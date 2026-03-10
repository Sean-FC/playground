# Configure SSM by default across all EC2 instances
resource "aws_iam_role" "default_management_role" {
  name               = "AWSSystemsManagerDefaultEC2InstanceManagementRole"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume.json
}

resource "aws_iam_role_policy_attachment" "default_management_role" {
  role       = aws_iam_role.default_management_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
}

data "aws_iam_policy_document" "ssm_assume" {
  statement {
    sid    = "AllowSSMAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_ssm_service_setting" "default_host_management" {
  setting_id    = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:servicesetting/ssm/managed-instance/default-ec2-instance-management-role"
  setting_value = aws_iam_role.default_management_role.name
}
