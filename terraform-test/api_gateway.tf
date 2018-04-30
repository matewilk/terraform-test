resource "aws_api_gateway_rest_api" "terraform-test-api" {
  name = "Terraform Test API Gateway"
  description = "API Gateway for terraform test"
}

resource "aws_api_gateway_method" "proxy_root" {
  authorization = "NONE"
  http_method = "ANY"
  resource_id = "${aws_api_gateway_rest_api.terraform-test-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.terraform-test-api.id}"
}

resource "aws_api_gateway_integration" "lambda_root" {
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.terraform-test-api.id}"

  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:eu-west-2:lambda:path/2015-03-31/functions/${aws_lambda_function.terraform-test.arn}/invocations"
}

resource "aws_api_gateway_deployment" "terraform-test-api-gateway-deployment" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root"
  ]

  rest_api_id = "${aws_api_gateway_rest_api.terraform-test-api.id}"
  stage_name = "test"
}

output "terraform-test-api-gateway-base-url" {
  value = "${aws_api_gateway_deployment.terraform-test-api-gateway-deployment.invoke_url}"
}
