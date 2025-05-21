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
  description = "483f6e03-efc7-49b5-87a3-b2684c3f1a13"
}