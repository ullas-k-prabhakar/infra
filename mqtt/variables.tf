variable "mqtt_username" {
  description = "MQTT broker username"
  type        = string
}

variable "mqtt_password" {
  description = "MQTT broker password"
  type        = string
}

variable "vm_server_type" {
  description = "Instance Type, CAREFULL COST INVOLES"
  type        = string
  default     = "f1-micro"
}

variable "duck_domain_name" {
  description = "Duck Domain name"
  type        = string
}

variable "duck_token" {
  description = "Duck domain token"
  type        = string
}