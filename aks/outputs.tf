# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This file defines outputs for the AKS Terraform configuration.
# Outputs expose important resource attributes after Terraform apply, for use in other modules or workspaces.

output "resource_group_name" {
  description = "Azure resource group name where the AKS cluster is deployed."
  value       = azurerm_resource_group.default.name
}

output "kubernetes_cluster_name" {
  description = "AKS cluster name created by this configuration."
  value       = azurerm_kubernetes_cluster.default.name
}
