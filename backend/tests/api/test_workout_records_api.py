"""Contract tests for immutable structured workout records."""

from tests.conftest import auth, make_user


def _start_workout(client, token):
    response = client.post("/api/workouts/", json={}, headers=auth(token))
    assert response.status_code == 201, response.text
    return response.json()["id"]


def test_catalog_and_idempotent_record_creation(client):
    _, token = make_user(client, "recorder", suffix="records")
    catalog = client.get("/api/exercises", headers=auth(token))
    assert catalog.status_code == 200, catalog.text
    exercise = next(item for item in catalog.json() if item["unit_kind"] == "reps_weight")
    payload = {
        "workout_id": _start_workout(client, token),
        "exercise_id": exercise["id"],
        "performed_at": "2026-07-16T05:30:00Z",
        "sets": [
            {"set_index": 0, "reps": 10, "weight_kg": 60},
            {"set_index": 1, "reps": 8, "weight_kg": 65},
        ],
    }
    headers = {**auth(token), "X-Idempotency-Key": "bench-001"}
    created = client.post("/api/workout-records", json=payload, headers=headers)
    repeated = client.post("/api/workout-records", json=payload, headers=headers)
    assert created.status_code == 201, created.text
    assert repeated.status_code == 201, repeated.text
    assert repeated.json()["id"] == created.json()["id"]
    assert created.json()["exercise"]["id"] == exercise["id"]
    assert [item["set_index"] for item in created.json()["sets"]] == [0, 1]
    assert "id" not in created.json()["sets"][0]


def test_structured_record_targets_growth_body_part(client, db):
    _, token = make_user(client, "growthrecord", suffix="records")
    exercise = next(
        item
        for item in client.get("/api/exercises", headers=auth(token)).json()
        if item["body_part"] == "chest" and item["unit_kind"] == "reps_weight"
    )
    workout_id = _start_workout(client, token)
    created = client.post(
        "/api/workout-records",
        json={
            "workout_id": workout_id,
            "exercise_id": exercise["id"],
            "sets": [{"set_index": 0, "reps": 10, "weight_kg": 60}],
        },
        headers=auth(token),
    )
    assert created.status_code == 201, created.text

    ended = client.post(f"/api/workouts/{workout_id}/end", headers=auth(token))
    assert ended.status_code == 200, ended.text
    deltas = {item["part"]: item["potential"] for item in ended.json()["body_stats"]}
    assert deltas["chest"] > deltas["back"]


def test_record_detail_list_calendar_and_owner_boundary(client):
    _, owner_token = make_user(client, "recordowner", suffix="records")
    _, other_token = make_user(client, "recordother", suffix="records")
    exercise = next(
        item
        for item in client.get("/api/exercises", headers=auth(owner_token)).json()
        if item["unit_kind"] == "time"
    )
    workout_id = _start_workout(client, owner_token)
    created = client.post(
        "/api/workout-records",
        json={
            "workout_id": workout_id,
            "exercise_id": exercise["id"],
            "performed_at": "2026-07-16T15:30:00Z",
            "sets": [{"set_index": 0, "duration_seconds": 90}],
        },
        headers=auth(owner_token),
    )
    assert created.status_code == 201, created.text
    record_id = created.json()["id"]

    detail = client.get(f"/api/workout-records/{record_id}", headers=auth(owner_token))
    listing = client.get("/api/workout-records", headers=auth(owner_token))
    calendar = client.get(
        "/api/workout-records/calendar?from=2026-07-17&to=2026-07-17&tz=Asia/Seoul",
        headers=auth(owner_token),
    )
    assert detail.status_code == 200, detail.text
    assert listing.json()["items"][0]["id"] == record_id
    assert calendar.json()["days"] == [
        {"date": "2026-07-17", "record_count": 1, "body_parts": ["core"]}
    ]
    assert client.get(f"/api/workout-records/{record_id}", headers=auth(other_token)).status_code == 404


def test_list_cursor_can_be_reused(client):
    _, token = make_user(client, "cursoruser", suffix="records")
    exercise = next(
        item
        for item in client.get("/api/exercises", headers=auth(token)).json()
        if item["unit_kind"] == "reps_weight"
    )
    workout_id = _start_workout(client, token)
    for performed_at in ("2026-07-16T05:30:00Z", "2026-07-16T05:31:00Z"):
        response = client.post(
            "/api/workout-records",
            json={
                "workout_id": workout_id,
                "exercise_id": exercise["id"],
                "performed_at": performed_at,
                "sets": [{"set_index": 0, "reps": 10, "weight_kg": 60}],
            },
            headers=auth(token),
        )
        assert response.status_code == 201, response.text

    first_page = client.get("/api/workout-records?limit=1", headers=auth(token))
    assert first_page.status_code == 200, first_page.text
    second_page = client.get(
        f"/api/workout-records?limit=1&cursor={first_page.json()['next_cursor']}",
        headers=auth(token),
    )
    assert second_page.status_code == 200, second_page.text
    assert len(second_page.json()["items"]) == 1


def test_structured_record_growth_is_idempotent_and_visible_on_character(client, db):
    from models import GrowthEvent

    _, token = make_user(client, "recordgrowth", suffix="records")
    exercise = next(
        item
        for item in client.get("/api/exercises", headers=auth(token)).json()
        if item["body_part"] == "chest" and item["unit_kind"] == "reps_weight"
    )
    workout_id = _start_workout(client, token)
    created = client.post(
        "/api/workout-records",
        json={
            "workout_id": workout_id,
            "exercise_id": exercise["id"],
            "sets": [{"set_index": 0, "reps": 10, "weight_kg": 60}],
        },
        headers=auth(token),
    )
    assert created.status_code == 201, created.text

    first_end = client.post(f"/api/workouts/{workout_id}/end", headers=auth(token))
    repeated_end = client.post(f"/api/workouts/{workout_id}/end", headers=auth(token))
    character = client.get("/api/characters/me", headers=auth(token))

    assert first_end.status_code == 200, first_end.text
    assert repeated_end.json()["body_stats"] == first_end.json()["body_stats"]
    assert db.query(GrowthEvent).filter(GrowthEvent.workout_id == workout_id).count() == 7
    assert {
        item["part"]: (item["level"], item["potential"])
        for item in character.json()["body_stats"]
    } == {
        item["part"]: (item["level"], item["potential"])
        for item in first_end.json()["body_stats"]
    }
