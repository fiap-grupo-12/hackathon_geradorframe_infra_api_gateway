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
    key    = "lambda_auxiliar_terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

# IAM Role para a Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Política de permissões para a função Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Criação da função Lambda
resource "aws_lambda_function" "api_handler" {
  function_name = "ApiGatewayHandler"
  runtime       = "python3.9" # Substitua pelo runtime desejado
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "${path.module}/lambda_function.zip" # Pacote contendo o código da Lambda

  # Variáveis de ambiente (opcional)
  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}

# Permissões para o API Gateway invocar a Lambda
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
}

# Outputs necessários para o API Gateway
output "lambda_invoke_arn" {
  description = "ARN de invocação da função Lambda"
  value       = aws_lambda_function.api_handler.invoke_arn
}

output "lambda_function_name" {
  description = "Nome da função Lambda"
  value       = aws_lambda_function.api_handler.function_name
}