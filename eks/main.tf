# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This Terraform configuration provisions an Amazon EKS (Elastic Kubernetes Service) cluster and supporting infrastructure for multi-cloud federation demos.
# It creates a VPC, subnets, security groups, and an EKS cluster with managed node groups. It also configures IAM roles for the EBS CSI driver add-on.

provider "aws" {
  region = "us-east-2" # AWS region for all resources
}

# Fetch available availability zones in the selected region
data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

# Local value for generating a unique cluster name
locals {
  cluster_name = "education-eks-${random_string.suffix.result}"
}

# Generate a random string to ensure unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
}

# Create a new VPC for the EKS cluster using the official AWS VPC module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name            = "education-eks"
  cidr            = "10.0.0.0/16"
  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Tag subnets for Kubernetes load balancer discovery
  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

# Create the EKS cluster and managed node group using the official AWS EKS module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.32"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    consul = {
      name           = "consul-group"
      instance_types = ["t3a.medium"]
      min_size       = 1
      max_size       = 4
      desired_size   = 4
    }
  }

  # Additional security group rules for node communication
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    ingress_cluster_all = {
      description                   = "Cluster to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

# Reference the AWS managed IAM policy for the EBS CSI driver
# OpenID Connect (OIDC) is an identity layer built on top of the OAuth 2.0 protocol. It lets clients verify the identity of users or services based on 
# authentication from an external Identity Provider (IdP).
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Create an IAM role for Service Account on the EBS CSI driver using OIDC federation
module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.40.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

# Deploy the EBS CSI driver as an EKS add-on, using the IAM role above
# The Amazon EBS CSI Driver is a Kubernetes Container Storage Interface (CSI) plugin that lets your EKS cluster treat Amazon EBS volumes as Kubernetes
# Volumes—handling their full lifecycle (provision, attach, mount, detach, delete).

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.43.0-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
}

resource "kubernetes_storage_class" "gp2_default" {
  metadata {
    name = "gp2"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "kubernetes.io/aws-ebs"
  reclaim_policy       = "Delete"
  volume_binding_mode  = "WaitForFirstConsumer"
  parameters = {
    type = "gp2"
  }
}