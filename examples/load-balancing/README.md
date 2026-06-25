# EKS Auto Mode Load Balancing Example

This example creates an EKS Auto Mode cluster, a Pod Identity association for a workload service account, and renders an internal Network Load Balancer `Service` manifest.

The module does not apply Kubernetes manifests because it does not add a Kubernetes provider.

```bash
terraform init
terraform apply
terraform output -raw manifest_yaml | kubectl apply -f -
```
