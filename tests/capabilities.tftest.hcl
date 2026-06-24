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

run "capabilities_cluster_shape" {
  command = plan

  variables {
    name = "unit-capabilities"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    capabilities = {
      argocd = {
        type            = "ARGOCD"
        capability_name = "argocd"
        argocd = {
          idc_instance_arn = "arn:aws:sso:::instance/ssoins-7223a1b234567890"
          idc_region       = "eu-west-2"
          namespace        = "argocd"
          network_access_vpce_ids = [
            "vpce-0123456789abcdef0"
          ]
          rbac_role_mappings = [
            {
              role = "ADMIN"
              identities = [
                {
                  id   = "12345678-1234-1234-1234-123456789012"
                  type = "SSO_GROUP"
                }
              ]
            },
            {
              role = "VIEWER"
              identities = [
                {
                  id   = "87654321-4321-4321-4321-210987654321"
                  type = "SSO_USER"
                }
              ]
            }
          ]
        }
        iam_policy_arns = [
          "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
        ]
      }

      ack = {
        type = "ACK"
      }

      kro = {
        type            = "KRO"
        create_iam_role = false
        iam_role_arn    = "arn:aws:iam::123456789012:role/platform/KROCapabilityRole-external"
      }
    }
  }

  assert {
    condition     = toset(keys(aws_eks_capability.this)) == toset(["ack", "argocd", "kro"])
    error_message = "The module should create each configured EKS capability."
  }

  assert {
    condition     = aws_eks_capability.this["argocd"].type == "ARGOCD"
    error_message = "The Argo CD capability type should be ARGOCD."
  }

  assert {
    condition     = aws_eks_capability.this["ack"].type == "ACK"
    error_message = "The ACK capability type should be ACK."
  }

  assert {
    condition     = aws_eks_capability.this["kro"].type == "KRO"
    error_message = "The KRO capability type should be KRO."
  }

  assert {
    condition     = aws_eks_capability.this["ack"].capability_name == "ack"
    error_message = "Capability names should default to the map key."
  }

  assert {
    condition     = aws_eks_capability.this["argocd"].configuration[0].argo_cd[0].namespace == "argocd"
    error_message = "The Argo CD namespace should be configurable."
  }

  assert {
    condition     = contains(aws_eks_capability.this["argocd"].configuration[0].argo_cd[0].network_access[0].vpce_ids, "vpce-0123456789abcdef0")
    error_message = "The Argo CD capability should support private VPC endpoint access."
  }

  assert {
    condition     = toset(keys(aws_iam_role.eks_capability)) == toset(["ack", "argocd"])
    error_message = "The module should create IAM roles only for capabilities with create_iam_role enabled."
  }

  assert {
    condition     = contains(keys(aws_iam_role_policy_attachment.eks_capability), "argocd:arn:aws:iam::aws:policy/SecretsManagerReadWrite")
    error_message = "Configured capability managed policies should be attached to the created IAM role."
  }

  assert {
    condition     = aws_eks_capability.this["kro"].role_arn == "arn:aws:iam::123456789012:role/platform/KROCapabilityRole-external"
    error_message = "External capability role mode should use the supplied IAM role ARN."
  }
}
