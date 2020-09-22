# Deploy Jenkins and Vault demo in K8s

## Requirements

* [Terraform CLI]()
* [Vault CLI]() (to configure Vault)
* A Kubernetes cluster running (Minikube and GKE tested)

## Deploy servers with Terraform

* Initialize Terraform
  ```bash
  terraform init
  ```
* Create a `terraform.auto.tfvars` file with the variables values:
  - `gcp_project` = "Your GCP project to save config files in GCS"
  - `vault_version` = "Leave it empty for default value (1.5.2) or use 1.x.y_ent for the Enterprise version"
  - `vault_repo` = "If you want to use Enterprise just use `hashicorp/vault-enterprise`"
  - `nodes` = "If empty default value is 3. The number of pods for Vault HA"
  - `cluster_endpoint` = "Your Kubernetes endpoint"
  - `client_certificate` = "Your K8s client cert file path"
  - `client_key` =  "Your K8s client key file path"
  - `ca_certificate` = "Your K8s CA cert file path"
  - `config_bucket` = "Your GCS config bucket to upload yaml files"
  - `dev`= "Set it to `false`  if you want to use peristed Vault (non development mode)"
  - `values_storage` = "Set it to `gcs` if you want to use Google Cloud Storage, or to `local` if you want to use local files"
* Apply your configuration (type yes after the Terraform plan has finished)
  ```bash
  terraform apply
  ```

After the `apply` you should have Jenkins running in the namespace `jenkins` and Vault running in the namespace `vault`

## Configure Jenkins and Vault for demo

* Expose Jenkins and Vault ports to your `localhost`:
  ```bash
  kubectl -n jenkins port-forward svc/vault-jenkins 8181:8080

  kubectl -n vault port-forward svc/vault 9200:8200
  ```
* If you run Vault in development mode (default Terraform variable), your Vault token is `root`. If not, you need to initialize Vault:
  ```bash
  kubectl exec -ti vault-0 -n vault -- vault operator init -n 1 -t 1
  ```
* Save your `Root Token` and `Unseal Key` and enable the AppRole Auth and create the demo secrets:
  ```bash
  export VAULT_ADDR="http://localhost:9200"

  curl -H "X-Vault-Token: root" -X PUT $VAULT_ADDR/v1/sys/policies/acl/jenkins-pol --data '{"policy": "path \"kv/data/cicd\" { capabilities = [ \"read\", \"list\" ] }\npath \"kv/cicd\" { capabilities = [ \"read\", \"list\" ] }"}'

  curl -H "X-Vault-Token: root" -X POST $VAULT_ADDR/v1/sys/auth/approle -d type=approle

  curl -H "X-Vault-Token: root" -X POST $VAULT_ADDR/v1/auth/approle/role/jenkins -d role_name=jenkins -d policies=jenkins-pol

  export VAULT_ROLE_ID=$(curl -s -H "X-Vault-Token: root" -X GET $VAULT_ADDR/v1/auth/approle/role/jenkins/role-id | jq -r '.data.role_id')

  export VAULT_SECRET_ID=$(curl -s -H "X-Vault-Token: root" -X POST $VAULT_ADDR/v1/auth/approle/role/jenkins/secret-id -d role_name=jenkin | jq -r '.data.secret_id')

  curl -H "X-Vault-Token: root" -X POST $VAULT_ADDR/v1/sys/mounts/kv -d '{"type": "kv","options":{"version": "2"}}'
  
  curl -H "X-Vault-Token: root" -X POST $VAULT_ADDR/v1/kv/data/cicd --data @- <<EOF
  {
    "data": {
      "gh_token": "<your_token>",
      "gh_user": "<your_gh_user>",
      "jenkins_pwd": "root",
      "tfe_dev": "<your_tfe_dev_token>",
      "tfe_org": "<your_tfe_org>",
      "tfe_token": "<your_tfe_token>"
    }
  }
  EOF
  ```

* Login into Jenkins `http://localhost:8181` with `admin / admin`
* Update the credentials in Jenkins to authenticate into Vault:
  * [demovault](http://localhost:8181/credentials/store/system/domain/_/credential/demovault/)
  * [vault-app-role](http://localhost:8181/credentials/store/system/domain/_/credential/vault-app-role/)


**That should be it! Just run your pipelines!**