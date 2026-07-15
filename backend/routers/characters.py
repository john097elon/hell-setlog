"""Router: Character customization."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
from models import Character, User
from schemas import CharacterOut, CharacterUpdate

router = APIRouter(prefix="/characters", tags=["characters"])


@router.get("/me", response_model=CharacterOut)
def get_my_character(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the current user's character."""
    if not current_user.character_id:
        raise HTTPException(status_code=404, detail="No character found")

    character = (
        db.query(Character).filter(Character.id == current_user.character_id).first()
    )
    if not character:
        raise HTTPException(status_code=404, detail="No character found")
    return character


@router.patch("/me", response_model=CharacterOut)
def update_my_character(
    body: CharacterUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update the current user's character name and/or avatar seed."""
    if not current_user.character_id:
        raise HTTPException(status_code=404, detail="No character found")

    character = (
        db.query(Character).filter(Character.id == current_user.character_id).first()
    )
    if not character:
        raise HTTPException(status_code=404, detail="No character found")

    if body.name is not None:
        character.name = body.name
    if body.avatar_seed is not None:
        character.avatar_seed = body.avatar_seed

    db.commit()
    db.refresh(character)
    return character
