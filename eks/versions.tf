# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This file specifies the required Terraform version and provider versions for the EKS configuration.
# It ensures compatibility and repeatability for deployments.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.6.2"
    }
  }
  required_version = ">= 0.14"
}

