# AWS EKS Terraform Project

This project provisions AWS infrastructure for EKS using reusable Terraform modules.

## Structure

- `infrastructure/modules/vpc`: VPC, subnets, route tables, NAT gateway.
- `infrastructure/modules/eks`: EKS control plane, managed nodes, and Karpenter support resources (IAM/SQS).
- `infrastructure/environments/{dev,staging,prod}`: Environment-specific root modules and tfvars.
- `infrastructure/shared/backend.tf`: Shared backend example (not used by environment roots).

## Key Features

- EKS control plane and managed node group.
- Spot or on-demand worker node capacity (`use_spot_nodes`).
- Customizable node instance types (`node_instance_types`).
- Configurable number of public/private subnets.
- Optional KEDA and Karpenter installation by Helm in each environment root module.
- AWS provider access by IAM Role ARN (`assume_role`).

## Usage

From an environment directory (example: dev):

```bash
cd infrastructure/environments/dev
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## IAM Access (Assume Role ARN)

Each environment uses:

- `aws_assume_role_arn` in `terraform.tfvars`
- `assume_role` inside the AWS provider in `main.tf`

Example value:

```hcl
aws_assume_role_arn = "arn:aws:iam::123456789012:role/TerraformDeployRole"
```

Your caller identity must be allowed in the role trust policy.

## Notes

- Configure AWS credentials before running Terraform.
- Review production values in `terraform.tfvars` before applying.
- Karpenter IAM policy in this template is broad for bootstrap and should be restricted for hardened environments.

## Remote State (S3)

Each environment uses its own state key in S3:

- dev: `aws/eks/dev/terraform.tfstate`
- staging: `aws/eks/staging/terraform.tfstate`
- prod: `aws/eks/prod/terraform.tfstate`

Update backend values in each environment `main.tf`:

- `bucket = "CHANGE_ME_TFSTATE_BUCKET"`
- `dynamodb_table = "CHANGE_ME_TF_LOCKS_TABLE"`
- `region = "us-east-1"` (adjust if needed)

After changing backend settings, reconfigure backend in each environment:

```bash
terraform init -reconfigure
```

If Terraform detects an existing local state, migrate it:

```bash
terraform init -migrate-state
```

Recommended sequence per environment:

```bash
cd infrastructure/environments/dev
terraform init -reconfigure
terraform plan -var-file=terraform.tfvars
```
