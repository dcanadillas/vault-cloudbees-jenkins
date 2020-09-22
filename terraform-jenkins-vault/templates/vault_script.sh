#!/bin/bash

# kubectl port-forward svc/vault -n vault 9200:8200 &
# export VAULT_ADDR="http://localhost:9200"
# vault login root

# Enable AppRole Auth Method
vault auth enable approle

#Create a policy to read secrets from kv/cicd
vault policy write jenkins-pol templates/jenkins-pol.hcl

# Create a role for the AppRole with the previous policy attached
vault write auth/approle/role/jenkins policies=jenkins-pol

# Create a secret ID
vault write auth/approle/role/jenkins/secret-id role_name=jenkins

# Retrieve the role ID
vault read auth/approle/role/jenkins/role-id
# vault read -format json auth/approle/role/jenkins/role-id | jq -r '.data.role_id'


vault secrets enable -version=2 -path=kv kv

vault write kv/data/cicd - << EOF
{
  "data": {
    "gh_token": "myghtoken",
    "gh_user": "my_user",
    "jenkins_pwd": "root",
    "tfe_dev": "mytfedevtoken",
    "tfe_org": "mytfeorg",
    "tfe_token": "mytfetoken"
  }
}
EOF





