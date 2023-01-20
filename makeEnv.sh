#!/usr/bin/env sh
_env="dev"
_envFileName=glitchenv
printf "" > "$_envFileName"
for i in BXI_API_URL BXI_SDK_TOKEN_URL BXI_API_KEY BXI_COMPANY_ID ; do
  _lower=$(echo "$i" | tr '[:upper:]' '[:lower:]')
  printf "$i=%s\n" "$(terraform -chdir=${_env} output -raw ${_lower} )" >> ${_envFileName}
done

{ 
  printf "BXI_LOGIN_POLICY_ID=%s\n" "$(jq -r '.outputs.app_policies.value.Authentication' ${_env}/terraform.tfstate)"
  printf "BXI_REGISTRATION_POLICY_ID=%s\n" "$(jq -r '.outputs.app_policies.value.Registration' ${_env}/terraform.tfstate)"
  printf "BXI_ACTIVE_VERTICAL=company\n"
  printf "BXI_DV_JS_URL=https://assets.pingone.com/davinci/latest/davinci.js\n"
} >> ${_envFileName}

for i in BXI_DASHBOARD_POLICY_ID BXI_GENERIC_POLICY_ID BXI_REMIX_POLICY_ID BXI_SHOW_REMIX_BUTTON BXI_GLITCH_REMIX_PROJECT ; do
  printf "%s=\n" "$i" >> ${_envFileName}
done