variable "aws_region" {
  default = "us-east-1"
}

variable "access_ip" {}

variable "zone_id" {
  type        = string
  default     = "Z0316813CHGSR83NJNTD"
  description = "Route53 hosted zone ids"
}

variable "domain_name" {
  default = "mehmetafsar.net"
}

variable "cname" {
  default = "terraform"
}

variable "availability" {
  default = "us-east-1e"
  description = "t3a.large can not be used in us-east-1e"
}