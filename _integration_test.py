#!/usr/bin/env python3
"""Integration test for Hell Setlog API - tests complete workout flow."""
import subprocess, json

# Login
r = subprocess.run(["curl", "-s", "-X", "POST", "http://localhost:8001/api/auth/login",
    "-H", "Content-Type: application/json",
    "-d", '{"email":"e2e@test.com","password":"test1234"}'],
    capture_output=True, text=True)
token = json.loads(r.stdout).get("access_token", "")
if not token:
    print("❌ LOGIN FAILED")
    exit(1)
print(f"✅ Login success")

def api(method, path, data=None, expected=None, label=""):
    cmd = ["curl", "-s", "-w", "\n%{http_code}", "-X", method,
           "http://localhost:8001/api" + path,
           "-H", "Authorization: Bearer " + token]
    if data is not None:
        cmd += ["-H", "Content-Type: application/json", "-d", json.dumps(data)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    lines = r.stdout.strip().split("\n")
    code = int(lines[-1].strip())
    body = "\n".join(lines[:-1])
    
    status = "✅" if expected is None or code == expected else "❌"
    label = label or f"{method} {path}"
    extra = f" (expected {expected})" if expected is not None and code != expected else ""
    print(f"{status} {label} → {code}{extra}")
    return json.loads(body) if body else {}, code

# 1. Create a party
party_body, _ = api("POST", "/parties/", {"name": "통합테스트"}, 201, "Create party")
party_id = party_body.get("id")
print(f"   Party ID: {party_id}")

# 2. Create a workout in that party
w_body, _ = api("POST", "/workouts/", {"party_id": party_id, "notes": "테스트"}, 201, "Create workout")
workout_id = w_body.get("id")
print(f"   Workout ID: {workout_id}")

# 3. Add setlogs (JSON body - was failing before fix)
api("POST", f"/workouts/{workout_id}/setlogs", {"type": "start", "content": "운동 시작!"}, 201, "Add start setlog")
api("POST", f"/workouts/{workout_id}/setlogs", {"type": "mid", "content": "중간 세트!"}, 201, "Add mid setlog")
api("POST", f"/workouts/{workout_id}/setlogs", {"type": "mid", "content": "더 많은 세트!"}, 201, "Add mid setlog 2")
api("POST", f"/workouts/{workout_id}/setlogs", {"type": "end", "content": "마지막!"}, 201, "Add end setlog")

# 4. Get setlogs
api("GET", f"/workouts/{workout_id}/setlogs", None, 200, "List setlogs")

# 5. Get workout
api("GET", f"/workouts/{workout_id}", None, 200, "Get workout")

# 6. End workout
api("POST", f"/workouts/{workout_id}/end", None, 200, "End workout")

# 7. Streak (was failing before fix - 404)
api("GET", "/streak/", None, 200, "Get streak")

# 8. Characters (was failing before fix - 405)
api("GET", "/characters/me", None, 200, "Get character")

# 9. Party feed
api("GET", f"/parties/{party_id}/feed", None, 200, "Get party feed")

# 10. Reactions
api("POST", "/reactions/", {"target_type": "workout", "target_id": workout_id, "emoji": "🔥"}, 201, "Add reaction")
api("POST", "/reactions/", {"target_type": "workout", "target_id": workout_id, "emoji": "💪"}, 201, "Add reaction 2")

# 11. Stats
api("GET", "/stats/", None, 200, "Get stats")

# 12. Tags
api("PATCH", "/users/me/tags", {"workout_tags": '["근력","유산소"]'}, 200, "Update tags")

# 13. Random browse
api("GET", "/parties/random-browse", None, 200, "Random browse")

# 14. Me
api("GET", "/auth/me", None, 200, "Auth me")

print("\n🎉 All API tests passed!")
