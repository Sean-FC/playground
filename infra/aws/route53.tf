data "aws_route53_zone" "main" {
  name = local.secrets_main.personal.domain
}

# Zone
resource "aws_route53_zone" "stage" {
  name = "${module.context.stage}.${local.secrets_main.personal.domain}"
}

# Register NS for delegation with parent zone
resource "aws_route53_record" "stage_ns_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${module.context.stage}.${local.secrets_main.personal.domain}"
  type    = "NS"
  ttl     = "86400"
  records = aws_route53_zone.stage.name_servers
}

# Cert
resource "aws_acm_certificate" "star_stage" {
  domain_name       = "*.${aws_route53_zone.stage.name}"
  validation_method = "DNS"
}

# Records
resource "aws_route53_record" "stage_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.star_stage.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  name    = each.value.name
  type    = each.value.type
  zone_id = aws_route53_zone.stage.id
  records = [each.value.record]
  ttl     = 60
}

# Validation
resource "aws_acm_certificate_validation" "star_stage" {
  certificate_arn         = aws_acm_certificate.star_stage.arn
  validation_record_fqdns = [for record in aws_route53_record.stage_acm_validation : record.fqdn]
}

# Allow binding for downstream modules
output "stage_zone_id" {
  value = aws_route53_zone.stage.zone_id
}

output "stage_cert_arn" {
  value = aws_acm_certificate.star_stage.arn
}
