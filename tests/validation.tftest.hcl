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

run "rejects_single_subnet" {
  command = plan

  variables {
    name       = "unit-invalid-subnets"
    subnet_ids = ["subnet-0123456789abcdef0"]
  }

  expect_failures = [
    var.subnet_ids
  ]
}

run "rejects_config_map_authentication" {
  command = plan

  variables {
    name = "unit-invalid-access"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    access_config = {
      authentication_mode = "CONFIG_MAP"
    }
  }

  expect_failures = [
    var.access_config
  ]
}

run "rejects_auto_mode_external_role_without_arn" {
  command = plan

  variables {
    name = "unit-invalid-node-role"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    compute_config = {
      enabled              = true
      create_node_iam_role = false
    }
  }

  expect_failures = [
    var.compute_config
  ]
}

run "rejects_invalid_auto_mode_node_pool" {
  command = plan

  variables {
    name = "unit-invalid-node-pool"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    compute_config = {
      node_pools = ["gpu"]
    }
  }

  expect_failures = [
    var.compute_config
  ]
}

run "rejects_invalid_ip_family" {
  command = plan

  variables {
    name = "unit-invalid-ip-family"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    ip_family = "dualstack"
  }

  expect_failures = [
    var.ip_family
  ]
}

run "rejects_invalid_access_scope" {
  command = plan

  variables {
    name = "unit-invalid-access-scope"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    access_entries = {
      platform_admin = {
        principal_arn = "arn:aws:iam::123456789012:role/platform-admin"
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "invalid"
            }
          }
        }
      }
    }
  }

  expect_failures = [
    var.access_entries
  ]
}

run "rejects_invalid_capability_type" {
  command = plan

  variables {
    name = "unit-invalid-capability-type"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    capabilities = {
      invalid = {
        type = "FLUXCD"
      }
    }
  }

  expect_failures = [
    var.capabilities
  ]
}

run "rejects_argocd_capability_without_identity_center_instance" {
  command = plan

  variables {
    name = "unit-invalid-argocd-idc"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    capabilities = {
      argocd = {
        type   = "ARGOCD"
        argocd = {}
      }
    }
  }

  expect_failures = [
    var.capabilities
  ]
}

run "rejects_duplicate_capability_types" {
  command = plan

  variables {
    name = "unit-invalid-duplicate-capabilities"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    capabilities = {
      ack_one = {
        type = "ACK"
      }
      ack_two = {
        type = "ACK"
      }
    }
  }

  expect_failures = [
    var.capabilities
  ]
}

run "rejects_invalid_capability_iam_policy_preset" {
  command = plan

  variables {
    name = "unit-invalid-capability-preset"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    capabilities = {
      ack = {
        type               = "ACK"
        iam_policy_presets = ["admin_everything"]
      }
    }
  }

  expect_failures = [
    var.capabilities
  ]
}

run "rejects_argocd_config_for_non_argocd_capability" {
  command = plan

  variables {
    name = "unit-invalid-non-argocd-config"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    capabilities = {
      ack = {
        type = "ACK"
        argocd = {
          idc_instance_arn = "arn:aws:sso:::instance/ssoins-7223a1b234567890"
        }
      }
    }
  }

  expect_failures = [
    var.capabilities
  ]
}
