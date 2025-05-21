# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This file specifies the required Terraform version and provider versions for the EKS configuration.
# It ensures compatibility and repeatability for deployments.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.83.1"  # bump to latest 5.x AWS provider :contentReference[oaicite:0]{index=0}
    }
  }
  required_version = ">= 1.12.0" # require Terraform CLI ≥ 1.12.0 :contentReference[oaicite:1]{index=1}
}

