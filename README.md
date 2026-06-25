# Terraform AWS EKS Auto Mode Module

Terraform module for creating an Amazon EKS cluster with EKS Auto Mode enabled by default:

- EKS control plane IAM role with EKS Auto Mode policies.
- Optional module-created EKS Auto Mode node IAM role.
- EKS Auto Mode managed compute with configurable built-in node pools.
- EKS Auto Mode load balancing and block storage switches.
- Rendered Kubernetes manifests for custom Auto Mode NodeClasses, NodePools, StorageClasses, and LoadBalancer Services.
- Optional EKS Pod Identity associations.
- Optional EKS access entries and access policy associations.
- Optional Amazon EKS managed capabilities: Argo CD, ACK, and KRO.
- Useful connection and composition outputs.

The module expects you to provide existing subnet IDs. In most deployments these should be private subnets with outbound internet access through NAT.
The Kubernetes API endpoint is private by default; enable public endpoint access only when callers outside the VPC need it.

## Usage

```hcl
module "eks_auto" {
  source = "./eks-auto"

  name       = "dev-auto"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]

  tags = {
    Environment = "dev"
  }
}
```

Then configure `kubectl`:

```bash
aws eks update-kubeconfig --name dev-auto
```

## Examples

- `examples/minimal` - smallest practical EKS Auto Mode module call using defaults for compute, API access, logging, load balancing, and block storage.
- `examples/capabilities` - EKS Auto Mode with all supported EKS capabilities: Argo CD, ACK, and KRO.
- `examples/storage` - custom Auto Mode NodeClass, NodePool, and encrypted gp3 StorageClass manifests.
- `examples/load-balancing` - Pod Identity and an EKS Auto Mode Network Load Balancer Service manifest.

## EKS Auto Mode

By default, this module sets:

- `endpoint_private_access = true`
- `endpoint_public_access = false`
- `bootstrap_self_managed_addons = false`
- `compute_config.enabled = true`
- `compute_config.node_pools = ["general-purpose", "system"]`
- `elastic_load_balancing_enabled = true`
- `block_storage_enabled = true`
- `access_config.authentication_mode = "API"`

The module can create the Auto Mode node IAM role, or callers can pass an existing node role ARN through `compute_config.node_iam_role_arn`.

## Rendered Kubernetes Manifests

This module does not introduce a Kubernetes provider. Instead, it can render Auto Mode Kubernetes manifests as outputs:

- `auto_mode_node_classes`
- `auto_mode_node_pools`
- `auto_mode_storage_classes`
- `auto_mode_load_balancer_services`

Apply the combined YAML after the cluster is reachable:

```bash
terraform output -raw auto_mode_kubernetes_manifest_yaml | kubectl apply -f -
```

## Pod Identity

Use `pod_identity_associations` to create AWS-native EKS Pod Identity associations. The module can create one IAM role per association, attach managed policies or inline JSON, and associate it with a Kubernetes service account.

## EKS Capabilities

Enable the `capabilities` map when this module should create Amazon EKS managed capabilities. Supported types are `ARGOCD`, `ACK`, and `KRO`.

```hcl
capabilities = {
  argocd = {
    type = "ARGOCD"
    argocd = {
      idc_instance_arn = "arn:aws:sso:::instance/ssoins-7223a1b234567890"
      namespace        = "argocd"
    }
  }

  ack = {
    type = "ACK"
  }

  kro = {
    type = "KRO"
  }
}
```

For `ARGOCD`, configure the nested `argocd` object with IAM Identity Center settings, optional RBAC role mappings, and optional VPC endpoint IDs. Attach managed policies or an inline policy to a capability role only when that capability needs access to supporting AWS services.
Capability role presets are available through `iam_policy_presets`: `cloudcontrol_read_only`, `eks_read_only`, `resource_tagging`, and `secrets_read_only`.

## Module Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eks_access_entry.auto_mode_node_class](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_entry.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.auto_mode_node_class](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_access_policy_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_capability.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_capability) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_pod_identity_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_capability](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.pod_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.eks_capability](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.eks_capability_preset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.pod_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_capability](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.pod_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_config"></a> [access\_config](#input\_access\_config) | Optional EKS access configuration. EKS Auto Mode uses access entries, so authentication mode defaults to API. | <pre>object({<br/>    authentication_mode                         = optional(string)<br/>    bootstrap_cluster_creator_admin_permissions = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_access_entries"></a> [access\_entries](#input\_access\_entries) | Additional EKS access entries and optional access policy associations to create. | <pre>map(object({<br/>    kubernetes_groups = optional(set(string), [])<br/>    policy_associations = optional(map(object({<br/>      access_scope = object({<br/>        namespaces = optional(set(string), [])<br/>        type       = string<br/>      })<br/>      policy_arn = string<br/>    })), {})<br/>    principal_arn = string<br/>    type          = optional(string, "STANDARD")<br/>    user_name     = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_auto_mode_load_balancer_services"></a> [auto\_mode\_load\_balancer\_services](#input\_auto\_mode\_load\_balancer\_services) | EKS Auto Mode Network Load Balancer Service manifests to render as YAML, keyed by Kubernetes metadata.name. | <pre>map(object({<br/>    annotations                 = optional(map(string), {})<br/>    external_traffic_policy     = optional(string)<br/>    ip_families                 = optional(list(string), [])<br/>    ip_family_policy            = optional(string)<br/>    labels                      = optional(map(string), {})<br/>    load_balancer_class         = optional(string, "eks.amazonaws.com/nlb")<br/>    load_balancer_source_ranges = optional(list(string), [])<br/>    namespace                   = optional(string, "default")<br/>    ports                       = list(any)<br/>    selector                    = map(string)<br/>    session_affinity            = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_auto_mode_node_classes"></a> [auto\_mode\_node\_classes](#input\_auto\_mode\_node\_classes) | Custom EKS Auto Mode NodeClass manifests to render as YAML, keyed by Kubernetes metadata.name. The module does not apply these manifests because it intentionally avoids adding a Kubernetes provider. | <pre>map(object({<br/>    annotations         = optional(map(string), {})<br/>    create_access_entry = optional(bool, true)<br/>    labels              = optional(map(string), {})<br/>    node_role_arn       = optional(string)<br/>    spec                = any<br/>  }))</pre> | `{}` | no |
| <a name="input_auto_mode_node_pools"></a> [auto\_mode\_node\_pools](#input\_auto\_mode\_node\_pools) | Custom EKS Auto Mode NodePool manifests to render as YAML, keyed by Kubernetes metadata.name. The module does not apply these manifests because it intentionally avoids adding a Kubernetes provider. | <pre>map(object({<br/>    annotations = optional(map(string), {})<br/>    labels      = optional(map(string), {})<br/>    spec        = any<br/>  }))</pre> | `{}` | no |
| <a name="input_auto_mode_storage_classes"></a> [auto\_mode\_storage\_classes](#input\_auto\_mode\_storage\_classes) | EKS Auto Mode EBS StorageClass manifests to render as YAML, keyed by Kubernetes metadata.name. | <pre>map(object({<br/>    allow_volume_expansion = optional(bool, true)<br/>    allowed_topologies     = optional(list(any), [])<br/>    annotations            = optional(map(string), {})<br/>    labels                 = optional(map(string), {})<br/>    mount_options          = optional(list(string), [])<br/>    parameters             = optional(map(string), {})<br/>    reclaim_policy         = optional(string, "Delete")<br/>    volume_binding_mode    = optional(string, "WaitForFirstConsumer")<br/>  }))</pre> | `{}` | no |
| <a name="input_block_storage_enabled"></a> [block\_storage\_enabled](#input\_block\_storage\_enabled) | Whether to enable EKS Auto Mode block storage support. | `bool` | `true` | no |
| <a name="input_bootstrap_self_managed_addons"></a> [bootstrap\_self\_managed\_addons](#input\_bootstrap\_self\_managed\_addons) | Whether EKS bootstraps the default self-managed networking add-ons. Keep false for EKS Auto Mode. | `bool` | `false` | no |
| <a name="input_capabilities"></a> [capabilities](#input\_capabilities) | Amazon EKS managed capabilities to create, keyed by a stable local name. Supported types are ARGOCD, ACK, and KRO. The module can create a capability IAM role per entry, or use an externally managed role ARN. | <pre>map(object({<br/>    capability_name           = optional(string)<br/>    create_iam_role           = optional(bool, true)<br/>    delete_propagation_policy = optional(string, "RETAIN")<br/>    iam_policy_arns           = optional(set(string), [])<br/>    iam_policy_presets        = optional(set(string), [])<br/>    iam_role_arn              = optional(string)<br/>    iam_role_name             = optional(string)<br/>    inline_policy_json        = optional(string)<br/>    type                      = string<br/>    argocd = optional(object({<br/>      idc_instance_arn        = optional(string)<br/>      idc_region              = optional(string)<br/>      namespace               = optional(string)<br/>      network_access_vpce_ids = optional(set(string), [])<br/>      rbac_role_mappings = optional(list(object({<br/>        role = string<br/>        identities = list(object({<br/>          id   = string<br/>          type = string<br/>        }))<br/>      })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | Optional KMS key ID or ARN for encrypting the EKS control plane CloudWatch log group. | `string` | `null` | no |
| <a name="input_cloudwatch_log_retention_days"></a> [cloudwatch\_log\_retention\_days](#input\_cloudwatch\_log\_retention\_days) | Retention in days for the EKS control plane CloudWatch log group. | `number` | `30` | no |
| <a name="input_cluster_encryption_config"></a> [cluster\_encryption\_config](#input\_cluster\_encryption\_config) | Optional EKS encryption configuration for Kubernetes secrets using an existing KMS key. | <pre>object({<br/>    provider_key_arn = string<br/>    resources        = optional(set(string), ["secrets"])<br/>  })</pre> | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Optional EKS cluster name. When null, name is used as the cluster name. | `string` | `null` | no |
| <a name="input_cluster_security_group_ids"></a> [cluster\_security\_group\_ids](#input\_cluster\_security\_group\_ids) | Additional security group IDs to associate with the EKS control plane. | `list(string)` | `[]` | no |
| <a name="input_compute_config"></a> [compute\_config](#input\_compute\_config) | EKS Auto Mode compute configuration. When enabled, the module can create the Auto Mode node IAM role and pass it to the cluster. | <pre>object({<br/>    create_node_iam_role = optional(bool, true)<br/>    enabled              = optional(bool, true)<br/>    node_iam_policy_arns = optional(set(string), [])<br/>    node_iam_role_arn    = optional(string)<br/>    node_iam_role_name   = optional(string)<br/>    node_pools           = optional(set(string), ["general-purpose", "system"])<br/>  })</pre> | `{}` | no |
| <a name="input_control_plane_scaling_tier"></a> [control\_plane\_scaling\_tier](#input\_control\_plane\_scaling\_tier) | Optional EKS control plane scaling tier. Leave null to use the AWS/provider default. | `string` | `null` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Whether to enable deletion protection for the EKS cluster. Leave null to use the AWS/provider default. | `bool` | `null` | no |
| <a name="input_elastic_load_balancing_enabled"></a> [elastic\_load\_balancing\_enabled](#input\_elastic\_load\_balancing\_enabled) | Whether to enable EKS Auto Mode load balancing support. | `bool` | `true` | no |
| <a name="input_enabled_cluster_log_types"></a> [enabled\_cluster\_log\_types](#input\_enabled\_cluster\_log\_types) | EKS control plane log types to enable. | `list(string)` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator"<br/>]</pre> | no |
| <a name="input_endpoint_private_access"></a> [endpoint\_private\_access](#input\_endpoint\_private\_access) | Whether the Kubernetes API server endpoint is reachable from within the VPC. | `bool` | `true` | no |
| <a name="input_endpoint_public_access"></a> [endpoint\_public\_access](#input\_endpoint\_public\_access) | Whether the Kubernetes API server endpoint is reachable from the public internet. | `bool` | `false` | no |
| <a name="input_force_update_version"></a> [force\_update\_version](#input\_force\_update\_version) | Whether to force version updates when EKS cannot drain pods. | `bool` | `null` | no |
| <a name="input_ip_family"></a> [ip\_family](#input\_ip\_family) | Optional Kubernetes service IP family. Valid values are ipv4 or ipv6. | `string` | `null` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version for the EKS cluster. Leave null to use the current AWS default. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix for module-created resources. Used as the EKS cluster name when cluster\_name is null. | `string` | n/a | yes |
| <a name="input_pod_identity_associations"></a> [pod\_identity\_associations](#input\_pod\_identity\_associations) | EKS Pod Identity associations to create for Kubernetes service accounts. The module can create the IAM role per association, or use an externally managed role ARN. | <pre>map(object({<br/>    create_iam_role      = optional(bool, true)<br/>    disable_session_tags = optional(bool)<br/>    iam_policy_arns      = optional(set(string), [])<br/>    iam_role_arn         = optional(string)<br/>    iam_role_name        = optional(string)<br/>    inline_policy_json   = optional(string)<br/>    namespace            = string<br/>    service_account      = string<br/>    tags                 = optional(map(string), {})<br/>    target_role_arn      = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_public_access_cidrs"></a> [public\_access\_cidrs](#input\_public\_access\_cidrs) | CIDR blocks that can access the public Kubernetes API endpoint when endpoint\_public\_access is true. Leave empty when the public endpoint is disabled. | `list(string)` | `[]` | no |
| <a name="input_service_ipv4_cidr"></a> [service\_ipv4\_cidr](#input\_service\_ipv4\_cidr) | Optional Kubernetes service IPv4 CIDR. Set only when you need a non-default service CIDR. | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs for the EKS control plane and EKS Auto Mode managed compute. Use at least two subnets in different Availability Zones. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to created resources. | `map(string)` | `{}` | no |
| <a name="input_upgrade_policy_support_type"></a> [upgrade\_policy\_support\_type](#input\_upgrade\_policy\_support\_type) | Optional Kubernetes version support policy. Valid values are STANDARD and EXTENDED. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_entry_arns"></a> [access\_entry\_arns](#output\_access\_entry\_arns) | EKS access entry ARNs by access entry key. |
| <a name="output_argocd_idc_managed_application_arns"></a> [argocd\_idc\_managed\_application\_arns](#output\_argocd\_idc\_managed\_application\_arns) | IAM Identity Center managed application ARNs by ARGOCD capability key. |
| <a name="output_argocd_server_urls"></a> [argocd\_server\_urls](#output\_argocd\_server\_urls) | Managed Argo CD server URLs by ARGOCD capability key. |
| <a name="output_auto_mode_kubernetes_manifest_yaml"></a> [auto\_mode\_kubernetes\_manifest\_yaml](#output\_auto\_mode\_kubernetes\_manifest\_yaml) | All rendered EKS Auto Mode Kubernetes manifests joined into a single multi-document YAML string. |
| <a name="output_auto_mode_kubernetes_manifests"></a> [auto\_mode\_kubernetes\_manifests](#output\_auto\_mode\_kubernetes\_manifests) | All rendered EKS Auto Mode Kubernetes YAML manifests by kind/name. |
| <a name="output_auto_mode_load_balancer_service_manifests"></a> [auto\_mode\_load\_balancer\_service\_manifests](#output\_auto\_mode\_load\_balancer\_service\_manifests) | Rendered EKS Auto Mode LoadBalancer Service YAML manifests by name. |
| <a name="output_auto_mode_node_class_access_entry_arns"></a> [auto\_mode\_node\_class\_access\_entry\_arns](#output\_auto\_mode\_node\_class\_access\_entry\_arns) | EKS access entry ARNs created for custom Auto Mode NodeClass IAM roles. |
| <a name="output_auto_mode_node_class_manifests"></a> [auto\_mode\_node\_class\_manifests](#output\_auto\_mode\_node\_class\_manifests) | Rendered EKS Auto Mode NodeClass YAML manifests by name. |
| <a name="output_auto_mode_node_iam_role_arn"></a> [auto\_mode\_node\_iam\_role\_arn](#output\_auto\_mode\_node\_iam\_role\_arn) | IAM role ARN used by EKS Auto Mode managed compute when compute is enabled. |
| <a name="output_auto_mode_node_iam_role_name"></a> [auto\_mode\_node\_iam\_role\_name](#output\_auto\_mode\_node\_iam\_role\_name) | IAM role name used by EKS Auto Mode managed compute when compute is enabled. |
| <a name="output_auto_mode_node_pool_manifests"></a> [auto\_mode\_node\_pool\_manifests](#output\_auto\_mode\_node\_pool\_manifests) | Rendered EKS Auto Mode NodePool YAML manifests by name. |
| <a name="output_auto_mode_storage_class_manifests"></a> [auto\_mode\_storage\_class\_manifests](#output\_auto\_mode\_storage\_class\_manifests) | Rendered EKS Auto Mode StorageClass YAML manifests by name. |
| <a name="output_capability_arns"></a> [capability\_arns](#output\_capability\_arns) | Amazon EKS capability ARNs by capability key. |
| <a name="output_capability_iam_policy_preset_names"></a> [capability\_iam\_policy\_preset\_names](#output\_capability\_iam\_policy\_preset\_names) | Capability IAM policy preset names attached by capability key. |
| <a name="output_capability_iam_role_arns"></a> [capability\_iam\_role\_arns](#output\_capability\_iam\_role\_arns) | IAM role ARNs used by Amazon EKS capabilities by capability key. |
| <a name="output_capability_iam_role_names"></a> [capability\_iam\_role\_names](#output\_capability\_iam\_role\_names) | IAM role names used by Amazon EKS capabilities by capability key. |
| <a name="output_capability_names"></a> [capability\_names](#output\_capability\_names) | Amazon EKS capability names by capability key. |
| <a name="output_capability_versions"></a> [capability\_versions](#output\_capability\_versions) | Amazon EKS capability software versions by capability key. |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | EKS cluster ARN. |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64-encoded cluster certificate authority data. |
| <a name="output_cluster_created_at"></a> [cluster\_created\_at](#output\_cluster\_created\_at) | Timestamp when the EKS cluster was created. |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Kubernetes API server endpoint. |
| <a name="output_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#output\_cluster\_iam\_role\_arn) | IAM role ARN used by the EKS control plane. |
| <a name="output_cluster_log_group_name"></a> [cluster\_log\_group\_name](#output\_cluster\_log\_group\_name) | CloudWatch log group for EKS control plane logs, if cluster logs are enabled. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | EKS cluster name. |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | OIDC issuer URL for the EKS cluster. |
| <a name="output_cluster_platform_version"></a> [cluster\_platform\_version](#output\_cluster\_platform\_version) | EKS platform version. |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security group created by EKS for the cluster. |
| <a name="output_cluster_status"></a> [cluster\_status](#output\_cluster\_status) | EKS cluster status. |
| <a name="output_cluster_tags_all"></a> [cluster\_tags\_all](#output\_cluster\_tags\_all) | All tags applied to the EKS cluster, including provider default tags. |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | Kubernetes version running on the EKS cluster. |
| <a name="output_pod_identity_association_arns"></a> [pod\_identity\_association\_arns](#output\_pod\_identity\_association\_arns) | EKS Pod Identity association ARNs by association key. |
| <a name="output_pod_identity_association_ids"></a> [pod\_identity\_association\_ids](#output\_pod\_identity\_association\_ids) | EKS Pod Identity association IDs by association key. |
| <a name="output_pod_identity_external_ids"></a> [pod\_identity\_external\_ids](#output\_pod\_identity\_external\_ids) | External IDs generated for EKS Pod Identity associations by association key. |
| <a name="output_pod_identity_iam_role_arns"></a> [pod\_identity\_iam\_role\_arns](#output\_pod\_identity\_iam\_role\_arns) | IAM role ARNs used by EKS Pod Identity associations by association key. |
| <a name="output_pod_identity_iam_role_names"></a> [pod\_identity\_iam\_role\_names](#output\_pod\_identity\_iam\_role\_names) | IAM role names used by EKS Pod Identity associations by association key. |
| <a name="output_update_kubeconfig_command"></a> [update\_kubeconfig\_command](#output\_update\_kubeconfig\_command) | AWS CLI command to configure kubectl for this cluster. |
<!-- END_TF_DOCS -->

## Git Hooks

Enable the repository hooks after cloning or initializing Git:

```bash
git config core.hooksPath .githooks
```

The pre-commit hook checks Terraform formatting and verifies that generated Terraform docs in this README are up to date.

Regenerate the README module documentation manually with:

```bash
scripts/terraform-docs.sh
```

## Tests

Native Terraform tests live in `tests/` and use mocked AWS provider resources, so they can run without AWS credentials or creating infrastructure:

```bash
terraform test
```

Pull requests run the same tests through `.github/workflows/terraform-pr.yml`, along with formatting, generated-docs, validation, and example checks.

## Local Development

Use the Makefile for common local checks:

```bash
make fmt
make docs
make check
```

## Notes

- The module does not create VPC, subnet, route table, NAT gateway, or security baseline resources.
- The public Kubernetes API endpoint is disabled by default. If you enable it, use narrow `public_access_cidrs`.
- EKS Auto Mode manages compute from the selected built-in node pools; this module does not create managed node groups.
- Kubernetes manifests are rendered as Terraform outputs and are not applied by this module.
