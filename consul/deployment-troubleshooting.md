# Consul on EKS Deployment Troubleshooting Log

This document records the issues encountered during the deployment of Consul to AWS EKS using Terraform and Helm, along with their root causes and solutions.

---

## 1. Outdated Terraform Provider Versions
**Problem:**
- The project was using outdated versions of AWS, Azure, Kubernetes, and Helm Terraform providers.

**Root Cause:**
- Provider versions in `versions.tf` files were not up to date.

**Solution:**
- Updated all provider versions to the latest stable releases as of June 2025.

---

## 2. AWS Profile and Region Mismatch
**Problem:**
- Terraform and AWS CLI commands failed to access the EKS cluster.
- Error: `Kubernetes cluster unreachable: the server has asked for the client to provide credentials`.

**Root Cause:**
- The AWS CLI profile (`dev-cli-user`) was configured for `us-west-2`, but the EKS cluster was in `us-east-2`.

**Solution:**
- Updated the AWS CLI profile or explicitly set the region to `us-east-2` in commands and provider configuration.

---

## 3. AWS User Not Authorized in EKS (aws-auth ConfigMap)
**Problem:**
- Even with admin AWS permissions, received: `the server has asked for the client to provide credentials` when using `kubectl` or Terraform.

**Root Cause:**
- The IAM user was not mapped in the EKS cluster's `aws-auth` ConfigMap, so Kubernetes RBAC denied access.

**Solution:**
- Added the IAM user ARN to the `mapUsers` section of the `aws-auth` ConfigMap with `system:masters` group.

---

## 4. Helm Release Fails with Context Deadline Exceeded
**Problem:**
- Helm release for Consul failed with `context deadline exceeded` and `failed` status.

**Root Cause:**
- The Consul server pod (`consul-server-0`) was stuck in `Pending` state, causing DNS resolution failures for dependent pods.

**Solution:**
- Investigated pod status and found storage issues (see next section).

---

## 5. Consul Server Pod Pending Due to Unbound PVC
**Problem:**
- `kubectl describe pod consul-server-0` showed: `pod has unbound immediate PersistentVolumeClaims`.

**Root Cause:**
- No default StorageClass was set in the cluster, so the PVC for the Consul server could not be bound.

**Solution:**
- Patched the `gp2` storage class to be the default.
- Updated the Terraform Helm release to explicitly set `server.storageClass = "gp2"`.
- Deleted the pending PVC to allow it to be recreated and bound.

---

## 6. Consul Injector Pod CrashLoopBackOff
**Problem:**
- The `consul-connect-injector` pod was in `CrashLoopBackOff` due to DNS resolution errors for `consul-server.default.svc`.

**Root Cause:**
- The Consul server pod was not running, so the service DNS was not resolvable.

**Solution:**
- Once the Consul server pod started (after fixing storage), the injector and other components were able to start successfully.

---

## 7. General Troubleshooting Steps Used
- Checked pod and PVC status with `kubectl get pods` and `kubectl get pvc`.
- Described pods and events with `kubectl describe pod <pod>` and `kubectl get events`.
- Checked Helm release status with `helm status` and `helm get all`.
- Verified AWS IAM and Kubernetes RBAC configuration.
- Ensured correct region and profile usage in AWS CLI and Terraform.

---

## 8. StorageClass Already Exists Error During Terraform Apply
**Problem:**
- Running `terraform apply` for the EKS module failed with:
  `Error: storageclasses.storage.k8s.io "gp2" already exists`

**Root Cause:**
- The `gp2` storage class was already present in the cluster (created manually or by EKS defaults), but Terraform was not aware of it and tried to create it again.

**Solution:**
- Imported the existing `gp2` storage class into Terraform state using:
  ```sh
  terraform import kubernetes_storage_class.gp2_default gp2
  ```
- After import, Terraform managed the storage class and could update its annotations as needed.

---

## 9. Reference: Official Guide for Deploying Consul and Configuring Cluster Federation

For a comprehensive, step-by-step guide on deploying Consul to federate multiple Kubernetes clusters (EKS and AKS) and troubleshooting common issues, refer to the official HashiCorp tutorial:

[Deploy federated multi-cloud Kubernetes clusters (HashiCorp Developer)](https://developer.hashicorp.com/terraform/tutorials/networking/multicloud-kubernetes)

### Key Steps from the Tutorial
- **Provision EKS and AKS clusters** using Terraform modules for each cloud provider.
- **Configure Terraform outputs** in each cluster module to expose connection details for use by other modules (such as Consul).
- **Deploy Consul via Helm** using the Terraform Helm provider, referencing the correct Kubernetes provider for each cluster.
- **Configure federation** by sharing federation secrets between clusters and setting up mesh gateways.
- **Deploy sample applications** to verify cross-cluster service discovery and connectivity.
- **Troubleshoot** using `kubectl`, `helm`, and Terraform logs to resolve issues with authentication, storage, and networking.

For detailed configuration examples, troubleshooting tips, and best practices, see the full tutorial: [https://developer.hashicorp.com/terraform/tutorials/networking/multicloud-kubernetes](https://developer.hashicorp.com/terraform/tutorials/networking/multicloud-kubernetes)

---

**End of Troubleshooting Log** 