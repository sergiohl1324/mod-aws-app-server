### GLOBAL VARIABLES ###

variable "project" {
  description = "Project name (naming/tagging)"
  type        = string
  default     = "poc"
}

variable "environment" {
  description = "Logical environment (e.g. nonproduction, production) used for tagging"
  type        = string
  default     = "nonproduction"
}

variable "tags" {
  description = "Additional tags merged with the default tags"
  type        = map(string)
  default     = {}
}

### EC2 VARIABLES ###

variable "ami" {
  description = "AMI to use. Recommended: Ubuntu 22.04/24.04 LTS — apt-get install build-essential/python3-dev/python3-venv is the most stable combo to compile uWSGI via pip."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "ID of the VPC where the instance's Security Group is created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet (public) where the instance is launched"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB Security Group — ingress on :80 is only allowed from this SG"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB Target Group the instance is registered to"
  type        = string
}

### BONUS TOGGLE — uWSGI ###

variable "enable_uwsgi" {
  description = "If false, nginx serves the static HTML directly. If true, it also compiles/installs uWSGI, deploys a minimal WSGI app, and nginx reverse-proxies to uWSGI via a unix socket."
  type        = bool
  default     = false
}

### TEST HTML CONTENT ###

variable "html_title" {
  description = "Title of the test HTML page"
  type        = string
  default     = "POC AWS — Sergio Hernandez"
}

variable "html_message" {
  description = "Message shown on the test HTML page"
  type        = string
  default     = "Infrastructure deployed with Terraform: VPC + ALB + EC2"
}
