output "input_bucket_name"  { value = google_storage_bucket.input.name }
output "output_bucket_name" { value = google_storage_bucket.output.name }
output "input_bucket_url"   { value = google_storage_bucket.input.url }
output "output_bucket_url"  { value = google_storage_bucket.output.url }
