# CloudBees Jenkins Distribution JCasC configuration with Vault plugin

This is a repo to configure your own [CloudBees Jenkins Distribution]() to demo your own [Vault]() integration using the [Vault Plugin]() for Jenkins.

You are going to use a local docker container to run your CloudBees Jenkins Distribution, but if you want to do it using Jenkins OSS deployed on Kubernetes you can go [here](#if-you-want-to-run-jenkins-oss-in-kubernetes).

## Requirements

* Docker installed in your machine
* Internet connection

## Build and run your Docker image with JCasC

Build your Docker image using the config provided in `cjd_jcasc.yaml`:

```
docker build -t hashidemo/cloudbees-jenkins-distro-jcasc:2.149.1.2 .
```

Once the image is built and saved locally you can run it by:

```
docker run \
--name cb-jenkins \
-u root \
--rm \
-p 8181:8080 \
-p 50000:50000 \
-p 33500:33500 \
-v $HOME/cb-jenkins-data-demo:/var/cloudbees-jenkins-distribution \
-v /var/run/docker.sock:/var/run/docker.sock \
hashidemo/cloudbees-jenkins-distro-jcasc:2.149.1.2
```

## Start Jenkins and activate the free license

The default YAML JCasC file is using `admin/admin` to authenticate in Jenkins. The process should be:

1. In your browser, go to `http://localhost:8181`
2. Authenticate with user `admin` and password `admin` (if you didn't change it in the `cjd_jcasc.yaml` file)
3. Activate the free license by the **Option1 - Activate online** (it's totally a perpetual free license, but if you don't persist the docker volume you will need to activate everytime you run the container)
4. Click `Start using CloudBees Jenkins Distribution` and enjoy

## Update your Vault auth credential from Jenkins

If you want to demo, be sure that you have a Vault server running. If not, you can run Vault in development mode. Then, update the token credential that comes configured with your Vault token credential configuration (you can create a new one with a different [Vault Auth method]()) and the AppRole credential:

1. Manage Jenkins > Manage Credentials
2. Go to `http://localhost:8181/credentials/store/system/domain/_/credential/demovault/`
3. Select Update
4. Enter your Vault token in the field `Token`
5. Go to `http://localhost:8181/credentials/store/system/domain/_/credential/vault-app-role/`
6. Enter the `role id` and the `secret id` in the fields


## Run and configure Vault to demo

If you want the configured pipelines in Jenkins to be successfuly run, you need a Vault server to connect into with some secrets created. If you don't have your Vault running or don't have much experience with Vault you can do the following:

* [Download Vault](https://www.vaultproject.io/downloads) binary
* Run Vault in development mode (you will lose all data when stopping the Vault process):
  ```bash
  vault server -dev -dev-root-token-id="root"
  ```
* Your Root token is `root`. But let's create an AppRole auth method to configure the Jenkins Auth credential. Execute all the following commands to retrieve your AppRole credentials:
  ```bash
  export VAULT_ADDR="http://localhost:9200"

  curl -H "X-Vault-Token: root" -X PUT $VAULT_ADDR/v1/sys/policies/acl/jenkins-pol --data '{"policy": "path \"kv/data/cicd\" { capabilities = [ \"read\", \"list\" ] }\npath \"kv/cicd\" { capabilities = [ \"read\", \"list\" ] }"}'

  curl -H "X-Vault-Token: root" -X POST $VAULT_ADDR/v1/sys/auth/approle -d type=approle

  curl -H "X-Vault-Token: root" -X POST $VAULT_ADDR/v1/auth/approle/role/jenkins -d role_name=jenkins -d policies=jenkins-pol

  export VAULT_ROLE_ID=$(curl -s -H "X-Vault-Token: root" -X GET $VAULT_ADDR/v1/auth/approle/role/jenkins/role-id | jq -r '.data.role_id')

  export VAULT_SECRET_ID=$(curl -s -H "X-Vault-Token: root" -X POST $VAULT_ADDR/v1/auth/approle/role/jenkins/secret-id -d role_name=jenkin | jq -r '.data.secret_id')
  ```
* Your `role_id` and `secret_id` are now set in the environment variables `VAULT_ROLE_ID` and `VAULT_SECRET_ID`. You can set those in [Jenkins](http://localhost:8181/credentials/store/system/domain/_/credential/vault-app-role/)
* Create the secrets that are going to be used from the pipelines demo:
  ```bash
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

# If you want to run Jenkins OSS in Kubernetes

I have added two more resources in this repo if you want to run Jenkins OSS and Vault demo in Kubernetes:

* Deploy Jenkins OSS with a `values.yaml` and `config-as-code` [manually using Helm](./k8s-jenkins_oss/)
* Deploy Jenkins OSS and Vault in your K8s cluster [usign Terraform](./terraform-jenkins-vault/)


