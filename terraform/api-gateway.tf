# Fichier: api_gateway.tf (ou à la suite dans main.tf)

# 1. Définir l'API REST elle-même
resource "aws_api_gateway_rest_api" "notes_api" {
  name        = "${var.project_name}-rest-api"
  description = "API REST pour le service de prise de notes"

  # Définition du type de point de terminaison (endpoint)
  # EDGE: Optimisé pour une distribution globale via CloudFront (par défaut)
  # REGIONAL: Pour des API accessibles principalement depuis la même région
  # PRIVATE: Pour des API accessibles uniquement depuis votre VPC
  endpoint_configuration {
    types = ["REGIONAL"] # REGIONAL est souvent un bon choix pour commencer
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = "Dev"
  }
}

# 2. Définir la ressource "/notes" (le chemin URL)
resource "aws_api_gateway_resource" "notes_resource" {
  rest_api_id = aws_api_gateway_rest_api.notes_api.id
  parent_id   = aws_api_gateway_rest_api.notes_api.root_resource_id # Se rattache à la racine de l'API
  path_part   = "notes"                                           # Le segment de chemin -> /notes
}

# 3. Définir la méthode POST sur /notes pour créer une note
resource "aws_api_gateway_method" "post_notes_method" {
  rest_api_id   = aws_api_gateway_rest_api.notes_api.id
  resource_id   = aws_api_gateway_resource.notes_resource.id
  http_method   = "POST"
  authorization = "NONE" # Pas d'autorisation pour cet exemple simple, mais on pourrait utiliser "AWS_IAM", COGNITO_USER_POOLS, etc.
}

# 4. Définir l'intégration entre la méthode POST et la fonction Lambda
resource "aws_api_gateway_integration" "post_notes_integration" {
  rest_api_id = aws_api_gateway_rest_api.notes_api.id
  resource_id = aws_api_gateway_resource.notes_resource.id
  http_method = aws_api_gateway_method.post_notes_method.http_method

  integration_http_method = "POST" # La méthode HTTP pour l'appel backend (Lambda)
  type                    = "AWS_PROXY" # Intégration proxy Lambda : la requête entière est passée à Lambda
  uri                     = aws_lambda_function.notes_api_lambda.invoke_arn # ARN d'invocation de notre Lambda
}

# 5. Définir la ressource "/notes/{noteId}" pour un ID de note spécifique
resource "aws_api_gateway_resource" "note_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.notes_api.id
  parent_id   = aws_api_gateway_resource.notes_resource.id # Se rattache à /notes
  path_part   = "{noteId}"                                 # Chemin avec un paramètre -> /notes/{noteId}
}

# 6. Définir la méthode GET sur /notes/{noteId} pour récupérer une note
resource "aws_api_gateway_method" "get_note_id_method" {
  rest_api_id   = aws_api_gateway_rest_api.notes_api.id
  resource_id   = aws_api_gateway_resource.note_id_resource.id
  http_method   = "GET"
  authorization = "NONE"

  # Définir que noteId est un paramètre de chemin requis
  request_parameters = {
    "method.request.path.noteId" = true
  }
}

# 7. Définir l'intégration entre la méthode GET et la fonction Lambda
resource "aws_api_gateway_integration" "get_note_id_integration" {
  rest_api_id = aws_api_gateway_rest_api.notes_api.id
  resource_id = aws_api_gateway_resource.note_id_resource.id
  http_method = aws_api_gateway_method.get_note_id_method.http_method

  integration_http_method = "POST"    # Lambda est toujours invoquée via POST par API Gateway en mode proxy
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.notes_api_lambda.invoke_arn
}

# 8. Déployer l'API pour la rendre accessible
resource "aws_api_gateway_deployment" "notes_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.notes_api.id

  triggers = {
    redeployment = sha1(jsonencode({
      # Include any part of your API configuration that, if changed,
      # should result in a new deployment.
      api_definition_hash = sha1(jsonencode({
        rest_api_name = aws_api_gateway_rest_api.notes_api.name
        resources     = {
          notes_resource_path   = aws_api_gateway_resource.notes_resource.path_part
          note_id_resource_path = aws_api_gateway_resource.note_id_resource.path_part
        }
        methods       = {
          post_notes_method = {
            http_method   = aws_api_gateway_method.post_notes_method.http_method
            authorization = aws_api_gateway_method.post_notes_method.authorization
            # You can add other relevant attributes from aws_api_gateway_method.post_notes_method
          }
          get_note_id_method = { # Specifically tracking the GET method's config
            http_method        = aws_api_gateway_method.get_note_id_method.http_method
            authorization      = aws_api_gateway_method.get_note_id_method.authorization # Critical for your issue
            request_parameters = aws_api_gateway_method.get_note_id_method.request_parameters
            # You can add other relevant attributes from aws_api_gateway_method.get_note_id_method
          }
        }
        integrations  = {
          post_notes_integration = {
            type                    = aws_api_gateway_integration.post_notes_integration.type
            uri                     = aws_api_gateway_integration.post_notes_integration.uri
            integration_http_method = aws_api_gateway_integration.post_notes_integration.integration_http_method
          }
          get_note_id_integration = {
            type                    = aws_api_gateway_integration.get_note_id_integration.type
            uri                     = aws_api_gateway_integration.get_note_id_integration.uri
            integration_http_method = aws_api_gateway_integration.get_note_id_integration.integration_http_method
          }
        }
        # You can add more details from your API Gateway resources, methods, and integrations
        # if their changes should also trigger a redeployment.
      }))
      # If you also change Lambda code and want to ensure API Gateway redeploys
      # (though typically Lambda updates are separate unless the ARN changes or integration URI changes)
      # lambda_source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    }))
  }

  lifecycle {
    create_before_destroy = true # Important pour éviter les interruptions de service lors des mises à jour
  }
}

# 9. Créer un "stage" (environnement) pour notre déploiement (ex: "v1" ou "dev")
resource "aws_api_gateway_stage" "notes_api_stage" {
  deployment_id = aws_api_gateway_deployment.notes_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.notes_api.id
  stage_name    = "v1" # Nom du stage, par exemple "v1", "dev", "prod"
}