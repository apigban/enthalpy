variable "cloud_api_token" {
  description = "API token from cloud provider"
  type        = string
  sensitive   = true
}

variable "user_information" {
  type = object({
    name    = string
    gecos   = string
    primary_group = string
    passwd  = string
  })
  sensitive = true
}

variable "server_information" {
  type = object({
    name = string
  })
}

variable "network_information" {
  type = object({
    name = string
    cidr = string
  })
}