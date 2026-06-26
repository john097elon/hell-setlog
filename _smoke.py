import subprocess, json

def api(method, path, data=None):
    r = subprocess.run(["curl", "-s", "-X", "POST", "http://localhost:8001/api/auth/login",
        "-H", "Content-Type: application/json",
        "-d", '{"email":"e2e@test.com","password":"test1234"}'],
        capture_output=True, text=True)
    token = json.loads(r.stdout).get("access_token", "")

    cmd = ["curl", "-s", "-w", "\nHTTP_%{http_code}", "-X", method, f"http://localhost:8001/api{path}",
           "-H", "Content-Type: application/json",
           "-H", f"Authorization: Bearer {token}"]
    if data:
        cmd += ["-d", json.dumps(data)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    print(f"{method} {path}")
    print(f"  {r.stdout.strip()}")
    print()

api("POST", "/workouts/5/setlogs", {"type": "start", "content": "테스트"})
api("GET", "/streak/")
api("GET", "/characters/me")
api("GET", "/streaks/")
