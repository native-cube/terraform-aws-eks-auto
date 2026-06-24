resource "aws_eks_cluster" "this" {
  bootstrap_self_managed_addons = var.bootstrap_self_managed_addons
  deletion_protection           = var.deletion_protection
  enabled_cluster_log_types     = var.enabled_cluster_log_types
  force_update_version          = var.force_update_version
  name                          = local.cluster_name
  role_arn                      = aws_iam_role.cluster.arn
  version                       = var.kubernetes_version

  vpc_config {
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = var.cluster_security_group_ids
    subnet_ids              = var.subnet_ids
  }

  access_config {
    authentication_mode                         = local.cluster_access_config.authentication_mode
    bootstrap_cluster_creator_admin_permissions = local.cluster_access_config.bootstrap_cluster_creator_admin_permissions
  }

  compute_config {
    enabled       = local.compute_enabled
    node_pools    = local.compute_enabled ? var.compute_config.node_pools : null
    node_role_arn = local.compute_enabled ? local.auto_mode_node_iam_role_arn : null
  }

  kubernetes_network_config {
    ip_family         = var.ip_family
    service_ipv4_cidr = var.service_ipv4_cidr

    elastic_load_balancing {
      enabled = var.elastic_load_balancing_enabled
    }
  }

  storage_config {
    block_storage {
      enabled = var.block_storage_enabled
    }
  }

  dynamic "control_plane_scaling_config" {
    for_each = var.control_plane_scaling_tier == null ? [] : [var.control_plane_scaling_tier]

    content {
      tier = control_plane_scaling_config.value
    }
  }

  dynamic "encryption_config" {
    for_each = var.cluster_encryption_config == null ? [] : [var.cluster_encryption_config]

    content {
      resources = encryption_config.value.resources

      provider {
        key_arn = encryption_config.value.provider_key_arn
      }
    }
  }

  dynamic "upgrade_policy" {
    for_each = var.upgrade_policy_support_type == null ? [] : [var.upgrade_policy_support_type]

    content {
      support_type = upgrade_policy.value
    }
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.cluster,
    aws_iam_role_policy_attachment.cluster,
    aws_iam_role_policy_attachment.node
  ]
}

resource "aws_eks_access_entry" "this" {
  for_each = var.access_entries

  cluster_name      = aws_eks_cluster.this.name
  kubernetes_groups = each.value.kubernetes_groups
  principal_arn     = each.value.principal_arn
  tags              = local.common_tags
  type              = each.value.type
  user_name         = each.value.user_name
}

resource "aws_eks_access_policy_association" "this" {
  for_each = local.access_policy_associations

  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = each.value.policy_arn
  principal_arn = each.value.principal_arn

  access_scope {
    namespaces = each.value.access_scope.namespaces
    type       = each.value.access_scope.type
  }

  depends_on = [
    aws_eks_access_entry.this
  ]
}

resource "aws_eks_capability" "this" {
  for_each = local.eks_capability_configs

  capability_name           = each.value.capability_name
  cluster_name              = aws_eks_cluster.this.name
  delete_propagation_policy = each.value.delete_propagation_policy
  role_arn                  = local.eks_capability_iam_role_arns[each.key]
  tags                      = local.common_tags
  type                      = each.value.type

  dynamic "configuration" {
    for_each = each.value.type == "ARGOCD" && each.value.argocd != null ? [each.value.argocd] : []

    content {
      argo_cd {
        namespace = configuration.value.namespace

        aws_idc {
          idc_instance_arn = configuration.value.idc_instance_arn
          idc_region       = configuration.value.idc_region
        }

        dynamic "network_access" {
          for_each = length(configuration.value.network_access_vpce_ids) > 0 ? [configuration.value.network_access_vpce_ids] : []

          content {
            vpce_ids = network_access.value
          }
        }

        dynamic "rbac_role_mapping" {
          for_each = configuration.value.rbac_role_mappings

          content {
            role = rbac_role_mapping.value.role

            dynamic "identity" {
              for_each = rbac_role_mapping.value.identities

              content {
                id   = identity.value.id
                type = identity.value.type
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    aws_iam_role_policy.eks_capability,
    aws_iam_role_policy_attachment.eks_capability
  ]
}
