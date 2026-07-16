"""Router: private image upload, retrieval, and deletion.

Media keys are `users/{owner_id}/...` — ownership is encoded in the key, so
access control is a prefix check with no extra table. Objects are private:
retrieval streams the bytes through an authenticated route (dev/local/memory)
or redirects to a short-lived signed URL (S3), never a public path.
"""
from fastapi import APIRouter, Depends, File, Form, HTTPException, Response, UploadFile
from fastapi.responses import JSONResponse, RedirectResponse
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
from models import PartyMember, Setlog, User, Workout
from settings import get_settings
from storage import (
    SIGNED_URL_SECONDS,
    ObjectNotFound,
    ObjectStorage,
    StoragePolicyError,
    StorageUnavailable,
    generate_object_key,
    get_storage,
    sniff_image_content_type,
)

router = APIRouter(prefix="/media", tags=["media"])

MAX_VIDEO_BYTES = 10 * 1024 * 1024


def _media_error(status_code: int, code: str, message: str) -> JSONResponse:
    return JSONResponse(
        status_code=status_code, content={"error": {"code": code, "message": message}}
    )


def _is_active_party_member(db: Session, party_id: int, user_id: int) -> bool:
    return (
        db.query(PartyMember)
        .filter(
            PartyMember.party_id == party_id,
            PartyMember.user_id == user_id,
            PartyMember.status == "active",
        )
        .first()
        is not None
    )

def _authorize_owner(key: str, user_id: int) -> None:
    # 404 (not 403) so a foreign key is indistinguishable from a missing one.
    if not key.startswith(f"users/{user_id}/"):
        raise HTTPException(status_code=404, detail="Media not found")


def _authorize_media_access(db: Session, key: str, user_id: int, denied_status: int = 404) -> None:
    # 1. Owner can always access
    if key.startswith(f"users/{user_id}/"):
        return

    # 2. Check if the media is associated with any Setlog in a party where user_id is an active member
    allowed = (
        db.query(PartyMember)
        .join(Workout, PartyMember.party_id == Workout.party_id)
        .join(Setlog, Setlog.workout_id == Workout.id)
        .filter(
            Setlog.file_path == key,
            PartyMember.user_id == user_id,
            PartyMember.status == "active",
        )
        .first()
        is not None
    )
    if not allowed:
        raise HTTPException(status_code=denied_status, detail="Media not found")


@router.post("", status_code=201)
async def upload_media(
    file: UploadFile = File(...),
    party_id: int | None = Form(default=None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    storage: ObjectStorage = Depends(get_storage),
):
    body = await file.read()
    is_video_request = file.content_type == "video/mp4" or party_id is not None

    if is_video_request:
        if file.content_type != "video/mp4":
            return _media_error(
                422, "unsupported_media_type", "Only video/mp4 uploads are allowed"
            )
        if party_id is None or not _is_active_party_member(
            db, party_id, current_user.id
        ):
            return _media_error(403, "forbidden", "Active party membership is required")
        if len(body) > MAX_VIDEO_BYTES:
            return _media_error(
                422, "file_too_large", "Video uploads must not exceed 10 MiB"
            )
        content_type = "video/mp4"
    else:
        content_type = sniff_image_content_type(body)
        if content_type is None:
            raise HTTPException(
                status_code=422, detail="Only JPEG, PNG, or WebP images are allowed"
            )

    try:
        key = generate_object_key(current_user.id, content_type)
        meta = storage.put(key, body, content_type)
    except StoragePolicyError as error:
        if is_video_request:
            return _media_error(422, "storage_policy_error", str(error))
        raise HTTPException(status_code=422, detail=str(error))
    except StorageUnavailable:
        if is_video_request:
            return _media_error(
                503, "storage_unavailable", "Media storage is unavailable"
            )
        raise HTTPException(status_code=503, detail="Media storage is unavailable")

    response = {
        "key": meta.key,
        "content_type": meta.content_type,
        "size_bytes": meta.size_bytes,
        "checksum_sha256": meta.checksum_sha256,
    }
    if is_video_request:
        response.update({"duration_seconds": None, "status": "ready"})
    return response


@router.get("/{key:path}/playback")
def get_playback_url(
    key: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    storage: ObjectStorage = Depends(get_storage),
):
    _authorize_media_access(db, key, current_user.id, denied_status=403)
    try:
        signed = storage.signed_get_url(key, expires_seconds=SIGNED_URL_SECONDS)
    except ObjectNotFound:
        raise HTTPException(status_code=404, detail="Media not found")
    return {
        "url": signed.url,
        "expires_in_seconds": signed.expires_seconds,
    }

@router.get("/{key:path}")
def get_media(
    key: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    storage: ObjectStorage = Depends(get_storage),
):
    _authorize_media_access(db, key, current_user.id)
    if get_settings().storage_backend == "s3":
        try:
            signed = storage.signed_get_url(key)
        except ObjectNotFound:
            raise HTTPException(status_code=404, detail="Media not found")
        return RedirectResponse(signed.url, status_code=302)
    try:
        content, meta = storage.get_object(key)
    except ObjectNotFound:
        raise HTTPException(status_code=404, detail="Media not found")
    return Response(
        content=content,
        media_type=meta.content_type,
        headers={
            "X-Content-Type-Options": "nosniff",
            "Cache-Control": "private, max-age=300",
        },
    )


@router.delete("/{key:path}", status_code=204)
def delete_media(
    key: str,
    current_user: User = Depends(get_current_user),
    storage: ObjectStorage = Depends(get_storage),
):
    _authorize_owner(key, current_user.id)
    try:
        storage.delete(key)
    except ObjectNotFound:
        raise HTTPException(status_code=404, detail="Media not found")
    return Response(status_code=204)
