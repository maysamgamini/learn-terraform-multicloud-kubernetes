# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This file specifies the required Terraform version and provider versions for the Consul federation configuration.
# It ensures compatibility and repeatability for deployments across Kubernetes clusters using Helm and Kubernetes providers.

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.0"
    }
  }
  required_version = ">= 0.14"
}

