# --- compute/variables.tf ---

variable "instance_count" {}
variable "instance_type_elastic" {}
variable "instance_type_others" {}
variable "elastic_sg" {}
variable "kibana_sg" {}
variable "logstash_sg" {}
variable "filebeat_sg" {}
variable "public_subnets" {}
variable "vol_size" {}
variable "public_key_path" {}
variable "key_name" {}
variable "lb_target_group_arn1" {}
variable "lb_target_group_arn2" {}
variable "private_key_path" {}
variable "tg_port1" {}
variable "tg_port2" {}
variable "load_balancer_endpoint" {}