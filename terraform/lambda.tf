# Fichier: lambda.tf (ou à la suite dans main.tf)

# Création de l'archive du code Lambda
# Terraform peut créer l'archive pour vous à partir de fichiers source.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda.py" # Assurez-vous que ce fichier existe au même niveau
  output_path = "lambda_package.zip" # Chemin où l'archive sera créée
}

resource "aws_lambda_function" "notes_api_lambda" {
  function_name = "${var.project_name}-handler"
  handler       = "lambda.lambda_handler" # Nom_fichier.nom_fonction_handler
  runtime       = "python3.9"                      # Choisissez une version de Python supportée
  role          = aws_iam_role.lambda_execution_role.arn # Le rôle IAM que nous avons créé

  # Informations sur le package de code
  filename         = data.archive_file.lambda_zip.output_path # Chemin vers l'archive ZIP
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256 # Pour détecter les changements de code

  # Variables d'environnement pour la Lambda
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.notes_table.name # Passe le nom de la table à la Lambda
    }
  }

  # Timeout et mémoire (ajuster si nécessaire)
  timeout     = 10 # en secondes
  memory_size = 128 # en Mo

  tags = {
    Name        = "${var.project_name}-lambda"
    Environment = "Dev"
  }
}

# Permission pour qu'API Gateway puisse invoquer cette fonction Lambda
# Nous définirons cette ressource après avoir créé l'API Gateway,
# car elle a besoin de l'ARN de l'API Gateway.
# aws_lambda_permission "api_gateway_permission" { ... }

resource "aws_lambda_permission" "api_gateway_permission_to_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notes_api_lambda.function_name # Nom de notre fonction Lambda
  principal     = "apigateway.amazonaws.com" # Le service API Gateway

  # Restreindre la permission à notre API Gateway spécifique
  # L'ARN source est au format: arn:aws:execute-api:region:account-id:api-id/*/METHOD/resource-path
  source_arn = "${aws_api_gateway_rest_api.notes_api.execution_arn}/*/*/*"
  # Le /*/*/* à la fin signifie "n'importe quelle méthode sur n'importe quelle ressource de cette API et de ce stage"
  # Vous pouvez être plus spécifique si nécessaire, par exemple:
  # source_arn = "${aws_api_gateway_rest_api.notes_api.execution_arn}/${aws_api_gateway_stage.notes_api_stage.stage_name}/*/*"
  # Ou même par méthode :
  # source_arn = "${aws_api_gateway_rest_api.notes_api.execution_arn}/${aws_api_gateway_stage.notes_api_stage.stage_name}/POST/notes"
}