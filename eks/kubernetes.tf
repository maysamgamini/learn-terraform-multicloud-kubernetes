# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes

# This file configures the Kubernetes provider for the EKS cluster.
# It is required for the EKS module to complete successfully, particularly for creating the aws-auth ConfigMap.
# Note: Do not schedule deployments or services in this workspace; keep it modular as per best practices.


data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# Configure the Kubernetes provider to interact with the EKS cluster
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
  }
}
