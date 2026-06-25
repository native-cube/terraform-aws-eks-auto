# Codex Instructions

These instructions apply to the whole Terraform EKS Auto Mode module.

## Module Scope

- Keep this as a reusable EKS Auto Mode module, not a full environment stack.
- Do not create VPCs, subnets, NAT gateways, route tables, or AWS provider configuration in the root module. Examples may configure providers.
- Accept existing network inputs such as `subnet_ids` and expose outputs useful for composition with other modules.
- Preserve backward compatibility for existing variables and outputs unless the user explicitly asks for a breaking change.

## Terraform Style

- Run `terraform fmt -recursive` after editing Terraform files.
- Keep root module files split by concern:
  - `versions.tf` for Terraform and provider constraints.
  - `variables.tf` for inputs and validation.
  - `locals.tf` for derived names, tags, and constants.
  - `iam.tf` for IAM roles, policies, and attachments.
  - `logs.tf` for CloudWatch log resources.
  - `main.tf` for the EKS Auto Mode cluster, access entries, and capabilities.
  - `outputs.tf` for module outputs.
- Keep all variables and outputs documented with clear descriptions.
- Add validation blocks for inputs with constrained values or important shape requirements.
- Prefer `for_each` with stable map keys for repeatable resources. Use `count` only for simple optional singleton resources.
- Use `data.aws_partition.current.partition` for AWS-managed policy ARNs instead of hard-coding `aws`.
- Use `local.common_tags` for created AWS resources unless there is a specific reason not to.
- Avoid hard-coded AWS regions, accounts, profiles, credentials, ARNs, subnet IDs, or cluster names in the reusable module.

## EKS Auto Mode Practices

- Keep the control plane IAM role and Auto Mode node IAM role separate.
- Keep IAM permissions minimal, using AWS-managed EKS Auto Mode policies and caller-supplied capability policies only when needed.
- Do not create managed node groups, self-managed nodes, Karpenter resources, Kubernetes providers, Helm releases, or in-cluster resources in this module.
- Default to EKS access entries by using API authentication.
- Preserve control-plane log retention when cluster logging is enabled.
- Keep the Kubernetes API endpoint private by default. Only enable public endpoint access explicitly, and prefer narrow `public_access_cidrs`.

## Examples And Docs

- Keep all usage examples of the module under `examples/` that consume this module from `../..`.
- Update the README when adding, removing, or changing user-facing variables, outputs, examples, or behavior.
- Do not commit real `terraform.tfvars`, state files, credentials, generated plans, or local `.terraform/` directories.

## Verification

For root module changes, run:

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform test
```

You can also run the local aggregate target:

```bash
make check
```

For example changes, also run the same init and validate commands from the touched example directory.

Do not run `terraform apply`, `terraform destroy`, or destructive state commands unless the user explicitly asks for them and confirms the target environment.
