# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This Terraform configuration deploys a sample microservices application (counting and dashboard services)
# across two Kubernetes clusters: Azure AKS and AWS EKS. It demonstrates multi-cloud service federation
# using Consul and cross-cluster service discovery.

# ## AKS resources

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

# Fetch AKS cluster details for Kubernetes provider configuration
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
}

# Deploy the counting service Pod to AKS
resource "kubernetes_pod" "counting" {
  provider = kubernetes.aks

  metadata {
    name = "counting"
    labels = {
      "app" = "counting"
    }
  }

  spec {
    container {
      image = "hashicorp/counting-service:0.0.2"
      name  = "counting"

      port {
        container_port = 9001
        name           = "http"
      }
    }
  }
}

# Expose the counting service Pod via a ClusterIP service in AKS
resource "kubernetes_service" "counting" {
  provider = kubernetes.aks
  metadata {
    name      = "counting"
    namespace = "default"
    labels = {
      "app" = "counting"
    }
  }
  spec {
    selector = {
      "app" = "counting"
    }
    port {
      name        = "http"
      port        = 9001
      target_port = 9001
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
}

# EKS resources 

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

# Fetch EKS cluster details for Kubernetes provider configuration
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
}

# Deploy the dashboard service Pod to EKS, with Consul Connect upstream annotation for cross-cluster service discovery
resource "kubernetes_pod" "dashboard" {
  provider = kubernetes.eks

  metadata {
    name = "dashboard"
    annotations = {
      "consul.hashicorp.com/connect-service-upstreams" = "counting:9001:dc2"
    }
    labels = {
      "app" = "dashboard"
    }
  }

  spec {
    container {
      image = "hashicorp/dashboard-service:0.0.4"
      name  = "dashboard"

      env {
        name  = "COUNTING_SERVICE_URL"
        value = "http://localhost:9001"
      }

      port {
        container_port = 9002
        name           = "http"
      }
    }
  }
}

# Expose the dashboard service Pod via a LoadBalancer service in EKS
resource "kubernetes_service" "dashboard" {
  provider = kubernetes.eks

  metadata {
    name      = "dashboard-service-load-balancer"
    namespace = "default"
    labels = {
      "app" = "dashboard"
    }
  }

  spec {
    selector = {
      "app" = "dashboard"
    }
    port {
      port        = 80
      target_port = 9002
    }

    type             = "LoadBalancer"
  }
}
