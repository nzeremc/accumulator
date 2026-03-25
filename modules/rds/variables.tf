variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
}

variable "master_username" {
  description = "Master username for RDS"
  type        = string
  sensitive   = true
}

variable "master_password" {
  description = "Master password for RDS (leave empty to auto-generate)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "backup_retention_period" {
  description = "Backup retention period in days (0 for free tier, 1-35 for production)"
  type        = number
  default     = 0
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = true
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for DB subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "s3_bucket_name" {
  description = "S3 bucket name for storing SQL scripts"
  type        = string
}