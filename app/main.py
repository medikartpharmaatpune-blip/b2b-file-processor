import json
import logging
import os
import base64
import threading
from flask import Flask, jsonify
from google.cloud import pubsub_v1
from app.processor import process_file


class JsonFormatter(logging.Formatter):
    def format(self, record):
        log = {
            "time":  self.formatTime(record),
            "level": record.levelname,
            "msg":   record.getMessage(),
        }
        for key, val in record.__dict__.items():
            if key not in ("name", "msg", "args", "levelname", "levelno", "pathname",
                           "filename", "module", "exc_info", "exc_text", "stack_info",
                           "lineno", "funcName", "created", "msecs", "relativeCreated",
                           "thread", "threadName", "processName", "process", "message",
                           "taskName", "asctime"):
                log[key] = val
        if record.exc_info:
            log["traceback"] = self.formatException(record.exc_info)
        return json.dumps(log)


handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logging.basicConfig(level=logging.INFO, handlers=[handler], force=True)
logger = logging.getLogger(__name__)

PROJECT_ID   = os.environ["GCP_PROJECT_ID"]
SUBSCRIPTION = os.environ["PUBSUB_SUBSCRIPTION"]

# ── Health server ─────────────────────────────────────────────────────────
health_app = Flask(__name__)

@health_app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200

def run_health_server():
    logger.info("health_server_starting", extra={"port": 8080})
    health_app.run(host="0.0.0.0", port=8080, use_reloader=False)

# ── Message handling ──────────────────────────────────────────────────────
def decode_message_data(raw: bytes) -> dict:
    try:
        return json.loads(base64.b64decode(raw).decode())
    except Exception:
        return json.loads(raw.decode())


def handle_message(message: pubsub_v1.subscriber.message.Message) -> None:
    try:
        raw = message.data
        logger.info("raw_message", extra={"raw": raw.decode("utf-8", errors="replace")})

        data      = decode_message_data(raw)
        file_name = data.get("name", "")
        logger.info("received", extra={"file": file_name})

        result = process_file(file_name)

        if result["status"] in ("success", "rejected"):
            message.ack()
        else:
            message.nack()

        logger.info("processed", extra=result)

    except Exception:
        logger.error("handler_error", exc_info=True)
        message.nack()


def main():
    # Start health server in background FIRST
    # K8s readiness probe hits /health at 5s — must be up before then
    health_thread = threading.Thread(target=run_health_server, daemon=True)
    health_thread.start()
    logger.info("health_server_started")

    # Then connect to Pub/Sub
    subscriber = pubsub_v1.SubscriberClient()
    sub_path   = subscriber.subscription_path(PROJECT_ID, SUBSCRIPTION)
    logger.info("starting", extra={"subscription": sub_path})

    flow_control = pubsub_v1.types.FlowControl(max_messages=4)
    future = subscriber.subscribe(
        sub_path,
        callback=handle_message,
        flow_control=flow_control
    )
    try:
        future.result()
    except KeyboardInterrupt:
        future.cancel()
        logger.info("shutdown")


if __name__ == "__main__":
    main()
