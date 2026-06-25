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

  public_access_cidrs = var.endpoint_public_access ? var.public_access_cidrs : null

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

  pod_identity_association_configs = {
    for key, association in var.pod_identity_associations : key => {
      create_iam_role      = try(association.create_iam_role, true)
      disable_session_tags = try(association.disable_session_tags, null)
      iam_policy_arns      = try(association.iam_policy_arns, toset([]))
      iam_role_arn         = try(association.iam_role_arn, null)
      iam_role_name        = coalesce(try(association.iam_role_name, null), substr("${local.cluster_name}-${key}-pod-identity", 0, 64))
      inline_policy_json   = try(association.inline_policy_json, null)
      namespace            = association.namespace
      service_account      = association.service_account
      tags                 = try(association.tags, {})
      target_role_arn      = try(association.target_role_arn, null)
    }
  }

  pod_identity_create_iam_roles = {
    for key, association in local.pod_identity_association_configs : key => association
    if association.create_iam_role
  }

  pod_identity_policy_attachments = length(local.pod_identity_create_iam_roles) == 0 ? {} : merge([
    for association_key, association in local.pod_identity_create_iam_roles : {
      for policy_arn in association.iam_policy_arns : "${association_key}:${policy_arn}" => {
        association_key = association_key
        policy_arn      = policy_arn
      }
    }
  ]...)

  pod_identity_iam_role_arns = {
    for key, association in local.pod_identity_association_configs :
    key => association.create_iam_role ? try(aws_iam_role.pod_identity[key].arn, null) : association.iam_role_arn
  }

  pod_identity_external_role_names = {
    for key, association in local.pod_identity_association_configs :
    key => association.iam_role_arn == null ? association.iam_role_name : coalesce(association.iam_role_name, reverse(split("/", association.iam_role_arn))[0])
  }

  pod_identity_iam_role_names = {
    for key, association in local.pod_identity_association_configs :
    key => association.create_iam_role ? try(aws_iam_role.pod_identity[key].name, association.iam_role_name) : local.pod_identity_external_role_names[key]
  }

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
      iam_policy_presets        = try(capability.iam_policy_presets, toset([]))
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

  eks_capability_iam_policy_preset_documents = {
    cloudcontrol_read_only = {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "cloudcontrol:GetResource",
            "cloudcontrol:ListResourceRequests",
            "cloudcontrol:ListResources"
          ]
          Resource = "*"
        }
      ]
    }
    eks_read_only = {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "eks:DescribeAccessEntry",
            "eks:DescribeCluster",
            "eks:DescribePodIdentityAssociation",
            "eks:ListAccessEntries",
            "eks:ListClusters",
            "eks:ListPodIdentityAssociations"
          ]
          Resource = "*"
        }
      ]
    }
    resource_tagging = {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "tag:GetResources",
            "tag:GetTagKeys",
            "tag:GetTagValues",
            "tag:TagResources",
            "tag:UntagResources"
          ]
          Resource = "*"
        }
      ]
    }
    secrets_read_only = {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:DescribeSecret",
            "secretsmanager:GetSecretValue",
            "secretsmanager:ListSecrets"
          ]
          Resource = "*"
        }
      ]
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

  eks_capability_preset_policies = length(local.eks_capability_create_iam_roles) == 0 ? {} : merge([
    for capability_key, capability in local.eks_capability_create_iam_roles : {
      for preset_name in capability.iam_policy_presets : "${capability_key}:${preset_name}" => {
        capability_key = capability_key
        preset_name    = preset_name
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

  auto_mode_node_class_specs = {
    for name, node_class in var.auto_mode_node_classes :
    name => merge(
      (
        try(node_class.spec.role, null) == null &&
        try(node_class.spec.instanceProfile, null) == null &&
        local.auto_mode_node_iam_role_name != null
        ) ? {
        role = local.auto_mode_node_iam_role_name
      } : {},
      node_class.spec
    )
  }

  auto_mode_node_class_access_entries = {
    for name, node_class in var.auto_mode_node_classes : name => {
      principal_arn = try(coalesce(try(node_class.node_role_arn, null), local.auto_mode_node_iam_role_arn), null)
    }
    if try(node_class.create_access_entry, true)
  }

  auto_mode_node_class_manifests = {
    for name, node_class in var.auto_mode_node_classes : name => yamlencode({
      apiVersion = "eks.amazonaws.com/v1"
      kind       = "NodeClass"
      metadata = merge(
        { name = name },
        length(node_class.annotations) > 0 ? { annotations = node_class.annotations } : {},
        length(node_class.labels) > 0 ? { labels = node_class.labels } : {}
      )
      spec = local.auto_mode_node_class_specs[name]
    })
  }

  auto_mode_node_pool_manifests = {
    for name, node_pool in var.auto_mode_node_pools : name => yamlencode({
      apiVersion = "karpenter.sh/v1"
      kind       = "NodePool"
      metadata = merge(
        { name = name },
        length(node_pool.annotations) > 0 ? { annotations = node_pool.annotations } : {},
        length(node_pool.labels) > 0 ? { labels = node_pool.labels } : {}
      )
      spec = node_pool.spec
    })
  }

  auto_mode_storage_class_manifests = {
    for name, storage_class in var.auto_mode_storage_classes : name => yamlencode(merge(
      {
        apiVersion = "storage.k8s.io/v1"
        kind       = "StorageClass"
        metadata = merge(
          { name = name },
          length(storage_class.annotations) > 0 ? { annotations = storage_class.annotations } : {},
          length(storage_class.labels) > 0 ? { labels = storage_class.labels } : {}
        )
        provisioner = "ebs.csi.eks.amazonaws.com"
        parameters = merge(
          {
            encrypted = "true"
            type      = "gp3"
          },
          storage_class.parameters
        )
        reclaimPolicy        = storage_class.reclaim_policy
        volumeBindingMode    = storage_class.volume_binding_mode
        allowVolumeExpansion = storage_class.allow_volume_expansion
      },
      length(storage_class.allowed_topologies) > 0 ? { allowedTopologies = storage_class.allowed_topologies } : {},
      length(storage_class.mount_options) > 0 ? { mountOptions = storage_class.mount_options } : {}
    ))
  }

  auto_mode_load_balancer_service_manifests = {
    for name, service in var.auto_mode_load_balancer_services : name => yamlencode({
      apiVersion = "v1"
      kind       = "Service"
      metadata = merge(
        {
          name      = name
          namespace = service.namespace
        },
        length(service.annotations) > 0 ? { annotations = service.annotations } : {},
        length(service.labels) > 0 ? { labels = service.labels } : {}
      )
      spec = merge(
        {
          type              = "LoadBalancer"
          loadBalancerClass = service.load_balancer_class
          ports             = service.ports
          selector          = service.selector
        },
        service.external_traffic_policy == null ? {} : { externalTrafficPolicy = service.external_traffic_policy },
        length(service.ip_families) > 0 ? { ipFamilies = service.ip_families } : {},
        service.ip_family_policy == null ? {} : { ipFamilyPolicy = service.ip_family_policy },
        length(service.load_balancer_source_ranges) > 0 ? { loadBalancerSourceRanges = service.load_balancer_source_ranges } : {},
        service.session_affinity == null ? {} : { sessionAffinity = service.session_affinity }
      )
    })
  }

  auto_mode_kubernetes_manifests = merge(
    {
      for name, manifest in local.auto_mode_node_class_manifests :
      "nodeclass/${name}" => manifest
    },
    {
      for name, manifest in local.auto_mode_node_pool_manifests :
      "nodepool/${name}" => manifest
    },
    {
      for name, manifest in local.auto_mode_storage_class_manifests :
      "storageclass/${name}" => manifest
    },
    {
      for name, manifest in local.auto_mode_load_balancer_service_manifests :
      "service/${name}" => manifest
    }
  )
}
