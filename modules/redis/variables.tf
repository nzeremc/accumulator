variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
}

variable "node_type" {
  description = "ElastiCache Redis node type"
  type        = string
}

variable "num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
}

variable "parameter_group_family" {
  description = "Redis parameter group family"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Redis"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for Redis"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}