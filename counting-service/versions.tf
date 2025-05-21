# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This file specifies the required Terraform version and provider versions for the counting-service configuration.
# It ensures compatibility and repeatability for deployments across Kubernetes clusters.

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.0"
    }
  }
  required_version = ">= 0.14"
}

