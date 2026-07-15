"""Seed script — creates 3 test users (with characters + all 7 BodyStats each),
1 sample party, party memberships, and 2 sample workouts with setlogs.

Run:  python seed.py
"""

import random
import string
from datetime import datetime, timedelta, timezone

from auth import hash_password
from database import SessionLocal
from models import (
    BodyStat,
    Character,
    Party,
    PartyMember,
    Reaction,
    Setlog,
    User,
    Workout,
)

# The 7 required BodyStat parts
BODY_PARTS = ["chest", "back", "legs", "shoulders", "arms", "core", "stamina"]


def seed():
    """Create all seed data."""

    db = SessionLocal()

    try:
        # ── Clean existing data (order matters for FK constraints) ──────────
        print("Cleaning existing data...")
        for table in [Reaction, Setlog, Workout, PartyMember, Party, BodyStat, Character, User]:
            db.query(table).delete()
        db.commit()
        print("  Done.\n")

        # ── 1. Create 3 test users ──────────────────────────────────────────
        users_data = [
            {"username": "alpha", "email": "alpha@dev.local", "password": "test1234"},
            {"username": "beta",  "email": "beta@dev.local",  "password": "test1234"},
            {"username": "gamma", "email": "gamma@dev.local", "password": "test1234"},
        ]
        users = []
        for ud in users_data:
            user = User(
                username=ud["username"],
                email=ud["email"],
                password_hash=hash_password(ud["password"]),
                character_id=None,
            )
            db.add(user)
            db.flush()
            users.append(user)
            print(f"Created user: {user.username} (id={user.id})")

        # ── 2. Create character + 7 BodyStats for each user ─────────────────
        for user in users:
            char = Character(
                user_id=user.id,
                name=user.username,
                avatar_seed="default",
            )
            db.add(char)
            db.flush()

            # Link user -> character
            user.character_id = char.id
            db.flush()

            # Create all 7 BodyStat entries
            for part in BODY_PARTS:
                db.add(BodyStat(
                    character_id=char.id,
                    part=part,
                    level=1,
                    potential=random.randint(0, 60),
                ))
            print(f"  -> Character '{char.name}' (id={char.id}) + 7 BodyStats created")

        db.commit()
        print()

        # ── 3. Create 1 sample party with all 3 users as members ────────────
        invite_code = "".join(random.choices(string.ascii_uppercase + string.digits, k=6))
        party = Party(
            name="Dev Party",
            invite_code=invite_code,
            owner_id=users[0].id,  # alpha is owner
        )
        db.add(party)
        db.flush()
        print(f"Created party: '{party.name}' (id={party.id}, invite={party.invite_code})")

        # Add all 3 users as members
        for user in users:
            db.add(PartyMember(party_id=party.id, user_id=user.id))
        db.commit()
        print("  -> All 3 users joined as members\n")

        # ── 4. Create 2 sample workouts with setlogs ────────────────────────
        now = datetime.now(timezone.utc)

        # Workout 1 (alpha — push day)
        w1 = Workout(
            user_id=users[0].id,
            party_id=party.id,
            started_at=now - timedelta(hours=2),
            ended_at=now - timedelta(hours=1),
            status="done",
            notes="Push day — chest + shoulders + triceps",
        )
        db.add(w1)
        db.flush()

        w1_setlogs = [
            ("start", "Getting ready for push day! 💪"),
            ("mid",  "Bench press: 3x10 @ 135lbs"),
            ("mid",  "Overhead press: 3x8 @ 95lbs"),
            ("mid",  "Incline dumbbell press: 3x12 @ 50lbs"),
            ("mid",  "Tricep pushdowns: 3x15 @ 45lbs"),
            ("mid",  "Lateral raises: 3x15 @ 20lbs"),
            ("end",  "Done! Great pump today, chest feels full 🔥"),
        ]
        for i, (stype, content) in enumerate(w1_setlogs):
            db.add(Setlog(
                workout_id=w1.id,
                user_id=users[0].id,
                type=stype,
                content=content,
                created_at=w1.started_at + timedelta(minutes=10 * i),
            ))
        print(f"Workout 1: '{w1.notes}' ({w1.status}) — {len(w1_setlogs)} setlogs")

        # Workout 2 (beta — pull day)
        w2 = Workout(
            user_id=users[1].id,
            party_id=party.id,
            started_at=now - timedelta(hours=1),
            ended_at=None,
            status="active",
            notes="Pull day — back + biceps",
        )
        db.add(w2)
        db.flush()

        w2_setlogs = [
            ("start", "Deadlift time! Warming up..."),
            ("mid",  "Deadlifts: 3x5 @ 225lbs"),
            ("mid",  "Pull-ups: 4x8 bodyweight"),
            ("mid",  "Barbell rows: 3x10 @ 135lbs"),
        ]
        for i, (stype, content) in enumerate(w2_setlogs):
            db.add(Setlog(
                workout_id=w2.id,
                user_id=users[1].id,
                type=stype,
                content=content,
                created_at=w2.started_at + timedelta(minutes=10 * i),
            ))
        print(f"Workout 2: '{w2.notes}' ({w2.status}) — {len(w2_setlogs)} setlogs")

        # ── 5. Add some reactions ───────────────────────────────────────────
        emojis = ["🔥", "💪", "🏋️", "👏", "😤", "🎯", "⚡", "🦍"]
        all_workouts = db.query(Workout).all()
        all_setlogs = db.query(Setlog).all()

        # Reactions on workouts
        for w in all_workouts:
            for u in users:
                if u.id != w.user_id:
                    db.add(Reaction(
                        user_id=u.id,
                        target_type="workout",
                        target_id=w.id,
                        emoji=random.choice(emojis),
                    ))

        # Reactions on some setlogs
        for s in all_setlogs[:6]:
            for u in users:
                if u.id != s.user_id and random.random() > 0.5:
                    db.add(Reaction(
                        user_id=u.id,
                        target_type="setlog",
                        target_id=s.id,
                        emoji=random.choice(emojis),
                    ))

        db.commit()

        # ── Summary ─────────────────────────────────────────────────────────
        print(f"\n{'='*50}")
        print("✅ Seed complete!")
        print(f"   Users:     {db.query(User).count()} (alpha, beta, gamma)")
        print("   Password:  test1234 (all users)")
        print(f"   Characters:{db.query(Character).count()}")
        print(f"   BodyStats: {db.query(BodyStat).count()} (7 per character)")
        print(f"   Parties:   {db.query(Party).count()} (invite={party.invite_code})")
        print(f"   Members:   {db.query(PartyMember).count()}")
        print(f"   Workouts:  {db.query(Workout).count()}")
        print(f"   Setlogs:   {db.query(Setlog).count()}")
        print(f"   Reactions: {db.query(Reaction).count()}")
        print(f"{'='*50}")

    finally:
        db.close()


if __name__ == "__main__":
    seed()
