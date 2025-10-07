variable "app_name" {
  type = string
}

variable "groups" {
  type = map(object({
    description = string
    role        = string
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
