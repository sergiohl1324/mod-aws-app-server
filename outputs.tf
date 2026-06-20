output "instance_id" {
  description = "ID de la instancia EC2 — usar con: aws ssm start-session --target <id>"
  value       = aws_instance.this.id
}

output "instance_public_ip" {
  description = "IP pública de la instancia"
  value       = aws_instance.this.public_ip
}

output "security_group_id" {
  description = "ID del Security Group de la instancia"
  value       = module.sg_app_server.this_security_group_id
}
