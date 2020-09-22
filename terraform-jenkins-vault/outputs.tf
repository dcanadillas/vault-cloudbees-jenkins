output "vault-yaml" {
  # value = "https://storage.cloud.google.com/${google_storage_bucket_object.vault-config.bucket}/${google_storage_bucket_object.vault-config.output_name}"
  value = var.values_storage == "gcs" ? google_storage_bucket_object.vault-config.0.media_link : local_file.vault.0.filename
}
output "jenkins-yaml" {
  # value = "https://storage.cloud.google.com/${google_storage_bucket_object.jenkins-config.bucket}/${google_storage_bucket_object.jenkins-config.output_name}"
  value = var.values_storage == "gcs" ? google_storage_bucket_object.jenkins-config.0.media_link : "${path.root}/templates/jenkins.yaml"
}