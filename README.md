# mod-aws-app-server

Terraform module for the POC's "Application Server": EC2 + Security Group (via [mod-aws-security-group](https://github.com/sergiohl1324/mod-aws-security-group), ingress only from the ALB's SG) + IAM Role/Instance Profile with SSM (no SSH, via [mod-aws-iam-role](https://github.com/sergiohl1324/mod-aws-iam-role)) + registration in an ALB Target Group.

The `user_data` (`templates/user_data.sh.tpl`) installs nginx and serves a simple HTML page. With the `enable_uwsgi = true` toggle, it also compiles/installs uWSGI (via pip, requires `build-essential`/`python3-dev`), deploys a minimal WSGI app, and reconfigures nginx as a reverse proxy to uWSGI over a unix socket.

> **Note:** this module depends on `mod-aws-security-group` and `mod-aws-iam-role` as child modules (referenced via `git::...?ref=main`). For `terraform init` to work from any machine, both repos must be public.

## Recommended AMI

**Ubuntu 22.04/24.04 LTS.** The script uses `apt-get`. Amazon Linux 2023 (dnf) might also work but has more historical friction compiling Python C extensions (PEP 668 / `python3-devel` headers).

## Important gotcha: `lifecycle.ignore_changes`

Unlike most reusable EC2 modules (which usually ignore `user_data` changes to avoid recreating the instance), **this module does NOT ignore `user_data`** — only `ami` is ignored. This is intentional: changing `enable_uwsgi` changes the rendered `user_data`, and Terraform needs to replace the instance (`# forces replacement`) for the change to take effect.

## Usage

```hcl
module "app_server" {
  source = "git::https://github.com/sergiohl1324/mod-aws-app-server.git?ref=main"

  project                = "poc"
  ami                    = "ami-xxxxxxxx" # Ubuntu 22.04/24.04 LTS for the region
  vpc_id                 = module.vpc.vpc_id
  subnet_id              = module.vpc.public_subnets[0]
  alb_security_group_id  = module.sg_alb.this_security_group_id
  target_group_arn       = module.alb.target_group_arns["web"]
  enable_uwsgi           = false
}
```

## Debug

No SSH exposed — use SSM Session Manager:

```bash
aws ssm start-session --target <instance_id>
cat /var/log/user-data.log
journalctl -u uwsgi
```

## Outputs

`instance_id`, `instance_public_ip`, `security_group_id`.
