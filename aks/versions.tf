# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This file specifies the required Terraform version and provider versions for the AKS configuration.
# It ensures compatibility and repeatability for deployments.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.63.0"
    }
  }

  required_version = ">= 0.14"
}

