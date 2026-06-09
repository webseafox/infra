variable "project_name" {
  description = "Project name used in resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
}

variable "aws_assume_role_arn" {
  description = "IAM Role ARN used by Terraform to access the target AWS account."
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "azs" {
  description = "Availability zones list."
  type        = list(string)
}

variable "public_subnet_count" {
  description = "Number of public subnets."
  type        = number
}

variable "private_subnet_count" {
  description = "Number of private subnets."
  type        = number
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnets."
  type        = bool
}

variable "node_instance_types" {
  description = "Worker node instance types."
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired nodes for managed node group."
  type        = number
}

variable "node_min_size" {
  description = "Minimum nodes for managed node group."
  type        = number
}

variable "node_max_size" {
  description = "Maximum nodes for managed node group."
  type        = number
}

variable "use_spot_nodes" {
  description = "Use spot capacity for nodes."
  type        = bool
}

variable "install_keda" {
  description = "Install KEDA in cluster."
  type        = bool
}

variable "install_karpenter" {
  description = "Install Karpenter in cluster."
  type        = bool
}

variable "tags" {
  description = "Extra resource tags."
  type        = map(string)
  default     = {}
}
