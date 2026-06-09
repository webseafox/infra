# AWS EKS Terraform Project

This project provisions AWS infrastructure for EKS using reusable Terraform modules.

## Structure

- `infrastructure/modules/vpc`: VPC, subnets, route tables, NAT gateway.
- `infrastructure/modules/eks`: EKS control plane, managed nodes, KEDA and Karpenter.
- `infrastructure/environments/{dev,staging,prod}`: Environment-specific root modules and tfvars.
- `infrastructure/shared/backend.tf`: Shared backend configuration.

## Key Features

- EKS control plane and managed node group.
- Spot or on-demand worker node capacity (`use_spot_nodes`).
- Customizable node instance types (`node_instance_types`).
- Configurable number of public/private subnets.
- Optional KEDA and Karpenter installation by Helm.

## Usage

From an environment directory (example: dev):

```bash
cd infrastructure/environments/dev
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Notes

- Configure AWS credentials before running Terraform.
- Review production values in `terraform.tfvars` before applying.
- Karpenter IAM policy in this template is broad for bootstrap and should be restricted for hardened environments.
