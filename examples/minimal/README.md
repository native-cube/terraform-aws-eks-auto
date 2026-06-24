# Minimal Example

This example creates an EKS Auto Mode cluster with the default `general-purpose` and `system` node pools, EKS-managed load balancing, and EKS-managed block storage.

```hcl
module "eks_auto" {
  source = "../.."

  name       = "example-auto"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
}
```

Production callers should restrict API endpoint CIDRs and use private subnets with outbound egress.
