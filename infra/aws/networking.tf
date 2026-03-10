resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name" : join(module.context.delimiter, [module.context.id, "main"])
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" : join(module.context.delimiter, [module.context.id, "igw"])
  }
}

# Creates scoped pub + private subnets per zone; using fck-nat rather than aws provisioned since marginal cost by comparison
module "main_subnets" {
  source  = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets?ref=tags/v3.1.1"
  context = module.context

  vpc_id             = aws_vpc.main.id
  igw_id             = [aws_internet_gateway.default.id]
  ipv4_cidr_block    = [var.self_managed_cidr_block]
  availability_zones = data.aws_availability_zones.current.names

  public_subnets_per_az_count = 1
  public_subnets_per_az_names = ["public"]

  private_subnets_per_az_count = 2
  private_subnets_per_az_names = ["compute", "database"]

  nat_gateway_enabled = false
}

# Gateway endpoints
resource "aws_vpc_endpoint" "gateway" {
  for_each          = toset(var.gateway_endpoints)
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type = "Gateway"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "${each.key}:*",
          ]
          Effect    = "Allow"
          Principal = "*"
          Resource  = "*"
        },
      ]
    }
  )
  tags = {
    "Name" : join(module.context.delimiter, [module.context.id, each.key, "gateway"])
  }
}

# AWS interface endpoints
resource "aws_vpc_endpoint" "interface" {
  for_each          = toset(var.interface_endpoints)
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type = "Interface"

  subnet_ids = module.main_subnets.private_subnet_ids

  tags = {
    "Name" : join(module.context.delimiter, [module.context.id, each.key, "interface"])
  }
}

# Associations
resource "aws_vpc_endpoint_route_table_association" "main_to_gateway" {
  for_each        = aws_vpc_endpoint.gateway
  vpc_endpoint_id = each.value.id
  route_table_id  = aws_vpc.main.main_route_table_id
}

resource "aws_vpc_endpoint_security_group_association" "default_to_interface" {
  for_each          = aws_vpc_endpoint.interface
  vpc_endpoint_id   = each.value.id
  security_group_id = aws_default_security_group.default.id
}

# NAT
resource "aws_key_pair" "fct_nat" {
  key_name   = join(module.context.delimiter, [module.context.id, "fck", "nat"])
  public_key = local.secrets_main.fck_nat.pub_key
  tags = merge(
    module.context.tags,
    { Name : join(module.context.delimiter, [module.context.id, "fck", "nat"]) }
  )
}

module "fck_nat" {
  count  = var.enable_nat ? 1 : 0
  source = "git::https://github.com/RaJiska/terraform-aws-fck-nat?ref=tags/v1.4.0"

  name          = join(module.context.delimiter, [module.context.id, "fck", "nat"])
  vpc_id        = aws_vpc.main.id
  subnet_id     = module.main_subnets.public_subnet_ids[0]
  instance_type = "t4g.micro"

  ha_mode              = false
  use_cloudwatch_agent = true

  update_route_tables = true
  route_tables_ids = {
    for sbn in module.main_subnets.named_private_subnets_stats_map["compute"] :
    "compute-${sbn.az}" => sbn.route_table_id
  }

  ssh_key_name                  = aws_key_pair.fct_nat.key_name
  additional_security_group_ids = [aws_security_group.default_ssh.id]

  tags = merge(
    module.context.tags,
    { Name : join(module.context.delimiter, [module.context.id, "fck", "nat"]) }
  )
}

output "aws_vpc_main_id" {
  value = aws_vpc.main.id
}

output "aws_vpc_main_public_subnet_ids" {
  value = module.main_subnets.public_subnet_ids
}

output "aws_vpc_main_private_subnet_ids" {
  value = module.main_subnets.private_subnet_ids
}
