### VARIABLES GLOBALES ###

variable "project" {
  description = "Nombre del proyecto (naming/tagging)"
  type        = string
  default     = "poc"
}

variable "environment" {
  description = "Ambiente lógico (ej. nonproduction, production) usado para tagging"
  type        = string
  default     = "nonproduction"
}

variable "tags" {
  description = "Tags adicionales que se fusionan con los tags por defecto"
  type        = map(string)
  default     = {}
}

### VARIABLES EC2 ###

variable "ami" {
  description = "AMI a usar. Recomendado: Ubuntu 22.04/24.04 LTS — apt-get install build-essential/python3-dev/python3-venv es el combo más estable para compilar uWSGI vía pip."
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "ID de la VPC donde se crea el Security Group de la instancia"
  type        = string
}

variable "subnet_id" {
  description = "Subnet (pública) donde se lanza la instancia"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security Group del ALB — se permite ingress :80 únicamente desde este SG"
  type        = string
}

variable "target_group_arn" {
  description = "ARN del Target Group del ALB donde se registra la instancia"
  type        = string
}

### TOGGLE BONUS — uWSGI ###

variable "enable_uwsgi" {
  description = "Si false, nginx sirve el HTML estático directo. Si true, además se compila/instala uWSGI, se despliega una mini app WSGI, y nginx hace reverse proxy hacia uWSGI vía unix socket."
  type        = bool
  default     = false
}

### CONTENIDO HTML DE PRUEBA ###

variable "html_title" {
  description = "Título de la página HTML de prueba"
  type        = string
  default     = "POC AWS — Sergio Hernández"
}

variable "html_message" {
  description = "Mensaje de la página HTML de prueba"
  type        = string
  default     = "Infraestructura desplegada con Terraform: VPC + ALB + EC2"
}
