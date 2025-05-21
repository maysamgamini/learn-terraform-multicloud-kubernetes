# This Terraform configuration deploys Consul to both AWS EKS and Azure AKS clusters,
# enabling federation between the two clusters for multi-cloud service mesh scenarios.
# It uses Helm to install Consul and manages federation secrets for secure cross-cluster communication.

# ## Key Multi‑Cloud Service‑Mesh Use Cases
# ## Cross‑Cloud Service Discovery
# A microservice in EKS (e.g. orders-api) can do a Consul DNS lookup to call a microservice in AKS (e.g. inventory-api) without hard‑coding endpoints or VPN tunnels.
# ## Disaster Recovery & Failover
# If your primary AWS region goes down, you can fail over to the exact same workloads running in Azure, with Consul health checks automatically routing traffic to healthy replicas.
# ## Hybrid‑Cloud Workload Migration
# Gradually migrate traffic from on‑premises or one cloud to another by registering both environments in the same service mesh and shifting load via Consul intention policies.
# ## Security & Compliance Segmentation
# Keep PCI‑scope services in one cloud while non‑PCI services run elsewhere—yet let them discover each other programmatically under strict ACL rules.
# ## Global Canary Deployments
# Roll out a new version of a service to 5% of traffic in Azure, while 95% remains in AWS, then shift the balance based on metrics, all orchestrated by Consul intentions and Terraform-driven canary policies.

# # Copyright (c) HashiCorp, Inc.
# # SPDX-License-Identifier: MPL-2.0

# ## EKS Resources

# Import the remote state from the EKS workspace to retrieve output values (region and cluster name)
data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../eks/terraform.tfstate"
  }
}

# Configure the AWS provider for EKS resources
provider "aws" {
  region = data.terraform_remote_state.eks.outputs.region
}

# Fetch EKS cluster details for Kubernetes and Helm provider configuration
data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

# Configure the Kubernetes provider for EKS
provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    command     = "aws"
  }

  experiments {
    manifest_resource = true
  }
}

# Configure the Helm provider for EKS
provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

# Install Consul on EKS using the official Helm chart and dc1.yaml values
resource "helm_release" "consul_dc1" {
  provider   = helm.eks
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  version    = "1.3.1"

  values = [
    file("dc1.yaml")
  ]
}

# Retrieve the federation secret created by Consul on EKS for use in AKS
data "kubernetes_secret" "eks_federation_secret" {
  provider = kubernetes.eks
  metadata {
    name = "consul-federation"
  }

  depends_on = [helm_release.consul_dc1]
}

## AKS Resources

# Import the remote state from the AKS workspace to retrieve output values (resource group and cluster name)
data "terraform_remote_state" "aks" {
  backend = "local"
  config = {
    path = "../aks/terraform.tfstate"
  }
}

# Configure the Azure provider for AKS resources
provider "azurerm" {
  features {}
}

# Fetch AKS cluster details for Kubernetes and Helm provider configuration
data "azurerm_kubernetes_cluster" "cluster" {
  name                = data.terraform_remote_state.aks.outputs.kubernetes_cluster_name
  resource_group_name = data.terraform_remote_state.aks.outputs.resource_group_name
}

# Configure the Kubernetes provider for AKS
provider "kubernetes" {
  alias                  = "aks"
  host                   = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)

  experiments {
    manifest_resource = true
  }
}

# Configure the Helm provider for AKS
provider "helm" {
  alias = "aks"
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
  }
}

# Copy the federation secret from EKS to AKS for Consul federation
resource "kubernetes_secret" "aks_federation_secret" {
  provider = kubernetes.aks
  metadata {
    name = "consul-federation"
  }

  data = data.kubernetes_secret.eks_federation_secret.data
}

# Install Consul on AKS using the official Helm chart and dc2.yaml values
resource "helm_release" "consul_dc2" {
  provider   = helm.aks
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  version    = "1.3.1"

  values = [
    file("dc2.yaml")
  ]

  depends_on = [kubernetes_secret.aks_federation_secret]
}
