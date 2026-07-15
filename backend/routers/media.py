"""Router: private image upload, retrieval, and deletion.

Media keys are `users/{owner_id}/...` — ownership is encoded in the key, so
access control is a prefix check with no extra table. Objects are private:
retrieval streams the bytes through an authenticated route (dev/local/memory)
or redirects to a short-lived signed URL (S3), never a public path.
"""
from fastapi import APIRouter, Depends, File, HTTPException, Response, UploadFile
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
from models import PartyMember, Setlog, User, Workout
from settings import get_settings
from storage import (
    ObjectNotFound,
    ObjectStorage,
    StoragePolicyError,
    StorageUnavailable,
    generate_object_key,
    get_storage,
    sniff_image_content_type,
)

router = APIRouter(prefix="/media", tags=["media"])


def _authorize_owner(key: str, user_id: int) -> None:
    # 404 (not 403) so a foreign key is indistinguishable from a missing one.
    if not key.startswith(f"users/{user_id}/"):
        raise HTTPException(status_code=404, detail="Media not found")


def _authorize_media_access(db: Session, key: str, user_id: int) -> None:
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
        raise HTTPException(status_code=404, detail="Media not found")


@router.post("", status_code=201)
async def upload_media(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    storage: ObjectStorage = Depends(get_storage),
):
    body = await file.read()
    content_type = sniff_image_content_type(body)
    if content_type is None:
        raise HTTPException(status_code=422, detail="Only JPEG, PNG, or WebP images are allowed")
    try:
        key = generate_object_key(current_user.id, content_type)
        meta = storage.put(key, body, content_type)
    except StoragePolicyError as error:
        raise HTTPException(status_code=422, detail=str(error))
    except StorageUnavailable:
        raise HTTPException(status_code=503, detail="Media storage is unavailable")
    return {
        "key": meta.key,
        "content_type": meta.content_type,
        "size_bytes": meta.size_bytes,
        "checksum_sha256": meta.checksum_sha256,
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
