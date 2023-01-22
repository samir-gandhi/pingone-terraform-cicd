#!/usr/bin/env sh
secrets="$(base64 localvars)"
gh secret set --app actions TERRAFORM_ENV_BASE64 --body $secrets
echo "Enter TF Cloud Token: (leave empty to skip)"
read -r TF_TOKEN
if test -n "$TF_TOKEN"; then
  gh secret set --app actions TF_API_TOKEN --body $TF_TOKEN
fi