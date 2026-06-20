output "instance_id" {
  description = "EC2 instance ID — use with: aws ssm start-session --target <id>"
  value       = aws_instance.this.id
}

output "instance_public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.this.public_ip
}

output "security_group_id" {
  description = "ID of the instance's Security Group"
  value       = module.sg_app_server.this_security_group_id
}
