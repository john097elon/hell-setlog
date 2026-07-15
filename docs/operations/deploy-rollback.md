# Deployment and rollback

Every release record names the immutable image digest, Alembic revision, feature flags, migration owner, release owner, pre-change restore point, previous image digest, and the exact rollback command.

## Before deployment

1. Confirm CI, migration compatibility, staging smoke, and required reviews are green.
2. Create/record the managed PostgreSQL restore point before a schema change.
3. Confirm backup success and the most recent restore rehearsal.
4. Confirm the previous image digest is still pullable.
5. Start the one-shot migration job with the migration role; do not give the app role DDL rights.
6. Start the candidate image only after migration succeeds.

## Application or configuration failure

Disable the risky flag if that protects users immediately. Otherwise redeploy the previous image digest with the same compatible database revision. Keep the failed image/digest and correlation IDs for investigation. A failed readiness check must prevent traffic from reaching the candidate.

## Database failure

Prefer a forward-fix or feature-flag disable. Run `alembic downgrade` only when that exact revision and post-deploy data shape were rehearsed as safe. For destructive/irreversible changes, restore to a new database from the recorded point and promote it through incident command; never overwrite the live database in place.

SQLite is a rollback target only before PostgreSQL accepts post-cutover writes. After writes begin, restore/fix PostgreSQL rather than reverse-copying data.

## Object and asset failure

Version bucket policy, object metadata, and frontend asset manifests. Roll back to the previous policy/manifest version and previous image digest. Do not make a bucket public to work around authorization or consistency failures.

## Secret or credential incident

Stop the affected deploy/job, revoke and rotate the least-privilege credential, redeploy with the new secret version, and verify old credentials fail. Do not include secret values in the incident timeline.
