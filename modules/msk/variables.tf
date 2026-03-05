variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "kafka_version" {
  description = "Kafka version for MSK"
  type        = string
}

variable "instance_type" {
  description = "MSK broker instance type"
  type        = string
}

variable "number_of_broker_nodes" {
  description = "Number of broker nodes in MSK cluster"
  type        = number
}

variable "ebs_volume_size" {
  description = "EBS volume size for MSK brokers in GB"
  type        = number
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for MSK brokers"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for MSK"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}