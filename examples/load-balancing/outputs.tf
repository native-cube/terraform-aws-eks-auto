output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks_auto.cluster_name
}

output "pod_identity_association_arns" {
  description = "EKS Pod Identity association ARNs."
  value       = module.eks_auto.pod_identity_association_arns
}

output "load_balancer_service_manifests" {
  description = "Rendered EKS Auto Mode LoadBalancer Service manifests."
  value       = module.eks_auto.auto_mode_load_balancer_service_manifests
}

output "manifest_yaml" {
  description = "All rendered manifests as multi-document YAML."
  value       = module.eks_auto.auto_mode_kubernetes_manifest_yaml
}
