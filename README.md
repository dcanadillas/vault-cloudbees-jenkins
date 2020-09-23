# CloudBees Jenkins Distribution JCasC configuration with Vault plugin

This is a repo to configure your own [CloudBees Jenkins Distribution]() to demo your own [Vault](https://www.vaultproject.io/) integration using the [Vault Plugin](https://plugins.jenkins.io/hashicorp-vault-plugin/) for Jenkins.

You are going to use a local docker container to run your CloudBees Jenkins Distribution, but if you want to do it using Jenkins OSS deployed on Kubernetes you can go [here](#if-you-want-to-run-jenkins-oss-in-kubernetes).

## Requirements

* [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) installed in your machine
* Internet connection
* Jenkins pipelines examples used are connecting to Terraform Cloud to [run a workspace](https://www.terraform.io/docs/cloud/run/index.html#runs-and-workspaces), so you need to have an account in Terraform Cloud (TFC). If you don't, you can do the following:
  * [Sign up into TFC/TFE](https://app.terraform.io/signup) and follow the process to create your first organization
  * Then you will need to create your [Terraform API tokens](https://www.terraform.io/docs/cloud/users-teams-organizations/api-tokens.html) if you want to run successfuly your pipelines:
    - Create an [organization token](https://www.terraform.io/docs/cloud/users-teams-organizations/api-tokens.html#organization-api-tokens)
    - Create a [team token](https://www.terraform.io/docs/cloud/users-teams-organizations/api-tokens.html#team-api-tokens)
* You also will need to [run Vault](#run-and-configure-vault-to-demo) if you want the demo run

## Build and run your Docker image with JCasC

### Using `docker-compose` to run CJD and Vault
In this repo you have a `docker-compose.yaml` file that has the description to start Jenkins and Vault containers.

So, to run your instances in Docker, just execute (from the rooth path of this repo):

```bash
docker-compose up --build 2>&1>/dev/null &
```

To see the logs for each container:
* Jenkins: `docker logs -f cjd`
* Vault: `docker logs -f vault`

Once the containers are running, you need to initialize and unseal Vault:
```bash
docker exec -ti vault vault operator init -n 1 -t 1
```

**Store your `Unseal Key` and your `Initial Root Token` in a safe place** (look at the example below)
```
dcanadillas ~ > docker exec -ti vault vault operator init -n 1 -t 1                              25s
Unseal Key 1: yziy+gEZuCz+6B7Gork64Lpb4zXu3JucTcRj7hSqAG0=

Initial Root Token: s.PscPN6HxVrqao8z9fB4WptYN

Vault initialized with 1 key shares and a key threshold of 1. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 1 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 1 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

Then, you need to configure your Vault with the secrets and Auth methods to run your pipelines integrated with Vault. If you don't know how, you can go to [this topic of this doc](#running-demo-vault-instance-locally-in-development-mode)

> NOTE: `docker-compose` will create the volumes `$HOME/cb-jenkins-data-demo` and `$HOME/vault-demo` with your Jenkins and Vault configurations if you want to reuse it. 

### Build your CloudBees image (skip this if you used `docker-compose`)
If you want to build your CloudBees Jenkins image manually 
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

> NOTE: If you are not using `docker-compose` you need to change `Vault URL` in Jenkins Configuration (http://localhost:8181/configure).with your Vault URL.

## Start Jenkins and activate the free license

The default YAML JCasC file is using `admin/admin` to authenticate in Jenkins. The process should be:

1. In your browser, go to `http://localhost:8181`
2. Authenticate with user `admin` and password `admin` (if you didn't change it in the `cjd_jcasc.yaml` file)
3. Activate the free license by the **Option1 - Activate online** (it's totally a perpetual free license, but if you don't persist the docker volume you will need to activate everytime you run the container)
4. Click `Start using CloudBees Jenkins Distribution` and enjoy

## Configure Vault instance to run the demo with Jenkins
Let's create an AppRole auth method to configure the Jenkins Auth credential. Execute all the following commands to retrieve your AppRole credentials:
  ```bash
  export VAULT_ADDR="http://localhost:9200"
  
  export VAULT_TOKEN="<your_Root_token>" 

  curl -H "X-Vault-Token: $VAULT_TOKEN" -X PUT $VAULT_ADDR/v1/sys/policies/acl/jenkins-pol --data '{"policy": "path \"kv/data/cicd\" { capabilities = [ \"read\", \"list\" ] }\npath \"kv/cicd\" { capabilities = [ \"read\", \"list\" ] }"}'

  curl -H "X-Vault-Token: $VAULT_TOKEN" -X POST $VAULT_ADDR/v1/sys/auth/approle -d type=approle

  curl -H "X-Vault-Token: $VAULT_TOKEN" -X POST $VAULT_ADDR/v1/auth/approle/role/jenkins -d role_name=jenkins -d policies=jenkins-pol

  export VAULT_ROLE_ID=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" -X GET $VAULT_ADDR/v1/auth/approle/role/jenkins/role-id | jq -r '.data.role_id')

  export VAULT_SECRET_ID=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" -X POST $VAULT_ADDR/v1/auth/approle/role/jenkins/secret-id -d role_name=jenkin | jq -r '.data.secret_id')
  ```

Your `role_id` and `secret_id` are now set in the environment variables `VAULT_ROLE_ID` and `VAULT_SECRET_ID`. You can set those in [Jenkins](http://localhost:8181/credentials/store/system/domain/_/credential/vault-app-role/)

Now, let's create the secrets that are going to be used from the pipelines demo:
  ```bash
  curl -H "X-Vault-Token: $VAULT_TOKEN" -X POST $VAULT_ADDR/v1/sys/mounts/kv -d '{"type": "kv","options":{"version": "2"}}'
  
  curl -H "X-Vault-Token: $VAULT_TOKEN" -X POST $VAULT_ADDR/v1/kv/data/cicd --data @- <<EOF
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

## Update your Vault auth credential from Jenkins

If you want to demo, be sure that you have a Vault server running (if you used [`docker-compose`](#using-docker-compose-to-run-cjd-and-vault) you should have Vault running in `http://localhost:9200`). If not, you can run Vault in development mode. Then, update the token credential that comes configured with your Vault token credential configuration and the AppRole credential:

1. Manage Jenkins > Manage Credentials
2. Go to `http://localhost:8181/credentials/store/system/domain/_/credential/demovault/update`
3. Select Update
4. Enter your Vault token in the field `Token`
5. Go to `http://localhost:8181/credentials/store/system/domain/_/credential/vault-app-role/update`
6. Enter the `role id` and the `secret id` in the fields


## Running demo Vault instance locally in development mode

If you want the configured pipelines in Jenkins to be successfuly run, you need a Vault server to connect into with some secrets created. If you don't have your Vault running or don't have much experience with Vault you can do the following:

* [Download Vault](https://www.vaultproject.io/downloads) binary
* Run Vault in development mode (you will lose all data when stopping the Vault process):
  ```bash
  vault server -dev -dev-root-token-id="root"
  ```

In this case your Root Token is `root`. In this development mode everything is stored in memory in Vault, so you will lose all the data once you stop Vault.

## Stopping your environment

To stop your environment (from the root paht of this repo):

```bash
docker-compose down --remove-orphans
```

If you want to remove your config folders:
```bash
rm -rf $HOME/vault-demo

rm -rh $HOME/cb-jenkins-data-demo
```


# If you want to run Jenkins OSS in Kubernetes

I have added two more resources in this repo if you want to run Jenkins OSS and Vault demo in Kubernetes:

* Deploy Jenkins OSS with a `values.yaml` and `config-as-code` [manually using Helm](./k8s-jenkins_oss/)
* Deploy Jenkins OSS and Vault in your K8s cluster [usign Terraform](./terraform-jenkins-vault/)


