output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks_auto.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint."
  value       = module.eks_auto.cluster_endpoint
}

output "auto_mode_node_iam_role_arn" {
  description = "IAM role ARN used by EKS Auto Mode managed compute."
  value       = module.eks_auto.auto_mode_node_iam_role_arn
}

output "update_kubeconfig_command" {
  description = "AWS CLI command to configure kubectl for this cluster."
  value       = module.eks_auto.update_kubeconfig_command
}
