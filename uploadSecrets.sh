#!/usr/bin/env sh
secrets="$(base64 localvars)"
gh secret set --app actions TERRAFORM_ENV_BASE64 --body $secrets