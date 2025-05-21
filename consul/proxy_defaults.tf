# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This file contains optional Kubernetes manifests for setting Consul ProxyDefaults in both EKS and AKS clusters.
# Uncomment and apply after the main Consul configuration if you want to customize global proxy settings for Consul service mesh.
# These resources set the meshGateway mode to local for all proxies in the default namespace.

/*
## Apply the configuration in main.tf before uncommenting and applying the configuration in this file.

resource "kubernetes_manifest" "eks_proxy_defaults" {
  provider = kubernetes.eks
  manifest = {
    "apiVersion" = "consul.hashicorp.com/v1alpha1"
    "kind"       = "ProxyDefaults"
    "metadata" = {
      "name"      = "global"
      "namespace" = "default"
      "finalizers" = ["finalizers.consul.hashicorp.com"]
    }
    "spec" = {
      "meshGateway" = {
        "mode" = "local"
      }
    }
  }
}

resource "kubernetes_manifest" "aks_proxy_defaults" {
  provider = kubernetes.aks
  manifest = {
    "apiVersion" = "consul.hashicorp.com/v1alpha1"
    "kind"       = "ProxyDefaults"
    "metadata" = {
      "name"      = "global"
      "namespace" = "default"
      "finalizers" = ["finalizers.consul.hashicorp.com"]
    }
    "spec" = {
      "meshGateway" = {
        "mode" = "local"
      }
    }
  }
}
*/