import logging
import os
import uuid
from google.cloud import storage

logger = logging.getLogger(__name__)

VALID_EXTENSIONS = {".csv", ".txt", ".xml", ".json"}
INPUT_BUCKET  = os.environ["INPUT_BUCKET"]
OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]


def _storage_client():
    """Return a GCS client — points to emulator if env var is set."""
    emulator_host = os.environ.get("STORAGE_EMULATOR_HOST")
    if emulator_host:
        return storage.Client(
            project=os.environ["GCP_PROJECT_ID"],
            client_options={"api_endpoint": f"http://{emulator_host}"}
        )
    return storage.Client()


def process_file(file_name: str, correlation_id: str = None) -> dict:
    """
    Download file from input bucket, validate, write to output bucket.
    Returns a result dict — never raises, always returns status.
    correlation_id traces this file through all log lines.
    """
    if not correlation_id:
        correlation_id = str(uuid.uuid4())[:8]

    # Every log from this function carries the correlation_id
    log = logging.LoggerAdapter(logger, {
        "correlation_id": correlation_id,
        "file": file_name
    })

    client = _storage_client()

    # --- download ---
    try:
        blob    = client.bucket(INPUT_BUCKET).blob(file_name)
        content = blob.download_as_bytes()
        log.info("downloaded", extra={"bytes": len(content)})
    except Exception as e:
        log.error("download_failed", extra={"error": str(e)})
        return {
            "status": "error",
            "stage": "download",
            "file": file_name,
            "correlation_id": correlation_id
        }

    # --- validate ---
    ext = os.path.splitext(file_name)[1].lower()
    if ext not in VALID_EXTENSIONS:
        log.warning("invalid_extension", extra={"ext": ext})
        return {
            "status": "rejected",
            "reason": "unsupported_extension",
            "file": file_name,
            "correlation_id": correlation_id
        }

    if len(content) == 0:
        log.warning("empty_file")
        return {
            "status": "rejected",
            "reason": "empty_file",
            "file": file_name,
            "correlation_id": correlation_id
        }

    # --- route to output ---
    try:
        out_blob = client.bucket(OUTPUT_BUCKET).blob(f"processed/{file_name}")
        out_blob.upload_from_string(content)
        log.info("routed", extra={"destination": OUTPUT_BUCKET})
        return {
            "status": "success",
            "file": file_name,
            "correlation_id": correlation_id,
            "bytes": len(content)
        }
    except Exception as e:
        log.error("upload_failed", extra={"error": str(e)})
        return {
            "status": "error",
            "stage": "upload",
            "file": file_name,
            "correlation_id": correlation_id
        }
