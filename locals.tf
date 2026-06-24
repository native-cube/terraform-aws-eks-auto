locals {
  cluster_name = coalesce(var.cluster_name, var.name)

  common_tags = merge(
    var.tags,
    {
      "terraform-module" = "eks-auto"
      "eks-cluster"      = local.cluster_name
    }
  )

  cluster_role_name = substr("${var.name}-cluster-role", 0, 64)
  node_role_name    = coalesce(var.compute_config.node_iam_role_name, substr("${var.name}-auto-node-role", 0, 64))

  compute_enabled              = var.compute_config.enabled
  create_node_iam_role         = local.compute_enabled && var.compute_config.create_node_iam_role
  auto_mode_node_iam_role_arn  = local.create_node_iam_role ? try(aws_iam_role.node[0].arn, null) : var.compute_config.node_iam_role_arn
  external_node_role_name      = var.compute_config.node_iam_role_arn == null ? var.compute_config.node_iam_role_name : coalesce(var.compute_config.node_iam_role_name, reverse(split("/", var.compute_config.node_iam_role_arn))[0])
  auto_mode_node_iam_role_name = local.create_node_iam_role ? try(aws_iam_role.node[0].name, local.node_role_name) : local.external_node_role_name

  cluster_access_config = {
    authentication_mode                         = coalesce(try(var.access_config.authentication_mode, null), "API")
    bootstrap_cluster_creator_admin_permissions = try(var.access_config.bootstrap_cluster_creator_admin_permissions, null)
  }

  cluster_policy_arns = toset([
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSBlockStoragePolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSComputePolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSNetworkingPolicy"
  ])

  node_policy_arns = local.create_node_iam_role ? setunion(toset([
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  ]), var.compute_config.node_iam_policy_arns) : toset([])

  access_policy_associations = length(var.access_entries) == 0 ? {} : merge([
    for entry_key, entry in var.access_entries : {
      for association_key, association in entry.policy_associations : "${entry_key}:${association_key}" => {
        access_scope  = association.access_scope
        entry_key     = entry_key
        policy_arn    = association.policy_arn
        principal_arn = entry.principal_arn
      }
    }
  ]...)

  eks_capability_configs = {
    for key, capability in var.capabilities : key => {
      capability_name           = coalesce(try(capability.capability_name, null), key)
      create_iam_role           = try(capability.create_iam_role, true)
      delete_propagation_policy = try(capability.delete_propagation_policy, "RETAIN")
      iam_policy_arns           = try(capability.iam_policy_arns, toset([]))
      iam_role_arn              = try(capability.iam_role_arn, null)
      iam_role_name             = coalesce(try(capability.iam_role_name, null), substr("${upper(capability.type)}CapabilityRole-${local.cluster_name}-${key}", 0, 64))
      inline_policy_json        = try(capability.inline_policy_json, null)
      type                      = upper(capability.type)
      argocd = try(capability.argocd, null) == null ? null : {
        idc_instance_arn        = try(capability.argocd.idc_instance_arn, null)
        idc_region              = try(capability.argocd.idc_region, null)
        namespace               = try(capability.argocd.namespace, null)
        network_access_vpce_ids = try(capability.argocd.network_access_vpce_ids, toset([]))
        rbac_role_mappings      = try(capability.argocd.rbac_role_mappings, [])
      }
    }
  }

  eks_capability_create_iam_roles = {
    for key, capability in local.eks_capability_configs : key => capability
    if capability.create_iam_role
  }

  eks_capability_policy_attachments = length(local.eks_capability_create_iam_roles) == 0 ? {} : merge([
    for capability_key, capability in local.eks_capability_create_iam_roles : {
      for policy_arn in capability.iam_policy_arns : "${capability_key}:${policy_arn}" => {
        capability_key = capability_key
        policy_arn     = policy_arn
      }
    }
  ]...)

  eks_capability_iam_role_arns = {
    for key, capability in local.eks_capability_configs :
    key => capability.create_iam_role ? try(aws_iam_role.eks_capability[key].arn, null) : capability.iam_role_arn
  }

  eks_capability_external_role_names = {
    for key, capability in local.eks_capability_configs :
    key => capability.iam_role_arn == null ? capability.iam_role_name : coalesce(capability.iam_role_name, reverse(split("/", capability.iam_role_arn))[0])
  }

  eks_capability_iam_role_names = {
    for key, capability in local.eks_capability_configs :
    key => capability.create_iam_role ? try(aws_iam_role.eks_capability[key].name, capability.iam_role_name) : local.eks_capability_external_role_names[key]
  }
}
