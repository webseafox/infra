project_name = "platform"
environment  = "staging"
aws_region   = "us-east-1"

cluster_version = "1.30"
vpc_cidr        = "10.40.0.0/16"
azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_count  = 3
private_subnet_count = 3
enable_nat_gateway   = true

node_instance_types = ["m5.large"]
node_desired_size   = 3
node_min_size       = 2
node_max_size       = 6

use_spot_nodes    = false
install_keda      = true
install_karpenter = true

tags = {
  Owner       = "platform-team"
  Environment = "staging"
}
