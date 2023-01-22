output "app_policies" {
  value = "${module.bxi.app_policies}"
  sensitive = true
}

output "bxi_api_key" {
  value = "${module.bxi.bxi_api_key}"
  sensitive = true
}

output "bxi_api_url" {
  value = "${module.bxi.bxi_api_url}"
}

output "bxi_sdk_token_url" {
  value = "${module.bxi.bxi_sdk_token_url}"
}

output "bxi_company_id" {
  value = "${module.bxi.bxi_company_id}"
}