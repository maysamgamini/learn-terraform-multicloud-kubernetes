# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This file defines input variables for the EKS Terraform configuration.
# These variables allow customization of the AWS region for resource deployment.

variable "region" {
  default     = "us-east-2"
  description = "AWS region where the EKS cluster and related resources will be deployed."
}
