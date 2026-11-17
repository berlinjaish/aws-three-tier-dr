
variable "project_name" {
  description = "Name of the AWS project"
  type        = string
  default     = "aws-three-tier-dr"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "dr_region" {
  description = "Disaster Recovery AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12 && length(var.db_password) <= 41
    error_message = "The RDS password must be between 12 and 41 characters."
  }
}
