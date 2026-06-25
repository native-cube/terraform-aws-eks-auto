# EKS Auto Mode Storage Example

This example creates an EKS Auto Mode cluster and renders Kubernetes manifests for:

- a custom Auto Mode `NodeClass`
- a custom Auto Mode `NodePool`
- an encrypted `gp3` EBS `StorageClass`

The module does not apply Kubernetes manifests because it does not add a Kubernetes provider.

```bash
terraform init
terraform apply
terraform output -raw manifest_yaml | kubectl apply -f -
```
