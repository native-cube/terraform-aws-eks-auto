mock_provider "aws" {
  override_during = plan

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"eks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn  = "arn:aws:iam::123456789012:role/mock-eks-role"
      name = "mock-eks-role"
    }
  }
}

run "custom_auto_mode_cluster_shape" {
  command = plan

  variables {
    name               = "unit-custom-prefix"
    cluster_name       = "unit-custom"
    kubernetes_version = "1.30"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    endpoint_private_access = true
    endpoint_public_access  = false
    public_access_cidrs     = ["203.0.113.10/32"]
    cluster_security_group_ids = [
      "sg-0123456789abcdef0"
    ]

    access_config = {
      authentication_mode                         = "API_AND_CONFIG_MAP"
      bootstrap_cluster_creator_admin_permissions = true
    }

    deletion_protection             = true
    force_update_version            = true
    enabled_cluster_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    cloudwatch_log_retention_days   = 90
    cloudwatch_log_group_kms_key_id = "arn:aws:kms:eu-west-2:123456789012:key/00000000-0000-0000-0000-000000000001"
    cluster_encryption_config = {
      provider_key_arn = "arn:aws:kms:eu-west-2:123456789012:key/00000000-0000-0000-0000-000000000002"
      resources        = ["secrets"]
    }

    compute_config = {
      create_node_iam_role = false
      enabled              = true
      node_iam_role_arn    = "arn:aws:iam::123456789012:role/platform/EKS-AutoNodeRole"
      node_pools           = ["system"]
    }

    elastic_load_balancing_enabled = false
    block_storage_enabled          = false
    ip_family                      = "ipv4"
    service_ipv4_cidr              = "172.20.0.0/16"
    upgrade_policy_support_type    = "STANDARD"

    access_entries = {
      platform_admin = {
        principal_arn = "arn:aws:iam::123456789012:role/platform-admin"
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    }

    tags = {
      Environment = "test"
      Owner       = "platform"
    }
  }

  assert {
    condition     = aws_eks_cluster.this.name == "unit-custom"
    error_message = "The EKS cluster should use cluster_name when it is set."
  }

  assert {
    condition     = aws_eks_cluster.this.version == "1.30"
    error_message = "The cluster should use the requested Kubernetes version."
  }

  assert {
    condition     = aws_eks_cluster.this.deletion_protection == true
    error_message = "Cluster deletion protection should be configurable."
  }

  assert {
    condition     = aws_eks_cluster.this.access_config[0].authentication_mode == "API_AND_CONFIG_MAP"
    error_message = "Cluster access authentication mode should be configurable."
  }

  assert {
    condition     = aws_eks_cluster.this.compute_config[0].node_role_arn == "arn:aws:iam::123456789012:role/platform/EKS-AutoNodeRole"
    error_message = "External Auto Mode node role mode should use the supplied role ARN."
  }

  assert {
    condition     = length(aws_iam_role.node) == 0
    error_message = "External Auto Mode node role mode should not create a node IAM role."
  }

  assert {
    condition     = toset(aws_eks_cluster.this.compute_config[0].node_pools) == toset(["system"])
    error_message = "Auto Mode node pools should be configurable."
  }

  assert {
    condition     = aws_eks_cluster.this.kubernetes_network_config[0].elastic_load_balancing[0].enabled == false
    error_message = "Auto Mode load balancing should be configurable."
  }

  assert {
    condition     = aws_eks_cluster.this.storage_config[0].block_storage[0].enabled == false
    error_message = "Auto Mode block storage should be configurable."
  }

  assert {
    condition     = aws_eks_cluster.this.kubernetes_network_config[0].service_ipv4_cidr == "172.20.0.0/16"
    error_message = "The cluster should use the configured service IPv4 CIDR."
  }

  assert {
    condition     = contains(keys(aws_eks_access_entry.this), "platform_admin")
    error_message = "The configured access entry should be created."
  }

  assert {
    condition     = contains(keys(aws_eks_access_policy_association.this), "platform_admin:admin")
    error_message = "The configured access policy association should be created."
  }
}
