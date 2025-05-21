# Learn Terraform - Deploy Federated Multi-Cloud Kubernetes Clusters

This repository contains Terraform configuration files to deploy a Consul-federated, multi-cloud Kubernetes setup across AWS (EKS) and Azure (AKS). It is designed for learning and demonstration purposes, following the [Deploy Federated Multi-Cloud Kubernetes Clusters tutorial](https://developer.hashicorp.com/terraform/tutorials/networking/multicloud-kubernetes).

---

## Architecture Overview
- **AKS (Azure Kubernetes Service):** Kubernetes cluster on Azure.
- **EKS (Elastic Kubernetes Service):** Kubernetes cluster on AWS.
- **Consul:** Service mesh deployed to both clusters, federated for cross-cloud service discovery.
- **Sample Services:** Counting and dashboard microservices deployed across both clusters.

---

## Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) >= 0.14
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- Sufficient permissions in both AWS and Azure accounts

---

## Credential Setup

### 1. Azure Credentials (for AKS)
- **Login to Azure:**
  ```sh
  az login
  ```
- **Set the desired subscription (if needed):**
  ```sh
  az account set --subscription "<your-subscription-id>"
  ```
- **Create a Service Principal:**
  ```sh
  az ad sp create-for-rbac --skip-assignment
  ```
  - Note the `appId` and `password` from the output. These will be used in `terraform.tfvars` for AKS.

- **Create `aks/terraform.tfvars`:**
  ```hcl
  appId    = "<your-appId>"
  password = "<your-password>"
  ```

### 2. AWS Credentials (for EKS)
- **Configure AWS CLI:**
  ```sh
  aws configure
  ```
  - Enter your AWS Access Key ID, Secret Access Key, region (e.g., `us-east-2`), and output format.
- Ensure your IAM user has permissions to create EKS clusters, VPCs, IAM roles, etc.

---

## Deployment Steps

**The order of deployment is important due to cross-references between workspaces.**

### 1. Deploy AKS (Azure Kubernetes Service)
```sh
cd aks
terraform init
terraform plan
terraform apply
```
- This creates the Azure resource group and AKS cluster. Outputs are used by other workspaces.

### 2. Deploy EKS (Elastic Kubernetes Service)
```sh
cd ../eks
terraform init
terraform plan
terraform apply
```
- This creates the AWS VPC, EKS cluster, and node groups. Outputs are used by other workspaces.

### 3. Deploy Consul Federation
```sh
cd ../consul
terraform init
terraform plan
terraform apply
```
- This deploys Consul to both clusters using Helm, federates them, and manages federation secrets.

### 4. Deploy Sample Microservices (Counting Service)
```sh
cd ../counting-service
terraform init
terraform plan
terraform apply
```
- This deploys the counting and dashboard services across both clusters.

---

## Verification
- Use `kubectl` to verify resources in both clusters:
  - For AKS:
    ```sh
    az aks get-credentials --resource-group <resource-group-name> --name <aks-cluster-name>
    kubectl get nodes
    kubectl get pods
    ```
  - For EKS:
    ```sh
    aws eks --region <region> update-kubeconfig --name <eks-cluster-name>
    kubectl get nodes
    kubectl get pods
    ```
- Check Consul UI and service connectivity as described in the tutorial.

---

## Cleanup
To destroy all resources, run `terraform destroy` in each workspace in **reverse order**:
1. `counting-service`
2. `consul`
3. `eks`
4. `aks`

---

## Troubleshooting & Tips
- Ensure your AWS and Azure credentials are active in your shell before running Terraform.
- If you see authentication errors, re-run `az login` or `aws configure` as needed.
- If you change outputs in one workspace, re-apply dependent workspaces.
- For Helm or Kubernetes errors, ensure your `kubectl` context is set to the correct cluster.
- For production, enable Consul ACLs and gossip encryption (see comments in `dc1.yaml` and `dc2.yaml`).

---

## References
- [HashiCorp Multi-Cloud Kubernetes Tutorial](https://developer.hashicorp.com/terraform/tutorials/networking/multicloud-kubernetes)
- [Consul Service Mesh Federation](https://www.consul.io/docs/connect/federation)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
