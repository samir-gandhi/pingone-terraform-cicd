terraform {
  required_providers {
    pingone = {
      source = "pingidentity/pingone"
    }
    davinci = {
      source = "pingidentity/davinci"
    }
  }
}


provider "pingone" {
  client_id = var.pingone_client_id
  client_secret = var.pingone_client_secret
  environment_id = var.pingone_environment_id
  region         = var.pingone_region
  force_delete_production_type = false
}

provider "davinci" {
  username = var.pingone_username
  password = var.pingone_password
  environment_id = var.pingone_environment_id
  region = var.pingone_region
}

data "pingone_environment" "admin_environment" {
  environment_id = var.pingone_environment_id
}

# Find license based on license name

data "pingone_licenses" "internal" {
  organization_id = data.pingone_environment.admin_environment.organization_id

  data_filter {
    name = "name"
    values = [
      "INTERNAL"
    ]
  }

  data_filter {
    name   = "status"
    values = ["ACTIVE"]
  }
}

resource "pingone_environment" "environment" {
  name        = var.environment_name
  description = "BXI Dev"
  type        = "SANDBOX"
  license_id  = data.pingone_licenses.internal.ids[0]

  default_population {
    name        = "My Population"
    description = "My new population for users"
  }

  service {
    type = "SSO"
  }
  service {
    type = "MFA"
  }
  service {
    type = "DaVinci"
  }

}

data "pingone_role" "identity_data_admin" {
  name = "Identity Data Admin"
}

data "pingone_role" "environment_admin" {
  name = "Environment Admin"
}

data "pingone_user" "admin_user" {
  environment_id = var.pingone_environment_id
  username       = var.pingone_username
}

resource "pingone_role_assignment_user" "admin_sso" {
  environment_id       = var.pingone_environment_id
  user_id              = data.pingone_user.admin_user.id
  role_id              = data.pingone_role.identity_data_admin.id
  scope_environment_id = resource.pingone_environment.environment.id
}

resource "pingone_role_assignment_user" "environment_admin_sso" {
  environment_id       = var.pingone_environment_id
  user_id              = data.pingone_user.admin_user.id
  role_id              = data.pingone_role.environment_admin.id
  scope_environment_id = resource.pingone_environment.environment.id
}

resource "pingone_population" "customers" {
  environment_id = resource.pingone_environment.environment.id

  name        = "Customers"
  description = "Customer Identities"
}

resource "pingone_application" "worker" {
  environment_id = resource.pingone_environment.environment.id
  name           = "dv-connection"
  enabled        = true

  oidc_options {
    type                        = "WORKER"
    grant_types                 = ["CLIENT_CREDENTIALS"]
    token_endpoint_authn_method = "CLIENT_SECRET_BASIC"
  }
}

resource "pingone_application_role_assignment" "worker_app_identity_admin_role" {
  environment_id       = pingone_environment.environment.id
  application_id       = pingone_application.worker.id
  role_id              = data.pingone_role.identity_data_admin.id
  scope_environment_id = pingone_environment.environment.id
}

resource "pingone_application_role_assignment" "worker_app_environment_admin_role" {
  environment_id       = pingone_environment.environment.id
  application_id       = pingone_application.worker.id
  role_id              = data.pingone_role.environment_admin.id
  scope_environment_id = pingone_environment.environment.id
}

resource "pingone_mfa_policy" "standard" {
  environment_id = pingone_environment.environment.id
  name           = "standard"

  mobile {
    enabled = false
  }

  totp {
    enabled = true
  }

  security_key {
    enabled = true
  }

  platform {
    enabled = true
  }

  sms {
    enabled = false
  }

  voice {
    enabled = false
  }

  email {
    enabled = true
  }

}

data "davinci_connections" "all" {
  environment_id = resource.pingone_role_assignment_user.admin_sso.scope_environment_id
  depends_on = [
    resource.pingone_role_assignment_user.environment_admin_sso
  ]
}

resource "davinci_variable" "population" {
  environment_id = resource.pingone_role_assignment_user.admin_sso.scope_environment_id
  depends_on     = [data.davinci_connections.all]
  name = "populationId"
  context = "company"
  description = "pingone customers population id"
  type = "string"
  value = resource.pingone_population.customers.id
  mutable = false
}

resource "davinci_variable" "agreement" {
  environment_id = resource.pingone_role_assignment_user.admin_sso.scope_environment_id
  depends_on     = [data.davinci_connections.all]
  name = "agreementId"
  context = "company"
  description = "some agreement.."
  type = "string"
  value = "abc123"
  mutable = false
}

resource "davinci_connection" "mfa" {
  depends_on     = [data.davinci_connections.all]
  environment_id = resource.pingone_role_assignment_user.admin_sso.scope_environment_id
  connector_id   = "pingOneMfaConnector"
  name           = "PingOne MFA"
  properties {
    name  = "clientId"
    value = resource.pingone_application.worker.oidc_options[0].client_id
  }
  properties {
    name  = "clientSecret"
    value = resource.pingone_application.worker.oidc_options[0].client_secret
  }
  properties {
    name  = "envId"
    value = resource.pingone_role_assignment_user.admin_sso.scope_environment_id
  }
  properties {
    name  = "policyId"
    value = resource.pingone_mfa_policy.standard.id
  }
  properties {
    name  = "region"
    value = coalesce(
      resource.pingone_environment.environment.region == "Europe" ? "EU" :"",
      resource.pingone_environment.environment.region == "AsiaPacific" ? "AP" :"",
      resource.pingone_environment.environment.region == "Canada" ? "CA" :"",
      resource.pingone_environment.environment.region == "NorthAmerica" ? "NA" :"",
    )
  }
}

resource "davinci_connection" "node" {
  depends_on     = [data.davinci_connections.all]
  environment_id = resource.pingone_role_assignment_user.admin_sso.scope_environment_id
  connector_id   = "nodeConnector"
  name           = "Node"
}

resource "davinci_flow" "bxi_registration" {
  environment_id = resource.pingone_role_assignment_user.admin_sso.scope_environment_id
  flow_json = file("${path.module}/BXI-Registration.json")
  depends_on = [data.davinci_connections.all]
  connections {
    connection_name = "PingOne"
    connection_id = "94141bf2f1b9b59a5f5365ff135e02bb"
  }
  connections {
    connection_name = "Http"
    connection_id = "867ed4363b2bc21c860085ad2baa817d"
  }
  connections {
    connection_name = "Annotation"
    connection_id = "921bfae85c38ed45045e07be703d86b8"
  }
  connections {
    connection_name = "Variables"
    connection_id = "06922a684039827499bdbdd97f49827b"
  }
  connections {
    connection_name = "Error Customize"
    connection_id = "6d8f6f706c45fd459a86b3f092602544"
  }
  connections {
    connection_name = resource.davinci_connection.mfa.name
    connection_id = resource.davinci_connection.mfa.id
  }
  variables {
    variable_id = resource.davinci_variable.population.id
    variable_name = resource.davinci_variable.population.name
  }
  variables {
    variable_id = resource.davinci_variable.agreement.id
    variable_name = resource.davinci_variable.agreement.name
  }
}

resource "davinci_flow" "bxi_authentication" {
  environment_id = resource.pingone_role_assignment_user.admin_sso.scope_environment_id
  flow_json = file("${path.module}/BXI-Authentication.json")
  depends_on = [data.davinci_connections.all]
  connections {
    connection_name = "PingOne"
    connection_id = "94141bf2f1b9b59a5f5365ff135e02bb"
  }
  connections {
    connection_name = "Http"
    connection_id = "867ed4363b2bc21c860085ad2baa817d"
  }
  connections {
    connection_name = "Annotation"
    connection_id = "921bfae85c38ed45045e07be703d86b8"
  }
  connections {
    connection_name = "Variables"
    connection_id = "06922a684039827499bdbdd97f49827b"
  }
  connections {
    connection_name = "Error Customize"
    connection_id = "6d8f6f706c45fd459a86b3f092602544"
  }
  connections {
    connection_name = "Functions"
    connection_id = "de650ca45593b82c49064ead10b9fe17"
  }
  connections {
    connection_id = resource.davinci_connection.node.id
    connection_name = resource.davinci_connection.node.name
  }
  connections {
    connection_name = resource.davinci_connection.mfa.name
    connection_id = resource.davinci_connection.mfa.id
  }
  variables {
    variable_id = resource.davinci_variable.population.id
    variable_name = resource.davinci_variable.population.name
  }
  variables {
    variable_id = resource.davinci_variable.agreement.id
    variable_name = resource.davinci_variable.agreement.name
  }
}

resource "davinci_application" "bxi_app" {
  environment_id = resource.pingone_role_assignment_user.admin_sso.scope_environment_id
  name           = "BXI App"
  oauth {
    enabled = true
    values {
      allowed_grants                = ["authorizationCode"]
      allowed_scopes                = ["openid", "profile"]
      enabled                       = true
      enforce_signed_request_openid = false
    }
  }
  policies {
    name = "Registration"
    policy_flows {
      flow_id    = resource.davinci_flow.bxi_registration.flow_id
      version_id = -1
      weight     = 100
    }
  }
  policies {
    name = "Authentication"
    policy_flows {
      flow_id    = resource.davinci_flow.bxi_authentication.flow_id
      version_id = -1
      weight     = 100
    }
  }
  saml {
    values {
      enabled                = false
      enforce_signed_request = true
    }
  }

  depends_on = [
    data.davinci_connections.all
  ]
}

output "app_policies" {
  value = {for i in resource.davinci_application.bxi_app.policies : "${i.name}" => i.policy_id}
  sensitive = true
}

output "bxi_api_key" {
  value = resource.davinci_application.bxi_app.api_keys.prod
  sensitive = true

}

output "bxi_api_url" {
  value = format("https://auth.pingone.%s", 
    coalesce(
      resource.pingone_environment.environment.region == "Europe" ? "eu" :"",
      resource.pingone_environment.environment.region == "AsiaPacific" ? "asia" :"",
      resource.pingone_environment.environment.region == "Canada" ? "ca" :"",
      resource.pingone_environment.environment.region == "NorthAmerica" ? "com" :"",
    )
  )
}

output "bxi_sdk_token_url" {
  value = format("https://orchestrate-api.pingone.%s", coalesce(
    resource.pingone_environment.environment.region == "Europe" ? "eu" :"",
    resource.pingone_environment.environment.region == "AsiaPacific" ? "asia" :"",
    resource.pingone_environment.environment.region == "Canada" ? "ca" :"",
    resource.pingone_environment.environment.region == "NorthAmerica" ? "com" :"",
    ))
}

output "bxi_company_id" {
  value = resource.pingone_environment.environment.id
}
