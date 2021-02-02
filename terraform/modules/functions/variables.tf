variable "name" {
  description = "Name of the module"
  type        = string
}

variable "entry_point" {
  description = "Name of the entry_point to run"
  type        = string
}

variable "bucket" {
  description = "The export bucket"
  type        = string
}

variable "service_account_email" {
  type = string
}

variable "schedule" {
  description = "schedule"
  type        = string
  default     = "0 */1 * * *"
}

variable "available_memory_mb" {
  type    = number
  default = 128
}

variable "timeout" {
  type    = number
  default = 60
}

variable "app_engine_region" {
  type    = string
  default = "us-west2"
}

