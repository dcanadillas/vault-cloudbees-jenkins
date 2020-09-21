# CloudBees Jenkins Distribution JCasC configuration with Vault plugin

This is a repo to configure your own [CloudBees Jenkins Distribution]() to demo your own [Vault]() integration using the [Vault Plugin]() for Jenkins.

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

If you want to demo, update the token credential that comes configured with your Vault token credential (you can create a new one with a different [Vault Auth method]()):

1. Manage Jenkins > Manage Credentials
2. Go to `http://localhost:8181/credentials/store/system/domain/_/credential/demovault/`
3. Select Update
4. Enter your token in the field `Token`

