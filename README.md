# SKO 2023 - Terraforming PingOne, Part 1: The Bifrost to a Better Realm

In this lab we will simulate scenarios PingOne consumers may encounter.

Functionally this repos is a template that is prepared to:
- Deploy PingOne configuration needed for BXIndustry instances
- Generate the env file needed to map BXI in Glitch to PingOne
- Show SDLC for Davinci Flows:
  - Edit a Davinci Flow in a "dev" instance, and promote it to a "prod" instance with Github Actions

## Prerequisites

To fully experience this Lab:
- Have a [PingOne organization](https://www.pingidentity.com/en/try-ping.html) with:
  - a worker app
  - Davinci added to the admin environment (or at least the DV connection and IDP used for SSO)
  - a user in the admin environment with required roles
  > NOTE: all of this can be set up via https://flows.pingidentity.cloud/sko-setup
- [terraform cli](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [gh cli](https://cli.github.com/manual/installation) (commonly `brew install gh`) installed and [auth'd](https://cli.github.com/manual/gh_auth_login)
- [terraform cloud free account](https://app.terraform.io/public/signup/account) - This is used to deploy the "prod" env from CI/CD

## Lab Overview

- Use this template repo
- Set up secrets :closed_lock_with_key:
- :rocket: Deploy and test "prod" env
- Deploy "dev" env
- Make, test, and save change in "dev" env
- Open Pull Request
- Merge Pull Request to deploy "prod"

## Use This Template repo
Click "Use this template" :wink:
