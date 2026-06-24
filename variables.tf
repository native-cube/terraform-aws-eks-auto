variable "name" {
  description = "Name prefix for module-created resources. Used as the EKS cluster name when cluster_name is null."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-_]{0,99}$", var.name))
    error_message = "The name must start with a letter or number and contain only letters, numbers, hyphens, and underscores."
  }
}

variable "cluster_name" {
  description = "Optional EKS cluster name. When null, name is used as the cluster name."
  type        = string
  default     = null

  validation {
    condition     = var.cluster_name == null || can(regex("^[A-Za-z0-9][A-Za-z0-9-_]{0,99}$", var.cluster_name))
    error_message = "The cluster_name must start with a letter or number and contain only letters, numbers, hyphens, and underscores."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster. Leave null to use the current AWS default."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS control plane and EKS Auto Mode managed compute. Use at least two subnets in different Availability Zones."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Provide at least two subnet IDs."
  }
}

variable "cluster_security_group_ids" {
  description = "Additional security group IDs to associate with the EKS control plane."
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Whether the Kubernetes API server endpoint is reachable from within the VPC."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the Kubernetes API server endpoint is reachable from the public internet."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks that can access the public Kubernetes API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "access_config" {
  description = "Optional EKS access configuration. EKS Auto Mode uses access entries, so authentication mode defaults to API."
  type = object({
    authentication_mode                         = optional(string)
    bootstrap_cluster_creator_admin_permissions = optional(bool)
  })
  default = null

  validation {
    condition = (
      var.access_config == null ||
      var.access_config.authentication_mode == null ||
      contains(["API", "API_AND_CONFIG_MAP"], var.access_config.authentication_mode)
    )
    error_message = "access_config.authentication_mode must be API or API_AND_CONFIG_MAP for this EKS Auto Mode module."
  }
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the EKS cluster. Leave null to use the AWS/provider default."
  type        = bool
  default     = null
}

variable "force_update_version" {
  description = "Whether to force version updates when EKS cannot drain pods."
  type        = bool
  default     = null
}

variable "bootstrap_self_managed_addons" {
  description = "Whether EKS bootstraps the default self-managed networking add-ons. Keep false for EKS Auto Mode."
  type        = bool
  default     = false
}

variable "cluster_encryption_config" {
  description = "Optional EKS encryption configuration for Kubernetes secrets using an existing KMS key."
  type = object({
    provider_key_arn = string
    resources        = optional(set(string), ["secrets"])
  })
  default = null

  validation {
    condition = (
      var.cluster_encryption_config == null ||
      alltrue([
        for resource in var.cluster_encryption_config.resources :
        resource == "secrets"
      ])
    )
    error_message = "cluster_encryption_config.resources currently supports only secrets."
  }
}

variable "enabled_cluster_log_types" {
  description = "EKS control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]

  validation {
    condition = alltrue([
      for log_type in var.enabled_cluster_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Cluster log types must be one of: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "cloudwatch_log_retention_days" {
  description = "Retention in days for the EKS control plane CloudWatch log group."
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731,
      1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.cloudwatch_log_retention_days)
    error_message = "CloudWatch log retention must be a valid AWS retention value."
  }
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "Optional KMS key ID or ARN for encrypting the EKS control plane CloudWatch log group."
  type        = string
  default     = null
}

variable "compute_config" {
  description = "EKS Auto Mode compute configuration. When enabled, the module can create the Auto Mode node IAM role and pass it to the cluster."
  type = object({
    create_node_iam_role = optional(bool, true)
    enabled              = optional(bool, true)
    node_iam_policy_arns = optional(set(string), [])
    node_iam_role_arn    = optional(string)
    node_iam_role_name   = optional(string)
    node_pools           = optional(set(string), ["general-purpose", "system"])
  })
  default = {}

  validation {
    condition = (
      !var.compute_config.enabled ||
      var.compute_config.create_node_iam_role ||
      var.compute_config.node_iam_role_arn != null
    )
    error_message = "When compute_config.enabled is true and create_node_iam_role is false, compute_config.node_iam_role_arn must be set."
  }

  validation {
    condition = alltrue([
      for node_pool in var.compute_config.node_pools :
      contains(["general-purpose", "system"], node_pool)
    ])
    error_message = "compute_config.node_pools supports only general-purpose and system."
  }

  validation {
    condition = (
      var.compute_config.node_iam_role_name == null ||
      can(regex("^[A-Za-z0-9+=,.@_-]{1,64}$", var.compute_config.node_iam_role_name))
    )
    error_message = "compute_config.node_iam_role_name must be 1-64 characters and contain only IAM role name characters."
  }
}

variable "elastic_load_balancing_enabled" {
  description = "Whether to enable EKS Auto Mode load balancing support."
  type        = bool
  default     = true
}

variable "block_storage_enabled" {
  description = "Whether to enable EKS Auto Mode block storage support."
  type        = bool
  default     = true
}

variable "ip_family" {
  description = "Optional Kubernetes service IP family. Valid values are ipv4 or ipv6."
  type        = string
  default     = null

  validation {
    condition     = var.ip_family == null || contains(["ipv4", "ipv6"], var.ip_family)
    error_message = "ip_family must be ipv4 or ipv6."
  }
}

variable "service_ipv4_cidr" {
  description = "Optional Kubernetes service IPv4 CIDR. Set only when you need a non-default service CIDR."
  type        = string
  default     = null
}

variable "control_plane_scaling_tier" {
  description = "Optional EKS control plane scaling tier. Leave null to use the AWS/provider default."
  type        = string
  default     = null

  validation {
    condition     = var.control_plane_scaling_tier == null || contains(["standard"], var.control_plane_scaling_tier)
    error_message = "control_plane_scaling_tier currently supports standard."
  }
}

variable "upgrade_policy_support_type" {
  description = "Optional Kubernetes version support policy. Valid values are STANDARD and EXTENDED."
  type        = string
  default     = null

  validation {
    condition     = var.upgrade_policy_support_type == null || contains(["STANDARD", "EXTENDED"], var.upgrade_policy_support_type)
    error_message = "upgrade_policy_support_type must be STANDARD or EXTENDED."
  }
}

variable "access_entries" {
  description = "Additional EKS access entries and optional access policy associations to create."
  type = map(object({
    kubernetes_groups = optional(set(string), [])
    policy_associations = optional(map(object({
      access_scope = object({
        namespaces = optional(set(string), [])
        type       = string
      })
      policy_arn = string
    })), {})
    principal_arn = string
    type          = optional(string, "STANDARD")
    user_name     = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for _, entry in var.access_entries :
      contains(["STANDARD", "EC2_LINUX", "EC2_WINDOWS", "FARGATE_LINUX", "HYBRID_LINUX"], entry.type)
    ])
    error_message = "access_entries[*].type must be STANDARD, EC2_LINUX, EC2_WINDOWS, FARGATE_LINUX, or HYBRID_LINUX."
  }

  validation {
    condition = alltrue(flatten([
      for _, entry in var.access_entries : [
        for _, association in entry.policy_associations :
        contains(["cluster", "namespace"], association.access_scope.type)
      ]
    ]))
    error_message = "access_entries[*].policy_associations[*].access_scope.type must be cluster or namespace."
  }
}

variable "capabilities" {
  description = "Amazon EKS managed capabilities to create, keyed by a stable local name. Supported types are ARGOCD, ACK, and KRO. The module can create a capability IAM role per entry, or use an externally managed role ARN."
  type = map(object({
    capability_name           = optional(string)
    create_iam_role           = optional(bool, true)
    delete_propagation_policy = optional(string, "RETAIN")
    iam_policy_arns           = optional(set(string), [])
    iam_role_arn              = optional(string)
    iam_role_name             = optional(string)
    inline_policy_json        = optional(string)
    type                      = string
    argocd = optional(object({
      idc_instance_arn        = optional(string)
      idc_region              = optional(string)
      namespace               = optional(string)
      network_access_vpce_ids = optional(set(string), [])
      rbac_role_mappings = optional(list(object({
        role = string
        identities = list(object({
          id   = string
          type = string
        }))
      })), [])
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for _, capability in var.capabilities :
      contains(["ACK", "ARGOCD", "KRO"], upper(capability.type))
    ])
    error_message = "capabilities entries must use type ACK, ARGOCD, or KRO."
  }

  validation {
    condition = alltrue([
      for _, capability in var.capabilities :
      capability.create_iam_role || capability.iam_role_arn != null
    ])
    error_message = "When capabilities[*].create_iam_role is false, capabilities[*].iam_role_arn must be set."
  }

  validation {
    condition = alltrue([
      for _, capability in var.capabilities :
      capability.capability_name == null || can(regex("^[A-Za-z0-9][A-Za-z0-9-_]{0,99}$", capability.capability_name))
    ])
    error_message = "capabilities[*].capability_name must start with a letter or number and contain only letters, numbers, hyphens, and underscores."
  }

  validation {
    condition = alltrue([
      for _, capability in var.capabilities :
      capability.delete_propagation_policy == "RETAIN"
    ])
    error_message = "capabilities[*].delete_propagation_policy currently supports only RETAIN."
  }

  validation {
    condition = alltrue([
      for _, capability in var.capabilities :
      capability.iam_role_name == null || can(regex("^[A-Za-z0-9+=,.@_-]{1,64}$", capability.iam_role_name))
    ])
    error_message = "capabilities[*].iam_role_name must be 1-64 characters and contain only IAM role name characters."
  }

  validation {
    condition = alltrue([
      for _, capability in var.capabilities :
      upper(capability.type) != "ARGOCD" || (
        capability.argocd != null &&
        capability.argocd.idc_instance_arn != null
      )
    ])
    error_message = "ARGOCD capabilities require an argocd object with idc_instance_arn set."
  }

  validation {
    condition = alltrue([
      for _, capability in var.capabilities :
      upper(capability.type) == "ARGOCD" || capability.argocd == null
    ])
    error_message = "Only ARGOCD capabilities may configure the argocd object."
  }

  validation {
    condition = alltrue(flatten([
      for _, capability in var.capabilities :
      capability.argocd == null ? [true] : [
        for mapping in capability.argocd.rbac_role_mappings :
        contains(["ADMIN", "EDITOR", "VIEWER"], mapping.role)
      ]
    ]))
    error_message = "capabilities[*].argocd.rbac_role_mappings role must be ADMIN, EDITOR, or VIEWER."
  }

  validation {
    condition = alltrue(flatten([
      for _, capability in var.capabilities :
      capability.argocd == null ? [true] : flatten([
        for mapping in capability.argocd.rbac_role_mappings : [
          for identity in mapping.identities :
          contains(["SSO_USER", "SSO_GROUP"], identity.type)
        ]
      ])
    ]))
    error_message = "capabilities[*].argocd.rbac_role_mappings identity type must be SSO_USER or SSO_GROUP."
  }
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
