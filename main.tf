### SECURITY GROUP — APP SERVER ###

module "sg_app_server" {
  source = "git::https://github.com/sergiohl1324/mod-aws-security-group.git?ref=main"

  name        = "${var.project}-sg-app-server"
  description = "Allows HTTP traffic only from the ALB Security Group"
  vpc_id      = var.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "HTTP from the ALB"
      source_security_group_id = var.alb_security_group_id
    }
  ]

  egress_rules = ["all-all"]

  project     = var.project
  environment = var.environment
  tags        = var.tags
}

### IAM ROLE — SSM ACCESS (no SSH) ###

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
  vpc_security_group_ids      = [module.sg_app_server.this_security_group_id]
  iam_instance_profile        = module.iam_role.instance_profile_name

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    title        = var.html_title
    message      = var.html_message
    enable_uwsgi = var.enable_uwsgi
  })
  # AWS provider default is a stop/start in place, which does NOT re-run
  # cloud-init's user_data on an existing instance — force a real replacement
  # instead, so user_data changes (and the enable_uwsgi toggle) actually take effect.
  user_data_replace_on_change = true

  # IMDSv2 required (SSRF/credential theft protection)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.common_tags, { Name = "${var.project}-app-server" })

  # Note: user_data changes are intentionally NOT ignored (unlike the typical
  # EC2 module pattern) — the enable_uwsgi toggle relies on a user_data change
  # forcing the instance to be replaced.
  lifecycle {
    ignore_changes = [ami]
  }
}

### ALB TARGET GROUP REGISTRATION ###

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.this.id
  port             = 80
}
