variable "gcp_project" {
  description = "Google Cloud project"
}
variable "gcp_region" {
  description = "Google Cloud Platform region"
  default = "europe-west1"
}
variable "nodes" {
  description = "Vault nodes for HA"
  default = 3
}
variable "vault_version" {
  description = "Version of Vault to be deployed"
  default = "1.5.2"
}
variable "config_bucket" {
  description = "Cloud bucket to save config generated files"
}
variable "vault_repo" {
  description = "Vault Helm repositorie to use"
  default = "hashicorp/vault"
}
variable "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
}
variable "client_certificate" {
  description = "K8s cluster client certificate"
}
variable "client_key" {
  description = "K8s cluster client key"
}
variable "ca_certificate" {
  description = "K8s cluster CA certificate"
}
variable "vault_dev" {
  description = "Deploy Vault in development mode"
  default = true
}
variable "values_storage" {
  description = "Local or GCS storage for your values_yaml files"
  default = "gcs"
}
