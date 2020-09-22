terraform {
  required_version = ">= 0.13.0"
}

provider "google" {
  project = var.gcp_project
  region = var.gcp_region
}
provider "helm" {
  kubernetes {
    load_config_file = false
    host = var.cluster_endpoint
    # insecure = true
    # username = "${var.username}"
    # password = "${var.password}"
    # token = var.token

    # client_certificate = var.client_certificate
    # client_key = var.client_key
    # cluster_ca_certificate = var.ca_certificate
    client_certificate = file(var.client_certificate)
    client_key = file(var.client_key)
    cluster_ca_certificate = file(var.ca_certificate)
  }
}
provider "kubernetes" {
    load_config_file = false
    host = var.cluster_endpoint
    # insecure = true
    # username = "${var.username}"
    # password = "${var.password}"
    # token = var.token

    # client_certificate = var.client_certificate
    # client_key = var.client_key
    # cluster_ca_certificate = var.ca_certificate
    client_certificate = file("/Users/dcanadillas/.minikube/profiles/vault-k8s/client.crt")
    client_key = file("/Users/dcanadillas/.minikube/profiles/vault-k8s/client.key")
    cluster_ca_certificate = file("/Users/dcanadillas/.minikube/ca.crt")

}