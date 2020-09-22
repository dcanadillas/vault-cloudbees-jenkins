global:
  enabled: true
  tlsDisable: true
injector:
  # Let's enable if we want to demo some injection in the cluster
  enabled: true
server:
  image:
    repository: "${vault_repo}"
    tag: "${vault_version}"
    pullPolicy: IfNotPresent
  updateStrategyType: "OnDelete"

  dev:
    enabled: ${dev}

%{ if dev == false ~}
  readinessProbe:
    # ready if unsealed, either active or standby or performancestandby
    enabled: true
    path: /v1/sys/health?standbycode=204&performancestandbycode=204&drsecondarycode=204
  livenessProbe:
    # alive if vault is successfully responding to requests
    enabled: true
    path: /v1/sys/health?standbyok=true&perfstandbyok=true&sealedcode=204&uninitcode=204&drsecondarycode=204
    initialDelaySeconds: 30

  affinity: # |
  #  podAntiAffinity:
  #    requiredDuringSchedulingIgnoredDuringExecution:
  #      - labelSelector:
  #          matchLabels:
  #            app.kubernetes.io/name: {{ template "vault.name" . }}
  #            app.kubernetes.io/instance: "{{ .Release.Name }}"
  #            component: server
  #        topologyKey: kubernetes.io/hostname

  # Enables a headless service to be used by the Vault Statefulset
  service:
    enabled: true
    # clusterIP: None
    type: "NodePort"
    # nodePort: 30000
    # port: 8200
    # targetPort: 8200
    # annotations: {}

  ha:
    enabled: true
    replicas: ${vault_nodes}
    # If set to null, this will be set to the Pod IP Address
    apiAddr: null
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true
        listener "tcp" {
          tls_disable = true
          address = "[::]:8200"
          cluster_address = "[::]:8201"
        }
        storage "raft" {
          path = "/vault/data"
%{ for leader_host in hosts ~}
          retry_join {
            leader_api_addr = "http://${leader_host}.vault-internal:8200"
          }
%{ endfor ~}
        }
        service_registration "kubernetes" {}
        replication {
          resolver_discover_servers = false
        } 

# Vault UI
ui:
  enabled: false
  serviceType: "LoadBalancer"
  # serviceNodePort: null
  externalPort: 8200

%{ endif ~}
