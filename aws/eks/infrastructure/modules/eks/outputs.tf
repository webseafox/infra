output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN used for IRSA."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "karpenter_irsa_role_arn" {
  description = "Karpenter IRSA role ARN when enabled."
  value       = try(aws_iam_role.karpenter_irsa[0].arn, null)
}

output "karpenter_interruption_queue_name" {
  description = "SQS queue name used by Karpenter interruption handling."
  value       = try(aws_sqs_queue.karpenter[0].name, null)
}
