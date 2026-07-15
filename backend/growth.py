"""Server-authoritative GrowthEvent engine (formula_version=1)."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, time, timezone

BODY_PARTS: tuple[str, ...] = (
    "chest", "back", "legs", "shoulders", "arms", "core", "stamina"
)
FORMULA_VERSION = 1
DAILY_CAP_PER_PART = 30  # ponytail: daily anti-farm ceiling; raise if gameplay demands it

_PART_KW_KR: dict[str, str] = {
    "chest": "가슴",
    "back": "등",
    "legs": "하체",
    "shoulders": "어깨",
    "arms": "팔",
    "core": "코어",
    "stamina": "유산소",
}


@dataclass(frozen=True)
class PartGrowth:
    body_part: str
    delta: int
    reason: str
    level_before: int
    potential_before: int
    level_after: int
    potential_after: int


def compute_growth(
    duration_seconds: int,
    setlog_contents: list[str],
    current_stats: dict[str, tuple[int, int]],  # part -> (level, potential)
    daily_used: dict[str, int],                  # part -> potential already granted today
) -> list[PartGrowth]:
    """Pure, deterministic growth for all 7 parts. No randomness.

    delta=0 entries are included so callers always see all 7 parts.
    Ceiling: daily_used + delta <= DAILY_CAP_PER_PART per part.
    """
    duration_min = max(0, duration_seconds) // 60
    base_gain = min(10, max(5, duration_min // 6))

    combined = " ".join(c.lower() for c in setlog_contents)
    mentioned = {part for part, kw in _PART_KW_KR.items() if kw in combined}

    results: list[PartGrowth] = []
    for part in BODY_PARTS:
        mention_bonus = 3 if part in mentioned else 0
        raw_gain = base_gain + mention_bonus

        remaining_cap = max(0, DAILY_CAP_PER_PART - daily_used.get(part, 0))
        delta = min(raw_gain, remaining_cap)

        parts = [f"v{FORMULA_VERSION}", f"dur:{duration_min}m", f"base:{base_gain}"]
        if mention_bonus:
            parts.append(f"mention:+{mention_bonus}")
        if delta < raw_gain:
            parts.append(f"daily_cap:{delta}/{raw_gain}")
        reason = ",".join(parts)

        level, potential = current_stats.get(part, (1, 0))
        new_potential = potential + delta
        new_level = level
        while new_potential >= 100:
            new_level += 1
            new_potential -= 100

        results.append(PartGrowth(
            body_part=part,
            delta=delta,
            reason=reason,
            level_before=level,
            potential_before=potential,
            level_after=new_level,
            potential_after=new_potential,
        ))

    return results


def today_utc_start() -> datetime:
    """UTC midnight of today — used to scope daily_used queries."""
    return datetime.combine(date.today(), time.min).replace(tzinfo=timezone.utc)
