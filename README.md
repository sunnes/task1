# Task 1

## Description

The wrapping repo for the exteran application: https://github.com/cristiklein/node-hostname \
Configure infrastructure - k3s single node based Kubernetes mini "cluster" \
Build and deploy it to that k3s with the externally accessable hostname: https://www.task.bisus.net \
The helm chart for the manifest rendering is [here](https://github.com/sunnes/task1/tree/main/charts/node-hostname)

## Structure

Folders:
 - **terraform** - includes terraform definition for the AWS EC2 minimalistic spawn of the k3s instance (smallest what was possible to push was not eligable for the Free Tier: t3.small intance)
 - **Dockerfile** - definition for the dockerized image building (double layered with the minimal security audit and fix)
 - **chart** - includes helm chart for the deployment of the built image (skipped registry mirror or hub uploads)
 - **scripts** - holds some handy bash scripts for the local development and testing
 - **node-hostname** - external submodule points to the applciation repository
 - **.github** - includes workflow pipelines for the github actions

## Repo related secrets:

- **ACTION_TOKEN** - The github token used to spawn with terraform the private github action runner inside of the k3s

- **AWS_ACCESS_KEY_ID** ->
- **AWS_DEFAULT_REGION** ->
- **AWS_SECRET_ACCESS_KEY** - those three key values used for the authenticate terraform in the AWS Free Tier account (without SSO support - expires fast and does not fit into the aws free tier. Required to configure and add AWS IAM SSO Authenticator)

- **CLOUDFLARE_TOKEN** - used as DNS zone manager (holds my private zone)
- **SSH_PRIVATE_KEY** - the key used for EC2 instance with the k3s isntalled

## Information about CICD automation pipeline

The pipeline consists of 3 stages:
- tests - due to application is not covered with tests this stage tries to make 3 matrix builds with different nodejs versions and passing `npm audit fix` to the green. In case of any vulnerable packaets will be detected - it will fail here
- build - just a build image without pushing it to the registry (failed to include the free registry with the AWS free tier) and leaves image on our k3s cluster in the cash
- deploy - uses same image by commit tag to deploy it with the helm chart to the k3s cluster

## What is not good here

1. With the very low resource limitations the terraform very messy and too complex. It was implemented with some security riscs there, but it works... and not stable. Did not found the way to get it clean without paying for the GKS or EKS clusters. Sorry
2. Absent built image testing, absent image promotions and fully absent release storage registries. Caused by absent of resources
3. The traefik ingress conflict with the certificate manager does not resolved. IMHO it sohuld not be used like that, but I will try it to resolve in time. By now does not revealed why routes for the certificate request validation are overlaps with the application ingress.


