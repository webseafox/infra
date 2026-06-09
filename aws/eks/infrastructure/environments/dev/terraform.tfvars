project_name = "platform"
environment  = "dev"
aws_region   = "us-east-1"

cluster_version = "1.30"
vpc_cidr        = "10.30.0.0/16"
azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_count  = 3
private_subnet_count = 3
enable_nat_gateway   = true

node_instance_types = ["t3.large"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 4

use_spot_nodes    = true
install_keda      = true
install_karpenter = true

tags = {
  Owner       = "platform-team"
  Environment = "dev"
}
