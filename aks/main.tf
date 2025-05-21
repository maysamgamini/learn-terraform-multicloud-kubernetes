# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This Terraform configuration provisions an Azure Kubernetes Service (AKS) cluster for multi-cloud federation demos.
# It creates a resource group and an AKS cluster with a default node pool, using a service principal for authentication.
# The random_pet resource is used to generate unique names for resources to avoid naming collisions.

resource "random_pet" "prefix" {}

# Configure the Azure provider to manage resources in Azure.
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# Create a resource group to contain the AKS cluster and related resources.
resource "azurerm_resource_group" "default" {
  name     = "${random_pet.prefix.id}-aks"
  location = "West US 2"

  tags = {
    environment = "Demo"
  }
}

# Provision an Azure Kubernetes Service (AKS) cluster in the resource group above.
# The cluster uses a default node pool with 3 nodes, each using the Standard_D2_v2 VM size.
# The service principal credentials are provided via variables for secure authentication.
resource "azurerm_kubernetes_cluster" "default" {
  name                = "${random_pet.prefix.id}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${random_pet.prefix.id}-k8s"
  kubernetes_version  = "1.32.3"

  default_node_pool {
    name            = "default"
    node_count      = 3
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  # Service principal for AKS authentication
  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  role_based_access_control_enabled = true

  tags = {
    environment = "Demo"
  }
}
