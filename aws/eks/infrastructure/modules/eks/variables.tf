variable "name" {
  description = "Project/environment name prefix."
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster Kubernetes version."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for EKS deployment."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for control plane and nodes."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for load balancers if needed."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Worker node EC2 instance types."
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired size of default managed node group."
  type        = number
}

variable "node_min_size" {
  description = "Minimum size of default managed node group."
  type        = number
}

variable "node_max_size" {
  description = "Maximum size of default managed node group."
  type        = number
}

variable "use_spot_nodes" {
  description = "Use spot capacity for managed node group."
  type        = bool
  default     = false
}

variable "install_karpenter" {
  description = "Create Karpenter support resources (IAM and SQS)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}
