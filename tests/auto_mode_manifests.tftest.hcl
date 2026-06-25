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

run "auto_mode_manifests_and_pod_identity" {
  command = plan

  variables {
    name = "unit-auto-manifests"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    auto_mode_node_classes = {
      custom = {
        spec = {
          ephemeralStorage = {
            size = "60Gi"
          }
          subnetSelectorTerms = [
            {
              tags = {
                Tier = "private"
              }
            }
          ]
        }
      }
    }

    auto_mode_node_pools = {
      custom = {
        spec = {
          template = {
            spec = {
              nodeClassRef = {
                group = "eks.amazonaws.com"
                kind  = "NodeClass"
                name  = "custom"
              }
              requirements = [
                {
                  key      = "karpenter.sh/capacity-type"
                  operator = "In"
                  values   = ["on-demand"]
                }
              ]
            }
          }
        }
      }
    }

    auto_mode_storage_classes = {
      "gp3-encrypted" = {
        parameters = {
          type = "gp3"
        }
      }
    }

    auto_mode_load_balancer_services = {
      web = {
        selector = {
          app = "web"
        }
        ports = [
          {
            name       = "http"
            port       = 80
            protocol   = "TCP"
            targetPort = 8080
          }
        ]
      }
    }

    pod_identity_associations = {
      web = {
        namespace       = "default"
        service_account = "web"
        iam_policy_arns = [
          "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        ]
      }
    }
  }

  assert {
    condition     = yamldecode(local.auto_mode_node_class_manifests["custom"]).kind == "NodeClass"
    error_message = "The module should render custom Auto Mode NodeClass YAML."
  }

  assert {
    condition     = yamldecode(local.auto_mode_node_class_manifests["custom"]).spec.role == "unit-auto-manifests-auto-node-role"
    error_message = "Custom NodeClass manifests should default to the Auto Mode node role name."
  }

  assert {
    condition     = yamldecode(local.auto_mode_node_pool_manifests["custom"]).kind == "NodePool"
    error_message = "The module should render custom Auto Mode NodePool YAML."
  }

  assert {
    condition     = yamldecode(local.auto_mode_storage_class_manifests["gp3-encrypted"]).provisioner == "ebs.csi.eks.amazonaws.com"
    error_message = "The module should render EKS Auto Mode EBS StorageClass YAML."
  }

  assert {
    condition     = yamldecode(local.auto_mode_load_balancer_service_manifests["web"]).spec.loadBalancerClass == "eks.amazonaws.com/nlb"
    error_message = "The module should render EKS Auto Mode NLB Service YAML."
  }

  assert {
    condition     = aws_eks_access_entry.auto_mode_node_class["custom"].type == "EC2"
    error_message = "Custom NodeClass IAM roles should get EC2 access entries."
  }

  assert {
    condition     = aws_eks_access_policy_association.auto_mode_node_class["custom"].policy_arn == "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy"
    error_message = "Custom NodeClass IAM roles should get the AmazonEKSAutoNodePolicy association."
  }

  assert {
    condition     = aws_eks_pod_identity_association.this["web"].namespace == "default"
    error_message = "The Pod Identity association should target the configured namespace."
  }

  assert {
    condition     = aws_eks_pod_identity_association.this["web"].service_account == "web"
    error_message = "The Pod Identity association should target the configured service account."
  }

  assert {
    condition     = contains(keys(aws_iam_role_policy_attachment.pod_identity), "web:arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy")
    error_message = "Pod Identity IAM role managed policies should be attached."
  }
}
