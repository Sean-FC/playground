resource "aws_ssm_parameter" "airflow" {
  name = "/${module.context.stage}/eso/airflow"
  type = "SecureString"
  value = jsonencode({
    fernet-key           = local.secrets_main.airflow.fernet_key
    api-secret-key       = local.secrets_main.airflow.api_secret_key
    jwt-secret           = local.secrets_main.airflow.jwt_secret
    webserver-secret-key = local.secrets_main.airflow.webserver_secret_key
    git-sync-ssh-key     = local.secrets_main.airflow.git_sync_ssh_key
  })
  tags = module.context.tags
}
