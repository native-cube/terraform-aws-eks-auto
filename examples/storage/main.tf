terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "eks_auto" {
  source = "../.."

  name               = var.name
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  subnet_ids         = var.subnet_ids

  auto_mode_node_classes = {
    storage = {
      spec = {
        ephemeralStorage = {
          size = "80Gi"
        }
        tags = {
          workload = "stateful"
        }
      }
    }
  }

  auto_mode_node_pools = {
    storage = {
      labels = {
        workload = "stateful"
      }
      spec = {
        disruption = {
          consolidationPolicy = "WhenEmptyOrUnderutilized"
          consolidateAfter    = "5m"
        }
        limits = {
          cpu = "200"
        }
        template = {
          metadata = {
            labels = {
              workload = "stateful"
            }
          }
          spec = {
            nodeClassRef = {
              group = "eks.amazonaws.com"
              kind  = "NodeClass"
              name  = "storage"
            }
            requirements = [
              {
                key      = "eks.amazonaws.com/instance-category"
                operator = "In"
                values   = ["m", "r"]
              },
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
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "true"
      }
      parameters = {
        encrypted = "true"
        fsType    = "ext4"
        type      = "gp3"
      }
      reclaim_policy      = "Delete"
      volume_binding_mode = "WaitForFirstConsumer"
    }
  }

  tags = merge(
    var.tags,
    {
      Example = "storage"
    }
  )
}
