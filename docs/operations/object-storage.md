# Private object storage

Hell Setlog stores user media in a private S3-compatible bucket. The application never mounts a local upload directory, exposes provider object URLs, accepts client-supplied storage paths, or enables anonymous bucket read/list.

## Contract

- Allowed media types: `image/jpeg`, `image/png`, and `image/webp`.
- Maximum object size: 10 MiB by default (`STORAGE_MAX_BYTES=10485760`).
- Object keys are server-generated as `users/{owner_id}/{uuid}.{ext}`.
- Signed GET URLs are single-object URLs with an exact 300-second expiry.
- The database, not the object key, is the source of ownership and attachment authorization.
- Provider errors are translated to generic storage errors and never returned with credentials, bucket internals, or signed URLs.

The `backend/storage.py` interface exposes `put`, `head`, `signed_get_url`, and `delete`. Unit tests use the memory implementation. Local development may use the non-public filesystem implementation, but the Compose stack uses MinIO through the same S3 adapter. Staging and production settings reject memory/local storage.

## Bucket setup

Create one bucket per environment and one least-privilege application identity. Grant only object read/write/delete for that bucket prefix. Do not grant `s3:ListAllMyBuckets`, bucket administration, public ACL changes, or anonymous access. Disable public access, enable encryption and versioning, and configure lifecycle rules separately for originals, rejected/quarantined objects, and backups.

Validate before deployment:

1. Anonymous `ListBucket` is denied.
2. Anonymous `GetObject` is denied.
3. The application identity can put/head/delete only inside its environment bucket.
4. A generated signed GET succeeds before 300 seconds and fails afterward.
5. Staging credentials cannot access production and production credentials cannot access staging.

## Upload integration boundary

Stage 3 adds the media database record and user-facing upload workflow. Before an object becomes attachable it must pass authorization, declared-size enforcement, magic-byte/MIME verification, checksum calculation, malware/quarantine handling, dimension limits, and EXIF stripping. A media record stores owner/relation, generated key, verified MIME, bytes, checksum, scan state, and timestamps. Only an authorized record may produce a signed URL or deletion.

Deleting a setlog/account schedules original and derivative deletion. Inventory reconciliation reports database records without objects and objects without database records; it never solves inconsistency by making the bucket public.
