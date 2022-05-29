# --- networking/outputs.tf ---

output "vpc_id" {
  value = aws_vpc.mtc_vpc.id
}

output "filebeat_sg" {
  value = aws_security_group.mtc_sg["filebeat"].id
}

output "logstash_sg" {
  value = aws_security_group.mtc_sg["logstash"].id
}

output "kibana_sg" {
  value = aws_security_group.mtc_sg["kibana"].id
}

output "elastic_sg" {
  value = aws_security_group.mtc_sg["elastic"].id
}

output "public_subnets" {
  value = aws_subnet.mtc_public_subnet.*.id
}