# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This file defines outputs for the EKS Terraform configuration.
# Outputs expose important resource attributes after Terraform apply, for use in other modules or workspaces.

output "cluster_id" {
  description = "EKS cluster ID created by the EKS module."
  value       = module.eks.cluster_id
}

output "region" {
  description = "AWS region where the EKS cluster is deployed."
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name generated for the EKS cluster."
  value       = local.cluster_name
}
