"""Daily RDS manual-snapshot lifecycle for a single RDS instance.

Rendered by Terraform templatefile() at packaging time.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any

import boto3
from botocore.config import Config

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DB_INSTANCE_IDENTIFIER = "${db_instance_identifier}"
SNAPSHOT_PREFIX = "${snapshot_prefix}"
MANAGED_TAG_KEY = "${managed_tag_key}"
MANAGED_TAG_VALUE = "${managed_tag_value}"
RETENTION_DAYS = int("${retention_days}")

AWS_CLIENT_CONFIG = Config(
    connect_timeout=5,
    read_timeout=30,
    retries={"max_attempts": 3, "mode": "standard"},
)

rds_client = boto3.client("rds", config=AWS_CLIENT_CONFIG)


def lambda_handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    """
    Daily RDS manual-snapshot lifecycle.
    Dispatches on event['action']: 'create' takes today's snapshot,
    'cleanup' expires snapshots past the retention window.
    Any failure is allowed to raise so the Lambda invocation is recorded
    as an error and the CloudWatch alarm -> SNS email alert fires.
    """
    action = event.get("action")

    if action == "create":
        return create_snapshot()
    if action == "cleanup":
        return cleanup_snapshots()

    raise ValueError(f"Invalid action: {action!r}. Must be 'create' or 'cleanup'")


def create_snapshot() -> dict[str, Any]:
    """Take a manual snapshot tagged with its expiry date, skipping if the instance is stopped."""
    # This instance is stopped nightly/weekends by the dev cost-saving auto-scheduler
    # (a separate Lambda in the cds-infra repo). CreateDBSnapshot requires 'available',
    # so a stopped instance is an expected no-op, not a failure: no data was written
    # while it was off, so there is nothing new to protect for that day.
    status = rds_client.describe_db_instances(DBInstanceIdentifier=DB_INSTANCE_IDENTIFIER)["DBInstances"][0][
        "DBInstanceStatus"
    ]

    if status == "stopped":
        logger.info(
            "Skipping snapshot: %s is stopped (expected on the dev start/stop schedule)", DB_INSTANCE_IDENTIFIER
        )
        return {"action": "create", "skipped": True, "reason": "instance stopped"}

    if status != "available":
        raise RuntimeError(f"Cannot create snapshot: {DB_INSTANCE_IDENTIFIER} is in unexpected state '{status}'")

    now = datetime.now(timezone.utc)
    snapshot_id = f"{SNAPSHOT_PREFIX}-{now:%Y%m%d-%H%M%S}"
    expiry_date = (now + timedelta(days=RETENTION_DAYS)).date().isoformat()

    logger.info(
        "Creating manual snapshot %s of %s (expires %s)",
        snapshot_id, DB_INSTANCE_IDENTIFIER, expiry_date,
    )

    rds_client.create_db_snapshot(
        DBSnapshotIdentifier=snapshot_id,
        DBInstanceIdentifier=DB_INSTANCE_IDENTIFIER,
        Tags=[
            {"Key": MANAGED_TAG_KEY, "Value": MANAGED_TAG_VALUE},
            {"Key": "ExpiryDate", "Value": expiry_date},
            {"Key": "CreatedBy", "Value": "rds-backup-lifecycle-lambda"},
        ],
    )

    logger.info("Snapshot creation requested: %s", snapshot_id)
    return {"action": "create", "snapshot_id": snapshot_id, "expiry_date": expiry_date}


def cleanup_snapshots() -> dict[str, Any]:
    """Delete managed snapshots past retention, always keeping the most recent one."""
    managed_snapshots = list_managed_snapshots()

    if not managed_snapshots:
        logger.info("No managed snapshots found for %s; nothing to clean up", DB_INSTANCE_IDENTIFIER)
        return {"action": "cleanup", "deleted": [], "retained": []}

    # Always keep the most recent managed snapshot, regardless of age.
    managed_snapshots.sort(key=lambda s: s["SnapshotCreateTime"])
    protected_latest = managed_snapshots[-1]["DBSnapshotIdentifier"]
    candidates = managed_snapshots[:-1]

    today = datetime.now(timezone.utc).date()
    deleted, retained, failures = [], [protected_latest], []

    for snap in candidates:
        snapshot_id = snap["DBSnapshotIdentifier"]

        age_expired = (datetime.now(timezone.utc) - snap["SnapshotCreateTime"]).days >= RETENTION_DAYS
        expiry_tag = snap["Tags"].get("ExpiryDate")
        tag_expired = bool(expiry_tag) and today >= datetime.fromisoformat(expiry_tag).date()

        if not (age_expired and tag_expired):
            retained.append(snapshot_id)
            continue

        try:
            logger.info(
                "Deleting expired snapshot %s (created %s, expiry tag %s)",
                snapshot_id,
                snap["SnapshotCreateTime"],
                expiry_tag,
            )
            rds_client.delete_db_snapshot(DBSnapshotIdentifier=snapshot_id)
            deleted.append(snapshot_id)
        except Exception as exc:  # noqa: BLE001 - collected and re-raised below
            logger.error("Failed to delete snapshot %s: %s", snapshot_id, exc)
            failures.append(f"{snapshot_id}: {exc}")

    logger.info("Cleanup complete. Deleted: %s | Retained: %s", deleted, retained)

    if failures:
        raise RuntimeError(f"{len(failures)} snapshot(s) failed to delete: {'; '.join(failures)}")

    return {"action": "cleanup", "deleted": deleted, "retained": retained}


def list_managed_snapshots() -> list[dict[str, Any]]:
    """
    Returns only snapshots this routine created: identifier prefix AND the
    dedicated ManagedBy tag must both match, verified independently of the
    IAM resource-ARN scoping already in place on the Lambda's role.
    """
    managed = []
    paginator = rds_client.get_paginator("describe_db_snapshots")

    for page in paginator.paginate(DBInstanceIdentifier=DB_INSTANCE_IDENTIFIER, SnapshotType="manual"):
        for snap in page["DBSnapshots"]:
            snapshot_id = snap["DBSnapshotIdentifier"]

            if snap["Status"] != "available":
                continue
            if not snapshot_id.startswith(SNAPSHOT_PREFIX):
                continue

            tag_list = rds_client.list_tags_for_resource(ResourceName=snap["DBSnapshotArn"])["TagList"]
            tags = {t["Key"]: t["Value"] for t in tag_list}
            if tags.get(MANAGED_TAG_KEY) != MANAGED_TAG_VALUE:
                continue

            snap["Tags"] = tags
            managed.append(snap)

    return managed
