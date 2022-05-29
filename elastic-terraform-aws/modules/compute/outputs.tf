output "instance" {
  value     = aws_instance.elastic_nodes[*]
  sensitive = true
}