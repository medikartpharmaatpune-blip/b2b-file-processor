import logging
import os
from google.cloud import storage

logger = logging.getLogger(__name__)

VALID_EXTENSIONS = {".csvx", ".txt", ".xml", ".json"}
INPUT_BUCKET  = os.environ["INPUT_BUCKET"]
OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]


def _storage_client():
    """Return a GCS client — points to emulator if env var is set."""
    emulator_host = os.environ.get("STORAGE_EMULATOR_HOST")
    if emulator_host:
        # fake-gcs-server needs the full URL including scheme
        return storage.Client(
            project=os.environ["GCP_PROJECT_ID"],
            client_options={"api_endpoint": f"http://{emulator_host}"}
        )
    return storage.Client()


def process_file(file_name: str) -> dict:
    client = _storage_client()

    try:
        blob    = client.bucket(INPUT_BUCKET).blob(file_name)
        content = blob.download_as_bytes()
        logger.info("downloaded", extra={"file": file_name, "bytes": len(content)})
    except Exception as e:
        logger.error("download_failed", extra={"file": file_name, "error": str(e)})
        return {"status": "error", "stage": "download", "file": file_name}

    ext = os.path.splitext(file_name)[1].lower()
    if ext not in VALID_EXTENSIONS:
        logger.warning("invalid_extension", extra={"file": file_name, "ext": ext})
        return {"status": "rejected", "reason": "unsupported_extension", "file": file_name}

    if len(content) == 0:
        logger.warning("empty_file", extra={"file": file_name})
        return {"status": "rejected", "reason": "empty_file", "file": file_name}

    try:
        out_blob = client.bucket(OUTPUT_BUCKET).blob(f"processed/{file_name}")
        out_blob.upload_from_string(content)
        logger.info("routed", extra={"file": file_name, "destination": OUTPUT_BUCKET})
        return {"status": "success", "file": file_name}
    except Exception as e:
        logger.error("upload_failed", extra={"file": file_name, "error": str(e)})
        return {"status": "error", "stage": "upload", "file": file_name}
