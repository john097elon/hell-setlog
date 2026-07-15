from __future__ import annotations

import datetime


def _build_streaks(
    days: list[datetime.date],
) -> list[tuple[datetime.date, datetime.date, int]]:
    """Return streaks as (start, end, length) for sorted unique days."""
    streaks: list[tuple[datetime.date, datetime.date, int]] = []
    start = days[0]
    prev = days[0]

    for day in days[1:]:
        if day == prev + datetime.timedelta(days=1):
            prev = day
            continue

        streaks.append((start, prev, (prev - start).days + 1))
        start = day
        prev = day

    streaks.append((start, prev, (prev - start).days + 1))
    return streaks


def compute_streak(workout_dates: list[datetime.date]) -> dict:
    """
    Compute current and longest workout streak information.

    A date counts if there is at least one workout on that day.
    """
    if not workout_dates:
        return {
            "current_streak": 0,
            "longest_streak": 0,
            "current_streak_start": None,
            "longest_streak_start": None,
            "longest_streak_end": None,
        }

    unique_days = sorted(set(workout_dates))
    day_set = set(unique_days)
    streaks = _build_streaks(unique_days)

    longest_start, longest_end, longest_streak = max(streaks, key=lambda s: s[2])

    today = datetime.date.today()
    yesterday = today - datetime.timedelta(days=1)
    current_end: datetime.date | None = None

    if today in day_set:
        current_end = today
    elif yesterday in day_set:
        current_end = yesterday

    if current_end is None:
        current_streak = 0
        current_streak_start = None
    else:
        current_streak_start = current_end
        while (current_streak_start - datetime.timedelta(days=1)) in day_set:
            current_streak_start -= datetime.timedelta(days=1)
        current_streak = (current_end - current_streak_start).days + 1

    return {
        "current_streak": current_streak,
        "longest_streak": longest_streak,
        "current_streak_start": current_streak_start,
        "longest_streak_start": longest_start,
        "longest_streak_end": longest_end,
    }
