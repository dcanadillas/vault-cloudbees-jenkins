
data "google_client_config" "default" {
}

# Creating dynamically a hostname list to use later on template
data "null_data_source" "hostnames" {
  count = var.nodes
  inputs = {
      hostnames = "vault-${count.index}"
  }
}
locals {
  hostnames = data.null_data_source.hostnames.*.inputs.hostnames
}
# ##################

# Creating namespaces for Vault and Jenkins

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
}

# ##################

# Let's upload config values.yaml to GCS

resource "google_storage_bucket_object" "jenkins-config" {
  count = var.values_storage == "gcs" ? 1 : 0 
  name   = "jenkins.yml"
  content = file("${path.root}/templates/jenkins.yaml")
  bucket = var.config_bucket
}

resource "google_storage_bucket_object" "vault-config" {
  count = var.values_storage == "gcs" ? 1 : 0
  name   = "vault.yml"
  content = templatefile("${path.root}/templates/vault.yaml.tpl",{
            vault_repo = var.vault_repo,
            vault_version = var.vault_version,
            vault_nodes = var.nodes,
            vault_namespace = kubernetes_namespace.vault.metadata.0.name,
            hosts = local.hostnames,
            dev = var.vault_dev
            })
  bucket = var.config_bucket
}

# ##################

# Let's install with Helm

resource "helm_release" "vault" {
  # depends_on = [
  #     kubernetes_secret.google-application-credentials,
  # ]
  name = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart  = "vault"
  create_namespace = false
  namespace = kubernetes_namespace.vault.metadata.0.name
  force_update = true
  values = [
      var.values_storage == "gcs" ? google_storage_bucket_object.vault-config.0.content : local_file.vault.0.content
  ]
}
resource "helm_release" "jenkins" {
  # depends_on = [
  #     kubernetes_secret.google-application-credentials,
  # ]
  name = "jenkins"
  repository = "https://charts.jenkins.io"
  chart  = "jenkins"
  create_namespace = false
  namespace = kubernetes_namespace.jenkins.metadata.0.name
  force_update = true
  values = [
      var.values_storage == "gcs" ? google_storage_bucket_object.jenkins-config.0.content : file("${path.root}/templates/jenkins.yaml")
  ]
  wait = false
}

# ##################

## I you want to create the template files locally uncomment the following lines (This is not working with remote execution in TFE)
# resource "local_file" "vault" {
#     content     = templatefile("${path.root}/templates/vault.yaml.tpl",{
#           hostname = var.hostname,
#           vault_version = var.vault_version
#           })
#     filename = "${path.root}/templates/vault.yaml"
# }
resource "local_file" "vault" {
  count = var.values_storage == "local" ? 1 : 0
  content = templatefile("${path.root}/templates/vault.yaml.tpl",{
            vault_repo = var.vault_repo,
            vault_version = var.vault_version,
            vault_nodes = var.nodes,
            vault_namespace = kubernetes_namespace.vault.metadata.0.name,
            hosts = local.hostnames,
            dev = var.vault_dev
            })
  filename = "${path.root}/templates/vault.yaml"
}