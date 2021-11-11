variable "region" {
  type    = string
  default = "us-east-1"
}

variable "owner" {
  type = string
}

variable "ami_id" {
  type        = string
  description = "Free tier AMI id to use"
}

variable "my_ip_address" {
  type        = string
  description = "My local IP to prevent unrestricted access to internet facing resources"
}

variable "public_key" {
  type        = string
  description = "Public key of the key pair"
}
