variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for scripts and data"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the database secret in Secrets Manager"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Variables for Federated Role (OIDC Provider)
variable "oidc_provider_arn" {
  description = "ARN of the OIDC identity provider (e.g., arn:aws:iam::123456789012:oidc-provider/oidc.eks.region.amazonaws.com/id/XXXXX)"
  type        = string
  default     = ""
}

variable "oidc_provider_name" {
  description = "Name/URL of the OIDC provider (e.g., oidc.eks.us-east-1.amazonaws.com/id/XXXXX)"
  type        = string
  default     = ""
}