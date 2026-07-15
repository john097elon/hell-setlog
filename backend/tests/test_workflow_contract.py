import re
from pathlib import Path

import yaml

WORKFLOWS = (
    Path(".github/workflows/operational-foundation.yml"),
    Path(".github/workflows/deploy-staging.yml"),
)


def uses_values(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "uses":
                yield child
            yield from uses_values(child)
    elif isinstance(value, list):
        for child in value:
            yield from uses_values(child)


def load_workflow(path: Path):
    assert path.exists(), f"{path} must exist"
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def test_workflows_are_parseable_least_privilege_and_sha_pinned():
    for path in WORKFLOWS:
        workflow = load_workflow(path)
        assert workflow["permissions"] == {"contents": "read"}
        for action in uses_values(workflow):
            if action.startswith("./"):
                continue
            assert re.search(r"@[0-9a-f]{40}$", action), (
                f"{path}: external action must use an immutable SHA: {action}"
            )


def test_ci_verifies_application_compose_and_digest_publication():
    path = WORKFLOWS[0]
    workflow = load_workflow(path)
    source = path.read_text(encoding="utf-8")

    assert "pytest" in source
    assert "npm ci" in source
    assert "npm run build" in source
    assert "docker compose config" in source
    assert "docker compose up --build --wait" in source
    assert "smoke_api.py" in source
    assert "smoke_object_storage.py" in source
    assert Path("backend/scripts/smoke_object_storage.py").exists()
    assert "docker push" in source
    assert "RepoDigests" in source
    assert workflow["jobs"]["image"]["permissions"] == {
        "contents": "read",
        "packages": "write",
    }


def test_staging_deploy_is_protected_and_uses_digest_rollback():
    workflow_path = WORKFLOWS[1]
    workflow = load_workflow(workflow_path)
    source = workflow_path.read_text(encoding="utf-8")
    script_path = Path("ops/deploy_staging.sh")
    runbook_path = Path("docs/operations/staging.md")
    evidence_path = Path("docs/operations/evidence/ELO-18.md")

    for path in (script_path, runbook_path, evidence_path):
        assert path.exists(), f"{path} must exist"

    assert workflow["jobs"]["deploy"]["environment"] == "staging"
    for secret in (
        "STAGING_HOST",
        "STAGING_USER",
        "STAGING_SSH_KEY",
        "STAGING_KNOWN_HOSTS",
        "STAGING_APP_HOST",
    ):
        assert secret in source
    assert "image_digest" in source
    assert "ops/deploy_staging.sh" in source

    script = script_path.read_text(encoding="utf-8")
    assert "sha256:[0-9a-f]{64}" in script
    assert ".last_image" in script
    assert "previous_image" in script
    assert "rollback" in script.lower()
    assert "docker compose" in script
    assert "/readyz" in script

    runbook = runbook_path.read_text(encoding="utf-8")
    assert "GitHub environment" in runbook
    assert "managed PostgreSQL" in runbook
    assert "private S3-compatible" in runbook
    assert "previous image digest" in runbook

    evidence = evidence_path.read_text(encoding="utf-8")
    assert "Local verification" in evidence
    assert "External verification still required" in evidence
