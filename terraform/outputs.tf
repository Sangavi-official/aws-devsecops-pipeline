output "api_url" {
  description = "Public URL of the visitor counter API"
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/visits"
}
