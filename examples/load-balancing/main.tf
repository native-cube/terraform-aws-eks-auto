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

  pod_identity_associations = {
    web = {
      namespace       = "default"
      service_account = "web"
      iam_policy_arns = var.web_pod_iam_policy_arns
    }
  }

  auto_mode_load_balancer_services = {
    web = {
      namespace = "default"
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-scheme"      = "internal"
        "service.beta.kubernetes.io/aws-load-balancer-target-type" = "ip"
      }
      labels = {
        app = "web"
      }
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

  tags = merge(
    var.tags,
    {
      Example = "load-balancing"
    }
  )
}
