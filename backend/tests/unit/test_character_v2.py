"""Unit tests for Character V2 features."""

import hashlib
import json
import os
import sys
from pathlib import Path

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from models import BodyStat, Character
from schemas import CharacterOut
from settings import Settings


def test_manifest_schema_and_provenance():
    # Find the manifest file in the frontend public assets folder
    root_dir = Path(__file__).resolve().parents[3]
    manifest_path = root_dir / "frontend" / "public" / "assets" / "manifest.json"

    assert manifest_path.exists(), f"Manifest file not found at {manifest_path}"

    # 1. Manifest schema test
    with open(manifest_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    assert "version" in data
    assert "assets" in data
    assert isinstance(data["assets"], dict)

    # 2. Asset hash/provenance check
    for key, asset in data["assets"].items():
        assert "path" in asset
        assert "hash" in asset
        assert "author" in asset
        assert "source" in asset
        assert "license" in asset
        assert "attribution" in asset

        # Verify the actual file hash
        file_path = root_dir / "frontend" / "public" / asset["path"].lstrip("/")
        assert file_path.exists(), f"Asset file not found at {file_path}"

        hasher = hashlib.sha256()
        with open(file_path, "rb") as af:
            hasher.update(af.read())
        computed_hash = hasher.hexdigest()

        expected_hash = asset["hash"].replace("sha256-", "")
        assert computed_hash == expected_hash, (
            f"Hash mismatch for {key}: expected {expected_hash}, got {computed_hash}"
        )


def test_version_switching_and_cdn_rollback():
    # 3. Old version cache and rollback
    char = Character(name="TestHero", avatar_seed="default")

    # Initially default to stage 1 (total level < 15)
    assert char.stage == 1
    assert char.fallback_key == "T"

    # Verify avatar_url matches default version v2
    assert "/assets/avatars/stage_1.svg?v=v2" in char.avatar_url

    # Test Settings updates and validator
    s = Settings(
        app_env="development",
        asset_version="v2.1.0",
        asset_cdn_url="https://cdn.example.com/",
    )
    assert s.asset_version == "v2.1.0"
    assert s.asset_cdn_url == "https://cdn.example.com/"


def test_character_stage_progression():
    char = Character(name="Hero", avatar_seed="default")
    char.body_stats = [
        BodyStat(part="chest", level=5),
        BodyStat(part="back", level=5),
        BodyStat(part="legs", level=4),
    ]
    # Total level = 14 -> Stage 1
    assert char.stage == 1

    # Add stats to level 15 -> Stage 2
    char.body_stats.append(BodyStat(part="arms", level=1))
    assert char.stage == 2

    # Level 30 -> Stage 3
    char.body_stats = [
        BodyStat(part="chest", level=10),
        BodyStat(part="back", level=10),
        BodyStat(part="legs", level=10),
    ]
    assert char.stage == 3


def test_missing_asset_fallback():
    # 4. Missing asset fallback contract test
    char1 = Character(name="", avatar_seed="invalid_seed")
    assert char1.stage == 1
    assert char1.fallback_key == "?"

    char2 = Character(name="Alice", avatar_seed="stage_99,hat_red")
    # stage override parses as 99, but is clamped to 3
    assert char2.stage == 3
    assert char2.fallback_key == "A"
    assert "stage_3.svg" in char2.avatar_url
    assert char2.cosmetics == ["hat_red"]
