#!/usr/bin/env sh
secrets="$(base64 localvars)"
echo $secrets
gh secret set --app actions TERRAFORM_ENV_BASE64 --body $secrets