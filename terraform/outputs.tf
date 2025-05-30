# Fichier: outputs.tf (ou à la suite dans main.tf)

output "api_endpoint_url" {
  description = "L'URL de base pour invoquer l'API de prise de notes."
  value       = aws_api_gateway_stage.notes_api_stage.invoke_url
  # L'URL sera quelque chose comme : https://abcdef123.execute-api.eu-west-3.amazonaws.com/v1
}