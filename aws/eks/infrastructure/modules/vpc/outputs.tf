output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = [for s in values(aws_subnet.public) : s.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = [for s in values(aws_subnet.private) : s.id]
}
