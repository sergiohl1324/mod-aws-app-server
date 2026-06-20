# mod-aws-app-server

Módulo Terraform para el "Application Server" de la POC: EC2 + Security Group (vía [mod-aws-security-group](https://github.com/sergiohl1324/mod-aws-security-group), ingress solo desde el SG del ALB) + IAM Role/Instance Profile con SSM (sin SSH, vía [mod-aws-iam-role](https://github.com/sergiohl1324/mod-aws-iam-role)) + registro en un Target Group de ALB.

El `user_data` (`templates/user_data.sh.tpl`) instala nginx y sirve un HTML simple. Con el toggle `enable_uwsgi = true`, además compila/instala uWSGI (vía pip, requiere `build-essential`/`python3-dev`), despliega una mini app WSGI, y reconfigura nginx como reverse proxy hacia uWSGI por unix socket.

> **Nota:** este módulo depende de `mod-aws-security-group` y `mod-aws-iam-role` como módulos hijos (referenciados por `git::...?ref=main`). Para que `terraform init` funcione desde cualquier máquina, ambos repos deben ser públicos.

## AMI recomendada

**Ubuntu 22.04/24.04 LTS.** El script usa `apt-get`. Amazon Linux 2023 (dnf) también podría funcionar pero tiene más fricción histórica compilando extensiones C de Python (PEP 668 / headers de `python3-devel`).

## Gotcha importante: `lifecycle.ignore_changes`

A diferencia de la mayoría de módulos EC2 reutilizables (que suelen ignorar cambios en `user_data` para evitar recrear la instancia), **este módulo NO ignora `user_data`** — solo ignora `ami`. Esto es intencional: cambiar `enable_uwsgi` cambia el `user_data` renderizado, y Terraform necesita reemplazar la instancia (`# forces replacement`) para que el cambio tome efecto.

## Uso

```hcl
module "app_server" {
  source = "git::https://github.com/sergiohl1324/mod-aws-app-server.git?ref=main"

  project                = "poc"
  ami                    = "ami-xxxxxxxx" # Ubuntu 22.04/24.04 LTS de la región
  vpc_id                 = module.vpc.vpc_id
  subnet_id              = module.vpc.public_subnets[0]
  alb_security_group_id  = module.sg_alb.this_security_group_id
  target_group_arn       = module.alb.target_group_arns["web"]
  enable_uwsgi           = false
}
```

## Debug

Sin SSH abierto — usar SSM Session Manager:

```bash
aws ssm start-session --target <instance_id>
cat /var/log/user-data.log
journalctl -u uwsgi
```

## Outputs

`instance_id`, `instance_public_ip`, `security_group_id`.
