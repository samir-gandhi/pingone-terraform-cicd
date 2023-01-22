module "bxi" {
  source = "../"
  pingone_username = var.pingone_username
  pingone_password = var.pingone_password
  pingone_region = var.pingone_region
  pingone_client_id = var.pingone_client_id
  pingone_client_secret = var.pingone_client_secret
  pingone_environment_id = var.pingone_environment_id
  environment_name = var.environment_name
}

variable "environment_name" {
  description = "name that will be used when creating PingOne Environment"
  default = "sko-cicd-dev"
}