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

run "default_auto_mode_cluster_shape" {
  command = plan

  variables {
    name = "unit-default"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    tags = {
      Environment = "test"
    }
  }

  assert {
    condition     = aws_eks_cluster.this.name == "unit-default"
    error_message = "The EKS cluster name should match var.name."
  }

  assert {
    condition     = aws_eks_cluster.this.bootstrap_self_managed_addons == false
    error_message = "EKS Auto Mode should not bootstrap self-managed add-ons by default."
  }

  assert {
    condition     = aws_eks_cluster.this.access_config[0].authentication_mode == "API"
    error_message = "EKS Auto Mode should default to API authentication."
  }

  assert {
    condition     = aws_eks_cluster.this.compute_config[0].enabled == true
    error_message = "EKS Auto Mode compute should be enabled by default."
  }

  assert {
    condition     = toset(aws_eks_cluster.this.compute_config[0].node_pools) == toset(["general-purpose", "system"])
    error_message = "The default Auto Mode node pools should be general-purpose and system."
  }

  assert {
    condition     = length(aws_iam_role.node) == 1
    error_message = "The Auto Mode node IAM role should be created by default."
  }

  assert {
    condition     = contains(keys(aws_iam_role_policy_attachment.node), "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy")
    error_message = "The Auto Mode node role should include the minimal EKS worker node policy."
  }

  assert {
    condition     = contains(keys(aws_iam_role_policy_attachment.node), "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly")
    error_message = "The Auto Mode node role should include the ECR pull-only policy."
  }

  assert {
    condition     = contains(keys(aws_iam_role_policy_attachment.cluster), "arn:aws:iam::aws:policy/AmazonEKSComputePolicy")
    error_message = "The cluster role should include the EKS Auto Mode compute policy."
  }

  assert {
    condition     = aws_eks_cluster.this.kubernetes_network_config[0].elastic_load_balancing[0].enabled == true
    error_message = "EKS Auto Mode load balancing should be enabled by default."
  }

  assert {
    condition     = aws_eks_cluster.this.storage_config[0].block_storage[0].enabled == true
    error_message = "EKS Auto Mode block storage should be enabled by default."
  }

  assert {
    condition     = aws_cloudwatch_log_group.cluster[0].name == "/aws/eks/unit-default/cluster"
    error_message = "The control plane log group name should follow the EKS log group convention."
  }

  assert {
    condition     = length(aws_eks_capability.this) == 0
    error_message = "EKS capabilities should not be created by default."
  }
}
