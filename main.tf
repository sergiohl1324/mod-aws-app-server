### SECURITY GROUP — APP SERVER ###

resource "aws_security_group" "app_server" {
  name        = "${var.project}-sg-app-server"
  description = "Permite trafico HTTP solo desde el Security Group del ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP desde el ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "Salida a internet (apt/pip, agente SSM)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project}-sg-app-server" })
}

### IAM ROLE — ACCESO SSM (sin SSH) ###

module "iam_role" {
  source = "git::https://github.com/sergiohl1324/mod-aws-iam-role.git?ref=main"

  project  = var.project
  role_use = "app-server-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  create_instance_profile = true
  managed_policy_arns     = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  tags = var.tags
}

### EC2 — APPLICATION SERVER ###

resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app_server.id]
  iam_instance_profile        = module.iam_role.instance_profile_name

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    title        = var.html_title
    message      = var.html_message
    enable_uwsgi = var.enable_uwsgi
  })

  # IMDSv2 obligatorio (protección SSRF/credential theft)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 10
    volume_type            = "gp3"
    encrypted              = true
    delete_on_termination  = true
  }

  tags = merge(local.common_tags, { Name = "${var.project}-app-server" })

  # Nota: a propósito NO se ignoran cambios en user_data (a diferencia del
  # patrón típico de módulos EC2) — el toggle enable_uwsgi depende de que
  # un cambio en user_data fuerce el reemplazo de la instancia.
  lifecycle {
    ignore_changes = [ami]
  }
}

### REGISTRO EN EL TARGET GROUP DEL ALB ###

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = var.target_group_arn
  target_id         = aws_instance.this.id
  port              = 80
}
