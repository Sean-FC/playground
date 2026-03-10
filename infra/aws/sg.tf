resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" : "default"
  }
}

resource "aws_security_group" "default_ssh" {
  vpc_id = aws_vpc.main.id
  name   = join(module.context.delimiter, [module.context.id, "ssh"])
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.secrets_main.personal.ip}/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" : join(module.context.delimiter, [module.context.id, "ssh"])
  }
}
