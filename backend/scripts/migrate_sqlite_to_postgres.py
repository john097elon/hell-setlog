"""Transactional, verifiable transfer from the legacy SQLite database."""

from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import asdict, dataclass
from datetime import date, datetime, timezone
from decimal import Decimal
from pathlib import Path
from typing import Any, Iterable, Mapping

from sqlalchemy import MetaData, create_engine, event, func, select, text, update
from sqlalchemy.engine import Connection, Engine, RowMapping

EXPECTED_REVISION = "20260715_0001"
TABLE_ORDER = (
    "users",
    "characters",
    "parties",
    "party_members",
    "workouts",
    "setlogs",
    "body_stats",
    "reactions",
)


@dataclass(frozen=True)
class TableSummary:
    count: int
    digest: str


@dataclass(frozen=True)
class TransferManifest:
    revision: str
    created_at: str
    source_fingerprint: str
    tables: dict[str, TableSummary]


@dataclass(frozen=True)
class VerificationReport:
    ok: bool
    counts: dict[str, int]
    source_digests: dict[str, str]
    target_digests: dict[str, str]
    differences: dict[str, str]


def _enable_sqlite_foreign_keys(dbapi_connection, _connection_record) -> None:
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


def _engine(url: str, enforce_foreign_keys: bool = False) -> Engine:
    engine = create_engine(url)
    if enforce_foreign_keys and engine.dialect.name == "sqlite":
        event.listen(engine, "connect", _enable_sqlite_foreign_keys)
    return engine


def _canonical(value: Any) -> Any:
    if isinstance(value, datetime):
        if value.tzinfo is None or value.utcoffset() is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).isoformat()
    if isinstance(value, date):
        return value.isoformat()
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, bytes):
        return value.hex()
    return value


def row_digest(rows: Iterable[Mapping[str, Any]]) -> str:
    payload = "\n".join(
        json.dumps(
            {key: _canonical(value) for key, value in sorted(dict(row).items())},
            sort_keys=True,
            ensure_ascii=True,
            separators=(",", ":"),
        )
        for row in rows
    )
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def _reflect(connection: Connection) -> MetaData:
    metadata = MetaData()
    metadata.reflect(bind=connection, only=TABLE_ORDER)
    missing = set(TABLE_ORDER) - set(metadata.tables)
    if missing:
        raise ValueError(f"database is missing required tables: {sorted(missing)}")
    return metadata


def _rows(connection: Connection, table) -> list[RowMapping]:
    statement = select(table).order_by(table.c.id)
    return list(connection.execute(statement).mappings())


def _summaries(connection: Connection, metadata: MetaData) -> dict[str, TableSummary]:
    result: dict[str, TableSummary] = {}
    for table_name in TABLE_ORDER:
        rows = _rows(connection, metadata.tables[table_name])
        result[table_name] = TableSummary(count=len(rows), digest=row_digest(rows))
    return result


def _source_fingerprint(summaries: Mapping[str, TableSummary]) -> str:
    material = "\n".join(
        f"{table}:{summary.count}:{summary.digest}"
        for table, summary in sorted(summaries.items())
    )
    return hashlib.sha256(material.encode("utf-8")).hexdigest()


def _target_values(table_name: str, row: Mapping[str, Any], target_table) -> dict[str, Any]:
    defaults: dict[str, dict[str, Any]] = {
        "users": {"workout_tags": "[]"},
        "parties": {
            "match_type": "manual",
            "max_members": 4,
            "is_open": True,
            "last_matched_at": None,
        },
        "party_members": {
            "role": "member",
            "status": "active",
            "left_at": None,
        },
    }
    values: dict[str, Any] = {}
    for column in target_table.columns:
        if column.name in row:
            values[column.name] = row[column.name]
        elif column.name in defaults.get(table_name, {}):
            values[column.name] = defaults[table_name][column.name]
        elif column.nullable:
            values[column.name] = None
        else:
            raise ValueError(f"legacy table {table_name} lacks required column {column.name}")
    return values


def _assert_target_revision(connection: Connection) -> None:
    revision = connection.execute(text("SELECT version_num FROM alembic_version")).scalar_one_or_none()
    if revision != EXPECTED_REVISION:
        raise ValueError(
            f"target Alembic revision must be {EXPECTED_REVISION}; found {revision!r}"
        )


def _assert_target_empty(connection: Connection, metadata: MetaData) -> None:
    nonempty = [
        table_name
        for table_name in TABLE_ORDER
        if connection.execute(
            select(func.count()).select_from(metadata.tables[table_name])
        ).scalar_one()
    ]
    if nonempty:
        raise ValueError(
            "target application tables must be empty; nonempty tables: "
            + ", ".join(nonempty)
        )


def _repair_postgres_sequences(connection: Connection, metadata: MetaData) -> None:
    if connection.dialect.name != "postgresql":
        return
    preparer = connection.dialect.identifier_preparer
    for table_name in TABLE_ORDER:
        quoted_table = preparer.quote(table_name)
        statement = text(
            "SELECT setval("
            "pg_get_serial_sequence(:table_name, 'id'), "
            "COALESCE(MAX(id), 1), "
            "MAX(id) IS NOT NULL"
            f") FROM {quoted_table}"
        )
        connection.execute(statement, {"table_name": table_name})


def _copy_rows(
    source_connection: Connection,
    target_connection: Connection,
    source_metadata: MetaData,
    target_metadata: MetaData,
) -> None:
    source_users = _rows(source_connection, source_metadata.tables["users"])
    target_users = target_metadata.tables["users"]
    character_links = {
        row["id"]: row.get("character_id")
        for row in source_users
        if row.get("character_id") is not None
    }
    user_values = []
    for row in source_users:
        values = _target_values("users", row, target_users)
        values["character_id"] = None
        user_values.append(values)
    if user_values:
        target_connection.execute(target_users.insert(), user_values)

    for table_name in TABLE_ORDER[1:]:
        source_rows = _rows(source_connection, source_metadata.tables[table_name])
        if not source_rows:
            continue
        target_table = target_metadata.tables[table_name]
        values = [
            _target_values(table_name, row, target_table)
            for row in source_rows
        ]
        target_connection.execute(target_table.insert(), values)

        if table_name == "characters":
            for user_id, character_id in character_links.items():
                target_connection.execute(
                    update(target_users)
                    .where(target_users.c.id == user_id)
                    .values(character_id=character_id)
                )


def _assert_referential_integrity(connection: Connection) -> None:
    if connection.dialect.name == "sqlite":
        violations = connection.exec_driver_sql("PRAGMA foreign_key_check").fetchall()
        if violations:
            raise ValueError("target foreign-key verification failed")


def _report(
    source_connection: Connection,
    target_connection: Connection,
    source_metadata: MetaData,
    target_metadata: MetaData,
) -> VerificationReport:
    source = _summaries(source_connection, source_metadata)
    target = _summaries(target_connection, target_metadata)
    differences: dict[str, str] = {}
    counts: dict[str, int] = {}
    for table_name in TABLE_ORDER:
        counts[table_name] = source[table_name].count
        if source[table_name] != target[table_name]:
            differences[table_name] = (
                f"source={source[table_name]} target={target[table_name]}"
            )
    return VerificationReport(
        ok=not differences,
        counts=counts,
        source_digests={name: summary.digest for name, summary in source.items()},
        target_digests={name: summary.digest for name, summary in target.items()},
        differences=differences,
    )


def verify(source_url: str, target_url: str) -> VerificationReport:
    source_engine = _engine(source_url)
    target_engine = _engine(target_url, enforce_foreign_keys=True)
    try:
        with source_engine.connect() as source_connection, target_engine.connect() as target_connection:
            source_metadata = _reflect(source_connection)
            target_metadata = _reflect(target_connection)
            return _report(
                source_connection,
                target_connection,
                source_metadata,
                target_metadata,
            )
    finally:
        source_engine.dispose()
        target_engine.dispose()


def transfer(
    source_url: str,
    target_url: str,
    manifest_path: Path,
) -> TransferManifest:
    source_engine = _engine(source_url)
    target_engine = _engine(target_url, enforce_foreign_keys=True)
    try:
        with source_engine.connect() as source_connection:
            source_metadata = _reflect(source_connection)
            source_summaries = _summaries(source_connection, source_metadata)

            with target_engine.begin() as target_connection:
                target_metadata = _reflect(target_connection)
                _assert_target_revision(target_connection)
                _assert_target_empty(target_connection, target_metadata)
                _copy_rows(
                    source_connection,
                    target_connection,
                    source_metadata,
                    target_metadata,
                )
                _repair_postgres_sequences(target_connection, target_metadata)
                _assert_referential_integrity(target_connection)
                report = _report(
                    source_connection,
                    target_connection,
                    source_metadata,
                    target_metadata,
                )
                if not report.ok:
                    raise ValueError(f"transfer verification failed: {report.differences}")

        manifest = TransferManifest(
            revision=EXPECTED_REVISION,
            created_at=datetime.now(timezone.utc).isoformat(),
            source_fingerprint=_source_fingerprint(source_summaries),
            tables=source_summaries,
        )
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        temporary_path = manifest_path.with_suffix(manifest_path.suffix + ".tmp")
        temporary_path.write_text(
            json.dumps(asdict(manifest), indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        temporary_path.replace(manifest_path)
        return manifest
    finally:
        source_engine.dispose()
        target_engine.dispose()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Move legacy SQLite rows into an empty Alembic-managed target"
    )
    parser.add_argument("--source-url", required=True)
    parser.add_argument("--target-url", required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()

    if args.verify_only:
        report = verify(args.source_url, args.target_url)
        print(json.dumps(asdict(report), sort_keys=True))
        return 0 if report.ok else 1

    manifest = transfer(args.source_url, args.target_url, args.manifest)
    print(
        json.dumps(
            {
                "status": "ok",
                "revision": manifest.revision,
                "source_fingerprint": manifest.source_fingerprint,
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
