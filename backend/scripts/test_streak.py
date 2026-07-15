#!/usr/bin/env python3
from __future__ import annotations

import datetime
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from backend.streak import compute_streak  # noqa: E402


def assert_equal(actual, expected, label: str) -> None:
    if actual != expected:
        raise AssertionError(f"{label}: expected {expected!r}, got {actual!r}")


def test_empty_list() -> None:
    result = compute_streak([])
    assert_equal(result["current_streak"], 0, "empty current_streak")
    assert_equal(result["longest_streak"], 0, "empty longest_streak")
    assert_equal(result["current_streak_start"], None, "empty current_streak_start")
    assert_equal(result["longest_streak_start"], None, "empty longest_streak_start")
    assert_equal(result["longest_streak_end"], None, "empty longest_streak_end")


def test_single_day() -> None:
    today = datetime.date.today()
    result = compute_streak([today])
    assert_equal(result["current_streak"], 1, "single day current_streak")
    assert_equal(result["longest_streak"], 1, "single day longest_streak")
    assert_equal(
        result["current_streak_start"], today, "single day current_streak_start"
    )
    assert_equal(
        result["longest_streak_start"], today, "single day longest_streak_start"
    )
    assert_equal(result["longest_streak_end"], today, "single day longest_streak_end")


def test_consecutive_days() -> None:
    start = datetime.date(2024, 1, 10)
    dates = [
        start,
        start + datetime.timedelta(days=1),
        start + datetime.timedelta(days=2),
    ]
    result = compute_streak(dates)
    assert_equal(result["longest_streak"], 3, "consecutive longest_streak")
    assert_equal(
        result["longest_streak_start"], start, "consecutive longest_streak_start"
    )
    assert_equal(
        result["longest_streak_end"],
        start + datetime.timedelta(days=2),
        "consecutive longest_streak_end",
    )


def test_gap_breaks_streak() -> None:
    start = datetime.date(2024, 2, 1)
    dates = [
        start,
        start + datetime.timedelta(days=1),
        start + datetime.timedelta(days=3),
    ]
    result = compute_streak(dates)
    assert_equal(result["longest_streak"], 2, "gap longest_streak")
    assert_equal(result["longest_streak_start"], start, "gap longest_streak_start")
    assert_equal(
        result["longest_streak_end"],
        start + datetime.timedelta(days=1),
        "gap longest_streak_end",
    )


def test_today_included_current_is_active() -> None:
    today = datetime.date.today()
    dates = [today - datetime.timedelta(days=1), today]
    result = compute_streak(dates)
    if result["current_streak"] < 1:
        raise AssertionError(
            f"today included current_streak: expected >= 1, got {result['current_streak']!r}"
        )


def test_yesterday_but_not_today_current_is_active() -> None:
    today = datetime.date.today()
    yesterday = today - datetime.timedelta(days=1)
    dates = [today - datetime.timedelta(days=2), yesterday]
    result = compute_streak(dates)
    if result["current_streak"] < 1:
        raise AssertionError(
            f"yesterday only current_streak: expected >= 1, got {result['current_streak']!r}"
        )


def main() -> None:
    test_empty_list()
    test_single_day()
    test_consecutive_days()
    test_gap_breaks_streak()
    test_today_included_current_is_active()
    test_yesterday_but_not_today_current_is_active()
    print("ALL TESTS PASSED")


if __name__ == "__main__":
    main()
