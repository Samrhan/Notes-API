# Fichier: iam.tf (ou à la suite dans main.tf)

# Politique d'assume role pour que Lambda puisse endosser ce rôle
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Rôle IAM pour la fonction Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.project_name}-lambda-exec-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# Politique IAM pour permettre l'écriture dans CloudWatch Logs
data "aws_iam_policy_document" "lambda_logging_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"] # Accès large pour les logs, peut être restreint
  }
}

resource "aws_iam_role_policy" "lambda_logging_policy" {
  name   = "${var.project_name}-lambda-logging-policy"
  role   = aws_iam_role.lambda_execution_role.id
  policy = data.aws_iam_policy_document.lambda_logging_policy_doc.json
}

# Politique IAM pour permettre les actions sur DynamoDB
# Nous utiliserons l'ARN de la table DynamoDB une fois qu'elle sera définie.
# Pour l'instant, nous créons le document de politique, nous l'attacherons plus tard.
data "aws_iam_policy_document" "lambda_dynamodb_policy_doc" {
  statement {
    actions = [
      "dynamodb:PutItem",    # Pour créer une note
      "dynamodb:GetItem",    # Pour lire une note
      "dynamodb:UpdateItem", # Optionnel, pour modifier
      "dynamodb:DeleteItem", # Optionnel, pour supprimer
      "dynamodb:Scan",       # Optionnel, pour lister (attention aux performances sur grosses tables)
      "dynamodb:Query"       # Optionnel, pour requêtes plus ciblées
    ]
    # La ressource sera l'ARN de notre table DynamoDB.
    # Nous le spécifierons plus tard en utilisant une référence à la ressource de la table.
    # Pour l'instant, on peut mettre un placeholder ou le laisser vide et l'ajouter
    # avant d'attacher la politique.
    # Dans ce cas, nous allons construire la politique directement dans la ressource aws_iam_role_policy
    # pour pouvoir référencer l'ARN de la table.
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name   = "${var.project_name}-lambda-dynamodb-policy"
  role   = aws_iam_role.lambda_execution_role.id # Référence au rôle créé précédemment
  policy = data.aws_iam_policy_document.lambda_dynamodb_policy_doc_with_arn.json
}

data "aws_iam_policy_document" "lambda_dynamodb_policy_doc_with_arn" {
  statement {
    effect = "Allow" # Explicitement Allow
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      # "dynamodb:UpdateItem", # Décommentez si vous ajoutez la fonctionnalité de mise à jour
      # "dynamodb:DeleteItem", # Décommentez si vous ajoutez la fonctionnalité de suppression
    ]
    # Référence à l'ARN de la table DynamoDB que nous venons de définir
    resources = [aws_dynamodb_table.notes_table.arn]
  }
}