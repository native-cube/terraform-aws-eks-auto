output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks_auto.cluster_name
}

output "node_class_manifests" {
  description = "Rendered EKS Auto Mode NodeClass manifests."
  value       = module.eks_auto.auto_mode_node_class_manifests
}

output "node_pool_manifests" {
  description = "Rendered EKS Auto Mode NodePool manifests."
  value       = module.eks_auto.auto_mode_node_pool_manifests
}

output "storage_class_manifests" {
  description = "Rendered EKS Auto Mode StorageClass manifests."
  value       = module.eks_auto.auto_mode_storage_class_manifests
}

output "manifest_yaml" {
  description = "All rendered manifests as multi-document YAML."
  value       = module.eks_auto.auto_mode_kubernetes_manifest_yaml
}
