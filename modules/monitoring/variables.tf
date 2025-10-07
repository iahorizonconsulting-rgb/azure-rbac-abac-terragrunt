variable "log_analytics_name" {
  type = string
}

variable "app_insights_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "enable_alerting" {
  type    = bool
  default = true
}

variable "alert_email" {
  type    = string
  default = "security@company.com"
}

variable "tags" {
  type    = map(string)
  default = {}
}
