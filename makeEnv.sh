#!/usr/bin/env sh
# _env="dev"
while :;do
  case "$1" in
    -h|--help)
      show_help
      shift 2
      ;;
    -e)
      _env=$2
      shift 2
      ;;
    -?*)
      printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
      show_help
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

show_help()
{
  # Display show_help
  echo "Generates env file"
  echo
  echo "Syntax: ./makeEnv.sh -e <dev>"
  echo "options:"
  echo "  -e            REQUIRED - environment/folder to use."
  echo "  -h|--help     Print this show_help."
  echo
  exit 0
}

if test -z "${_env}" ; then
  show_help
fi
_envFileName="glitchenv${_env}"
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