# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This file defines input variables for the AKS Terraform configuration.
# These variables are used to securely pass sensitive information such as service principal credentials.

variable "appId" {
  description = "Azure Kubernetes Service Cluster service principal (client ID for authentication)."
}

variable "password" {
  description = "Azure Kubernetes Service Cluster password (client secret for authentication)."
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}