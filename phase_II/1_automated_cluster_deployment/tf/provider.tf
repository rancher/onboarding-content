provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

provider "rancher2" {
  api_url   = local.rancher_url
  token_key = local.rancher_token
}
