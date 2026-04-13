import pytest
import os
from unittest.mock import MagicMock, patch

os.environ.setdefault("GCP_PROJECT_ID", "test-project")
os.environ.setdefault("PUBSUB_SUBSCRIPTION", "test-sub")
os.environ.setdefault("INPUT_BUCKET", "test-input")
os.environ.setdefault("OUTPUT_BUCKET", "test-output")

from app.processor import process_file, VALID_EXTENSIONS


class TestValidExtensions:
    def test_csv_is_valid(self):
        assert ".csv" in VALID_EXTENSIONS

    def test_xml_is_valid(self):
        assert ".xml" in VALID_EXTENSIONS

    def test_exe_is_not_valid(self):
        assert ".exe" not in VALID_EXTENSIONS

    def test_pdf_is_not_valid(self):
        assert ".pdf" not in VALID_EXTENSIONS


class TestProcessFile:
    def _mock_client(self, content=b"account,amount\n123,100.00"):
        """Return a mock GCS client that serves fake file content."""
        mock_blob = MagicMock()
        mock_blob.download_as_bytes.return_value = content

        mock_out_blob = MagicMock()

        mock_bucket = MagicMock()
        mock_bucket.blob.side_effect = [mock_blob, mock_out_blob]

        mock_client = MagicMock()
        mock_client.bucket.return_value = mock_bucket

        return mock_client, mock_out_blob

    @patch("app.processor._storage_client")
    def test_valid_csv_succeeds(self, mock_storage):
        client, out_blob = self._mock_client(b"account,amount\n123,100.00")
        mock_storage.return_value = client

        result = process_file("BACS_test.csv")

        assert result["status"] == "success"
        assert result["file"] == "BACS_test.csv"
        out_blob.upload_from_string.assert_called_once()

    @patch("app.processor._storage_client")
    def test_invalid_extension_rejected(self, mock_storage):
        client, _ = self._mock_client(b"binary content")
        mock_storage.return_value = client

        result = process_file("malware.exe")

        assert result["status"] == "rejected"
        assert result["reason"] == "unsupported_extension"

    @patch("app.processor._storage_client")
    def test_empty_file_rejected(self, mock_storage):
        client, _ = self._mock_client(b"")
        mock_storage.return_value = client

        result = process_file("empty.csv")

        assert result["status"] == "rejected"
        assert result["reason"] == "empty_file"

    @patch("app.processor._storage_client")
    def test_download_failure_returns_error(self, mock_storage):
        mock_blob = MagicMock()
        mock_blob.download_as_bytes.side_effect = Exception("GCS unavailable")

        mock_bucket = MagicMock()
        mock_bucket.blob.return_value = mock_blob

        mock_client = MagicMock()
        mock_client.bucket.return_value = mock_bucket
        mock_storage.return_value = mock_client

        result = process_file("BACS_test.csv")

        assert result["status"] == "error"
        assert result["stage"] == "download"

    @patch("app.processor._storage_client")
    def test_upload_failure_returns_error(self, mock_storage):
        mock_blob = MagicMock()
        mock_blob.download_as_bytes.return_value = b"account,amount\n123,100.00"

        mock_out_blob = MagicMock()
        mock_out_blob.upload_from_string.side_effect = Exception("GCS write failed")

        mock_bucket = MagicMock()
        mock_bucket.blob.side_effect = [mock_blob, mock_out_blob]

        mock_client = MagicMock()
        mock_client.bucket.return_value = mock_bucket
        mock_storage.return_value = mock_client

        result = process_file("BACS_test.csv")

        assert result["status"] == "error"
        assert result["stage"] == "upload"

    @patch("app.processor._storage_client")
    def test_xml_file_succeeds(self, mock_storage):
        client, out_blob = self._mock_client(b"<invoice><id>001</id></invoice>")
        mock_storage.return_value = client

        result = process_file("invoice.xml")

        assert result["status"] == "success"
        out_blob.upload_from_string.assert_called_once()

    @patch("app.processor._storage_client")
    def test_output_path_has_processed_prefix(self, mock_storage):
        """Verify output file goes to processed/ subdirectory."""
        mock_blob = MagicMock()
        mock_blob.download_as_bytes.return_value = b"account,amount\n123,100.00"

        mock_out_blob = MagicMock()
        mock_bucket = MagicMock()
        mock_bucket.blob.side_effect = [mock_blob, mock_out_blob]

        mock_client = MagicMock()
        mock_client.bucket.return_value = mock_bucket
        mock_storage.return_value = mock_client

        process_file("BACS_test.csv")

        # Second call to bucket().blob() should be the output path
        calls = mock_bucket.blob.call_args_list
        output_path = calls[1][0][0]
        assert output_path.startswith("processed/")
        assert "BACS_test.csv" in output_path
