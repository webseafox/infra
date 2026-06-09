variable "name" {
  description = "Project/environment name prefix."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
}

variable "public_subnet_count" {
  description = "Number of public subnets to create."
  type        = number
}

variable "private_subnet_count" {
  description = "Number of private subnets to create."
  type        = number
}

variable "enable_nat_gateway" {
  description = "Create one NAT gateway for private subnet egress."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
