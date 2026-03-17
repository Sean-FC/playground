# Avoid the management costs of EKS (~$100 per month not including node runtime)
locals {
  k3s_cluster_name       = "core"
  k3s_architecture       = "arm64"
  k3s_server_volume_size = 20
  k3s_agent_volume_size  = 20
  k3s_state_volume_size  = 20
  k3s_server_subnet_id   = module.main_subnets.public_subnet_ids[0]
  k3s_server_name        = join(module.context.delimiter, [module.context.id, local.k3s_cluster_name, "server"])
  k3s_agent_name         = join(module.context.delimiter, [module.context.id, local.k3s_cluster_name, "agent"])
  k3s_state_volume_name  = join(module.context.delimiter, [module.context.id, local.k3s_cluster_name, "state"])
  k3s_api_fqdn           = "${local.k3s_cluster_name}.${aws_route53_zone.stage.name}"
  k3s_server_private_ip  = cidrhost(data.aws_subnet.k3s_server.cidr_block, 10)
  k3s_arch_to_ami = {
    arm64  = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
    x86_64 = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  }
  k3s_compute_private_subnet_ids = [
    for subnet in module.main_subnets.named_private_subnets_stats_map["compute"] : subnet.subnet_id
  ]
}

data "aws_ssm_parameter" "al2023_ami" {
  count = var.k3s_enabled ? 1 : 0
  name  = local.k3s_arch_to_ami[local.k3s_architecture]
}

data "aws_subnet" "k3s_server" {
  id = local.k3s_server_subnet_id
}

resource "aws_iam_role" "k3s_node" {
  count = var.k3s_enabled ? 1 : 0
  name  = join(module.context.delimiter, [module.context.id, local.k3s_cluster_name, "node"])

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "k3s_node_ssm" {
  count      = var.k3s_enabled ? 1 : 0
  role       = aws_iam_role.k3s_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "k3s_node" {
  count = var.k3s_enabled ? 1 : 0
  name  = join(module.context.delimiter, [module.context.id, local.k3s_cluster_name, "node"])
  role  = aws_iam_role.k3s_node[0].name
}

resource "aws_key_pair" "k3s" {
  count      = var.k3s_enabled ? 1 : 0
  key_name   = join(module.context.delimiter, [module.context.id, local.k3s_cluster_name])
  public_key = local.secrets_main.k3s.pub_key

  tags = merge(
    module.context.tags,
    { Name = join(module.context.delimiter, [module.context.id, local.k3s_cluster_name]) }
  )
}

resource "aws_ebs_volume" "k3s_state" {
  availability_zone = data.aws_subnet.k3s_server.availability_zone
  size              = local.k3s_state_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(
    module.context.tags,
    {
      Name = local.k3s_state_volume_name
      Role = "k3s-state"
    }
  )
}

resource "aws_security_group" "k3s" {
  count       = var.k3s_enabled ? 1 : 0
  vpc_id      = aws_vpc.main.id
  name        = join(module.context.delimiter, [module.context.id, local.k3s_cluster_name])
  description = "k3s cluster traffic"

  ingress {
    description = "k3s API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["${local.secrets_main.personal.ip}/32"]
  }

  ingress {
    description = "k3s HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${local.secrets_main.personal.ip}/32"]
  }

  ingress {
    description = "k3s HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${local.secrets_main.personal.ip}/32"]
  }

  ingress {
    description = "intra-cluster"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = join(module.context.delimiter, [module.context.id, local.k3s_cluster_name])
  }
}

resource "aws_instance" "k3s_server" {
  count                       = var.k3s_enabled ? 1 : 0
  ami                         = nonsensitive(data.aws_ssm_parameter.al2023_ami[0].value)
  instance_type               = var.k3s_server_instance_type
  key_name                    = aws_key_pair.k3s[0].key_name
  subnet_id                   = local.k3s_server_subnet_id
  private_ip                  = local.k3s_server_private_ip
  vpc_security_group_ids      = [aws_security_group.k3s[0].id, aws_security_group.default_ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.k3s_node[0].name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size           = local.k3s_server_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/templates/k3s-server-user-data.tftpl", {
    api_endpoint               = local.k3s_api_fqdn
    env                        = module.context.stage
    k3s_version                = var.k3s_version
    node_name                  = local.k3s_server_name
    oidc_issuer_url            = "https://s3.${data.aws_region.current.region}.amazonaws.com/${aws_s3_bucket.k3s_oidc.bucket}"
    sa_signer_private_key_pem  = local.secrets_main.k3s.sa_signer_private_key_pem
    sa_signer_public_key_pkcs8 = local.secrets_main.k3s.sa_signer_public_key_pkcs8
    state_device               = "/dev/sdf"
    token                      = local.secrets_main.k3s.token
  })

  tags = merge(
    module.context.tags,
    {
      Name = local.k3s_server_name
      Role = "k3s-server"
    }
  )
}

resource "aws_iam_role_policy_attachment" "k3s_kms_decrypt" {
  count      = var.k3s_enabled ? 1 : 0
  role       = aws_iam_role.k3s_node[0].name
  policy_arn = data.terraform_remote_state.bootstrap.outputs.default_secrets_kms_decrypt
}

resource "aws_volume_attachment" "k3s_state" {
  count       = var.k3s_enabled ? 1 : 0
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.k3s_state.id
  instance_id = aws_instance.k3s_server[0].id

  force_detach = true
}

resource "aws_eip" "k3s_server" {
  count    = var.k3s_enabled ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.k3s_server[0].id

  tags = merge(
    module.context.tags,
    { Name = join(module.context.delimiter, [module.context.id, local.k3s_cluster_name, "eip"]) }
  )
}

resource "aws_route53_record" "k3s_api" {
  count   = var.k3s_enabled ? 1 : 0
  zone_id = aws_route53_zone.stage.zone_id
  name    = local.k3s_api_fqdn
  type    = "A"
  ttl     = 300
  records = [aws_eip.k3s_server[0].public_ip]
}

resource "aws_instance" "k3s_agent" {
  count                  = var.k3s_enabled ? var.k3s_agent_count : 0
  ami                    = nonsensitive(data.aws_ssm_parameter.al2023_ami[0].value)
  instance_type          = var.k3s_agent_instance_type
  key_name               = aws_key_pair.k3s[0].key_name
  subnet_id              = local.k3s_compute_private_subnet_ids[count.index % length(local.k3s_compute_private_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.k3s[0].id, aws_security_group.default_ssh.id]
  iam_instance_profile   = aws_iam_instance_profile.k3s_node[0].name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size           = local.k3s_agent_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/templates/k3s-agent-user-data.tftpl", {
    env         = module.context.stage
    k3s_version = var.k3s_version
    node_name   = format("%s-%02d", local.k3s_agent_name, count.index + 1)
    server_url  = "https://${local.k3s_server_private_ip}:6443"
    token       = local.secrets_main.k3s.token
  })

  tags = merge(
    module.context.tags,
    {
      Name = format("%s-%02d", local.k3s_agent_name, count.index + 1)
      Role = "k3s-agent"
    }
  )
}

# OIDC bucket
resource "aws_s3_bucket" "k3s_oidc" {
  bucket        = join(module.context.delimiter, ["seanfc", module.context.id, "k3s", "oidc"])
  force_destroy = true
  tags          = module.context.tags
}

resource "aws_s3_bucket_public_access_block" "k3s_oidc" {
  bucket                  = aws_s3_bucket.k3s_oidc.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "k3s_oidc" {
  bucket = aws_s3_bucket.k3s_oidc.id
  versioning_configuration {
    status = "Disabled"
  }
}

data "aws_iam_policy_document" "k3s_oidc_public_read" {
  statement {
    sid    = "AllowPublicReadOfOidcObjects"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.k3s_oidc.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "k3s_oidc_public_read" {
  bucket = aws_s3_bucket.k3s_oidc.id
  policy = data.aws_iam_policy_document.k3s_oidc_public_read.json
}

resource "aws_s3_object" "k3s_oidc_discovery" {
  bucket = aws_s3_bucket.k3s_oidc.id
  key    = ".well-known/openid-configuration"
  content = templatefile("${path.module}/templates/k3s-oidc-discovery.json.tftpl", {
    issuer_url = "https://s3.${data.aws_region.current.region}.amazonaws.com/${aws_s3_bucket.k3s_oidc.bucket}"
    jwks_uri   = "https://s3.${data.aws_region.current.region}.amazonaws.com/${aws_s3_bucket.k3s_oidc.bucket}/keys.json"
  })
  content_type = "application/json"
}

resource "aws_s3_object" "k3s_oidc_jwks" {
  bucket       = aws_s3_bucket.k3s_oidc.id
  key          = "keys.json"
  content      = local.secrets_main.k3s.oidc_jwks
  content_type = "application/json"
}

data "tls_certificate" "k3s_oidc" {
  url = "https://s3.${data.aws_region.current.region}.amazonaws.com/${aws_s3_bucket.k3s_oidc.bucket}"
}

resource "aws_iam_openid_connect_provider" "k3s" {
  url = "https://s3.${data.aws_region.current.region}.amazonaws.com/${aws_s3_bucket.k3s_oidc.bucket}"
  client_id_list = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = [
    data.tls_certificate.k3s_oidc.certificates[0].sha1_fingerprint
  ]
  tags = module.context.tags
  # Race; wait on objects being uploaded
  depends_on = [
    aws_s3_bucket_policy.k3s_oidc_public_read,
    aws_s3_object.k3s_oidc_discovery,
    aws_s3_object.k3s_oidc_jwks,
  ]
}

output "k3s_api_endpoint" {
  value     = var.k3s_enabled ? local.k3s_api_fqdn : null
  sensitive = true
}

output "k3s_remote_kubeconfig_path" {
  value = var.k3s_enabled ? "ssm:${aws_instance.k3s_server[0].id}:/etc/rancher/k3s/k3s-remote.yaml" : null
}
