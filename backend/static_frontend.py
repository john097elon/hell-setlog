"""Serve the immutable frontend build without intercepting API routes."""

from pathlib import Path

from fastapi import FastAPI
from starlette.exceptions import HTTPException
from starlette.staticfiles import StaticFiles


class SPAStaticFiles(StaticFiles):
    async def get_response(self, path: str, scope):
        try:
            return await super().get_response(path, scope)
        except HTTPException as error:
            if error.status_code != 404 or Path(path).suffix:
                raise
            return await super().get_response("index.html", scope)


def mount_frontend(app: FastAPI, directory: Path) -> None:
    root = directory.resolve()
    if not (root / "index.html").is_file():
        raise RuntimeError(f"frontend build is missing index.html under {root}")
    app.mount("/", SPAStaticFiles(directory=root), name="frontend")


def mount_frontend_if_present(app: FastAPI, directory: Path) -> bool:
    if not (directory / "index.html").is_file():
        return False
    mount_frontend(app, directory)
    return True
