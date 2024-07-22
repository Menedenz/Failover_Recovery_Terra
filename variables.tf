variable "project" {
  description = "Project name"
  type = string
  default = "hotStandby"
}
variable "env" {
  description = "Environment name"
  type = string
  default = "dev"
}




# Region variables
variable "aws_region" {
  description = "Region"
  type        = string
  default     = "us-east-1"
}

# VPC variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "VPC-hotStandby"
}

# Subnet variables
variable "subnet_a_cidr" {
  description = "CIDR block for subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_b_cidr" {
  description = "CIDR block for subnet B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone_a" {
  description = "Availability zone for subnet A"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  description = "Availability zone for subnet B"
  type        = string
  default     = "us-east-1b"
}

variable "subnet_a_name" {
  description = "Name tag for subnet A"
  type        = string
  default     = "Subnet-1a"
}

variable "subnet_b_name" {
  description = "Name tag for subnet B"
  type        = string
  default     = "Subnet-1b"
}

# Internet Gateway variables
variable "igw_name" {
  description = "Name tag for the Internet Gateway"
  type        = string
  default     = "IGW-HotStandby"
}

# Route Table variables
variable "route_table_name" {
  description = "Name tag for the Route Table"
  type        = string
  default     = "RouteTable-HotStandby"
}

# Security Group variables
variable "security_group_name_ec2" {
  description = "Name tag for the Security Group"
  type        = string
  default     = "EC2-SG"
}

variable "security_group_name_alb" {
  description = "Name tag for the Security Group"
  type        = string
  default     = "ALB-SG"
}


# EC2

variable "active_ec2_name" {
  description = "name of the active EC2 instance"
  type        = string
  default     = "Active_EC2"
}
variable "passive_ec2_name" {
  description = "name of the passive EC2 instance"
  type        = string
  default     = "Passive_EC2"
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "public_key_name" {
  description = "Name of the SSH public key"
  type        = string
}

variable "certificate_content" {
  description = "Path to the certificate .pem file"
  type        = string
}

variable "private_key_content" {
  description = "Path to the Private key . pem file"
  type        = string
}

variable "cert_file" {
  default = "./self_signed_certificate.pem"
}

variable "key_file" {
  default = "./private_key.pem"
}

variable "apache_log_dir" {
  default = "/var/log/apache2"
}

# Target groups
variable "active_tg_name" {
  description = "name of the active target group"
  type        = string
  default     = "Active_TG"
}
variable "passive_tg_name" {
  description = "name of the passive target group"
  type        = string
  default     = "Passive_TG"
}
variable "alb_name" {
  description = "name of the appliaction load balancer"
  type        = string
  default     = "Alb_Active_Passive_terraform"
}

variable "certificate_arn" {
  description = "arn of the certificate form ACM"
  type        = string
}

# Lambda function

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "FailoverRecover"
}

variable "lambda_handler" {
  description = "Handler for the Lambda function"
  type        = string
  default     = "FailoverALBTG.handler"
}

variable "lambda_runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.12"
}

variable "event_rule_name" {
  description = "Name of the event rule"
  type        = string
  default     = "ActiveIISRecoveryEvent"
}


variable "operation" {
  description = "Operation type"
  type        = string
  default     = "recovery"
}

