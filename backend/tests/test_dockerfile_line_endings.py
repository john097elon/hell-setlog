from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


def test_dockerfile_normalizes_shell_script_line_endings_before_entrypoint():
    dockerfile = (REPOSITORY_ROOT / "Dockerfile").read_text(encoding="utf-8")

    assert "sed -i 's/\\r$//' /app/ops/*.sh" in dockerfile
    assert dockerfile.index("sed -i 's/\\r$//' /app/ops/*.sh") < dockerfile.index(
        'ENTRYPOINT ["/app/ops/entrypoint.sh"]'
    )


if __name__ == "__main__":
    test_dockerfile_normalizes_shell_script_line_endings_before_entrypoint()
