variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "A região AWS onde os recursos serão criados."
}
variable "lambda_invoke_arn" {
  type        = string
  default     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:471112683391:function:ApiGatewayHandler/invocations"
  description = "ARN da função Lambda que será invocada pelo API Gateway."
}