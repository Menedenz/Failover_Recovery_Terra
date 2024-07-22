output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_a_id" {
  description = "The ID of subnet A"
  value       = aws_subnet.subnet_a.id
}

output "subnet_b_id" {
  description = "The ID of subnet B"
  value       = aws_subnet.subnet_b.id
}

# isntance outputs
output "instance_id_active" {
  description = "The ID of the active EC2 instance"
  value       = aws_instance.active_EC2.id
}

output "instance_public_ip_active" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.active_EC2.public_ip
}

output "instance_id_passive" {
  description = "The ID of the passive EC2 instance"
  value       = aws_instance.passive_EC2.id
}

output "instance_public_ip_passive" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.passive_EC2.public_ip
}

output "ALB_DNS_Name" {
  description = "DNS Name of the ALB"
  value       = aws_lb.alb_active_passive.dns_name
}