terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.15"
    }
  }
  backend "s3" {
    bucket = "terraform-tfstate-grupo12-fiap-2024-cesar-20250110"
    key    = "api_gateway_terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# Cognito User Pool -
resource "aws_cognito_user_pool" "gerador_de_frame_user_pool" {
  name = "gerador_de_frame_user_pool"

  password_policy {
    minimum_length    = 6
    require_uppercase = false
    require_numbers   = false
    require_symbols   = false
  }

  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true
  }

  username_attributes = ["email"]
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "gerador_de_frame_user_pool_client" {
  name                         = "gerador_de_frame_user_pool_client"
  user_pool_id                 = aws_cognito_user_pool.gerador_de_frame_user_pool.id
  allowed_oauth_flows          = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes         = ["openid", "email", "profile"]
  callback_urls                = ["http://localhost"]
  logout_urls                  = ["http://localhost"]
  default_redirect_uri         = "http://localhost"
  generate_secret              = false
  supported_identity_providers = ["COGNITO"]

  access_token_validity        = 1
  id_token_validity            = 1
  refresh_token_validity       = 720

  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "gerador_de_frame_domain" {
  domain       = "gerador-de-frame-domain"
  user_pool_id = aws_cognito_user_pool.gerador_de_frame_user_pool.id
}

# Cognito Identity Pool
resource "aws_cognito_identity_pool" "gerador_de_frame_identity_pool" {
  identity_pool_name               = "gerador_de_frame_identity_pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id              = aws_cognito_user_pool_client.gerador_de_frame_user_pool_client.id
    provider_name          = "cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.gerador_de_frame_user_pool.id}"
    server_side_token_check = true
  }
}

# IAM Role para API Gateway
resource "aws_iam_role" "api_gateway_role" {
  name = "api_gateway_cognito_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_policy" {
  name   = "api_gateway_cognito_policy"
  role   = aws_iam_role.api_gateway_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "cognito-idp:DescribeUserPool"
        Effect   = "Allow"
        Resource = aws_cognito_user_pool.gerador_de_frame_user_pool.arn
      }
    ]
  })
}

# API Gateway
resource "aws_api_gateway_rest_api" "hackathon_geradorframe_api" {
  name        = "hackathon_geradorframe_api"
  description = "API Gateway for Hackathon GeradorFrame"
}

# Recurso dinâmico /video/{proxy+}
resource "aws_api_gateway_resource" "video_proxy" {
  rest_api_id = aws_api_gateway_rest_api.hackathon_geradorframe_api.id
  parent_id   = aws_api_gateway_rest_api.hackathon_geradorframe_api.root_resource_id
  path_part   = "video"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.hackathon_geradorframe_api.id
  parent_id   = aws_api_gateway_resource.video_proxy.id
  path_part   = "{proxy+}" # Permite caminhos dinâmicos
}

# Método ANY para /video/{proxy+}
resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.hackathon_geradorframe_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# Integração Lambda
resource "aws_api_gateway_integration" "proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.hackathon_geradorframe_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                   = "CognitoAuthorizer"
  rest_api_id            = aws_api_gateway_rest_api.hackathon_geradorframe_api.id
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = [aws_cognito_user_pool.gerador_de_frame_user_pool.arn]
  identity_source        = "method.request.header.Authorization"
}

# Deployment
resource "aws_api_gateway_deployment" "hackathon_geradorframe_deployment" {
  rest_api_id = aws_api_gateway_rest_api.hackathon_geradorframe_api.id

  triggers = {
    redeploy_trigger = "${timestamp()}"
  }

  depends_on = [
    aws_api_gateway_integration.proxy_integration
  ]
}

# Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.hackathon_geradorframe_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.hackathon_geradorframe_api.id
  stage_name    = "prod"
  lifecycle {
    create_before_destroy = true
    ignore_changes = [deployment_id]
  }
}

# CloudWatch Logs para API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name = "/aws/apigateway/hackathon_geradorframe_api"
}

# Outputs
output "api_gateway_base_url" {
  description = "URL base do API Gateway"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "exemplo_url_solicitar_url_envio" {
  description = "Exemplo de URL para solicitar_url_envio"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/video/solicitar_url_envio"
}

output "exemplo_url_solicitar_url_imagens" {
  description = "Exemplo de URL para solicitar_url_imagens"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/video/solicitar_url_imagens"
}

output "cognito_login_url" {
  description = "URL de login Cognito"
  value       = "https://${aws_cognito_user_pool_domain.gerador_de_frame_domain.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/authorize?response_type=code&client_id=${aws_cognito_user_pool_client.gerador_de_frame_user_pool_client.id}&redirect_uri=http://localhost"
}

output "identity_pool_id" {
  description = "ID do Identity Pool do Cognito"
  value       = aws_cognito_identity_pool.gerador_de_frame_identity_pool.id
}

output "client_id" {
  description = "ID do Client no Cognito"
  value       = aws_cognito_user_pool_client.gerador_de_frame_user_pool_client.id
}

output "user_pool_id" {
  description = "ID do User Pool do Cognito"
  value       = aws_cognito_user_pool.gerador_de_frame_user_pool.id
}