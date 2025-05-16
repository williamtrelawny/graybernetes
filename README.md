# Project Graybernetes
Project Graybernetes is the initiative to develop an official Helm Chart for running Graylog in Kubernetes!

# Setup
Follow these instructions to get up and running with the manifests. We're assuming you're going to run everything in the `graylog` namespace, but you can change it if needed. Just know that certain things don't work right across separate namespaces!

## Create Namespace
First, create the Graylog namespace:
```
kubectl create ns graylog
```

## Install MongoDB Community Operator
Graylog needs a MongoDB cluster. We recommend the [Official MongoDB Community Operator](https://github.com/mongodb/mongodb-kubernetes-operator/tree/master), which can be deployed following their instructions. Just make sure to install in the `graylog` namespace!

To install via Helm just run:

```
helm install community-operator mongodb/community-operator -n graylog
```

## Create Secrets
Create Secrets for the Graylog `password_secret` and `root_password_sha2` values.

Generate `password_secret` random string:

```
kubectl create secret generic -n graylog graylog-password-secret --from-literal=password-secret=$(pwgen -N 1 -s 96)
```

Generate `root_password_sha2` hash, replace "your-password" with your desired password (in double quotes!):

```
kubectl create secret generic -n graylog graylog-root-password --from-literal=root-password=$(echo -n "your-password" | sha256sum | cut -d" " -f1)
```

## Apply the Manifests
Start by deploying a MongoDB ReplicaSet. The included `mongodb.yaml` manifest:

- Deploys a 3-node ReplicaSet
- Creates a `admin` user in the `admin` db (password: `admin`) with the `clusterAdmin` and `userAdminAnyDatabase` Roles
- Creates a `graylog` user in the `graylog` db (password: `yabbadabbadoo`) with the `dbAdmin` and `readWrite` Roles just for its own db

We recommend changing these passwords for production use! Edit the YAML to do so before applying.

Once ready, deploy the ReplicaSet:

```
kubectl apply -n graylog -f manifests/mongodb/mongodb.yaml
```

Wait for all MongDB pods to be in a READY state before continuing. We recommend using `k9s`.

Deploy the Graylog and Datanode services:

```
kubectl apply -n graylog -f manifests/graylog/service-graylog.yaml
kubectl apply -n graylog -f manifests/graylog/service-datanode.yaml
```

Deploy the Datanode StatefulSet:

```
kubectl apply -n graylog -f manifests/graylog/statefulset-datanode.yaml
```

Wait for all `datanode` pods to be READY. Check the logs to make sure you see the line: `Started REST API at <0.0.0.0:8999>` on each.

Last, deploy the Graylog StatefulSet:

```
kubectl apply -n graylog -f manifests/graylog/statefulset-graylog.yaml
```

Monitor the `graylog` pods to see the following lines:

- `Started REST API at <0.0.0.0:9000>`
- `Signing certificate for  node 75667707-f90a-4496-b546-329418710ba7, subject: CN=datanode-0.datanode-headless.graylog.svc.cluster.local`

And watch for the following in the Datanode pod logs:

- You might see some `Node not connected` or `Connection refused` error messages- this just means the other Datanodes' embedded Opensearch nodes are not up yet. If this persists for more than a couple minutes then you may have a problem.
- `Updating cluster node b4075883-2edf-4686-9b66-5134d2239069 from STARTING to AVAILABLE (reason: HEALTH_CHECK_OK)`

This indicates your Graylog and Datanode clusters are healthy and communicating to eachother.