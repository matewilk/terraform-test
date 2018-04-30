provider "aws" {
  access_key = ""
  secret_key = ""
  region = "eu-west-2"
}

resource "aws_lambda_function" "terraform-test" {
  function_name = "terraform-test-lambda"

  s3_bucket = "matewilk-terraform-test"
  s3_key = "terraform-test-lambda.zip"

  handler = "lambda.handler"
  role = "${aws_iam_role.terraform-test-lambda-exec.arn}"
  runtime = "nodejs8.10"
}

resource "aws_s3_bucket" "terraform-test-s3-lambda-result" {
  bucket = "matewilk-terraform-test-result"
  acl    = "private"
}

resource "aws_iam_role" "terraform-test-lambda-exec" {
  name = "terraform-test-lambda-exec"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3_policy" {
  name = "terraform-test-lambda-s3-access-policy"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:DeleteObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.terraform-test-s3-lambda-result.id}",
        "arn:aws:s3:::${aws_s3_bucket.terraform-test-s3-lambda-result.id}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "basic-attach" {
  role       = "${aws_iam_role.terraform-test-lambda-exec.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3-attach" {
  role       = "${aws_iam_role.terraform-test-lambda-exec.name}"
  policy_arn = "${aws_iam_policy.s3_policy.arn}"
}

resource "aws_api_gateway_resource" "proxy" {
  parent_id = "${aws_api_gateway_rest_api.terraform-test-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.terraform-test-api.id}"
  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  authorization = "NONE"
  http_method = "ANY"
  resource_id = "${aws_api_gateway_resource.proxy.id}"
  rest_api_id = "${aws_api_gateway_rest_api.terraform-test-api.id}"
}

resource "aws_api_gateway_integration" "lambda" {
  http_method = "${aws_api_gateway_method.proxy.http_method}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.terraform-test-api.id}"

  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${aws_lambda_function.terraform-test.invoke_arn}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.terraform-test.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.terraform-test-api-gateway-deployment.execution_arn}/*"
}
