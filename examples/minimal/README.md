# Minimal Example

This example creates an EKS Auto Mode cluster with the default `general-purpose` and `system` node pools, EKS-managed load balancing, and EKS-managed block storage.

```hcl
module "eks_auto" {
  source = "../.."

  name       = "example-auto"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
}
```

The module defaults to a private Kubernetes API endpoint. Enable `endpoint_public_access` only when callers outside the VPC need API access.
