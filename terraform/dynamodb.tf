# Fichier: dynamodb.tf (ou à la suite dans main.tf)

resource "aws_dynamodb_table" "notes_table" {
  name             = var.dynamodb_table_name # Utilise la variable définie plus tôt
  billing_mode     = "PAY_PER_REQUEST"       # Mode de facturation serverless, bon pour des charges variables/inconnues
  hash_key         = "noteId"                # Clé de partition (clé primaire simple)

  attribute {
    name = "noteId"
    type = "S" # S pour String (chaîne de caractères)
  }

  # Optionnel: Activer le Time To Live (TTL) si vous voulez que les notes expirent
  # ttl {
  #   attribute_name = "TimeToExist"
  #   enabled        = true
  # }

  # Optionnel: Activer le chiffrement côté serveur avec une clé gérée par AWS (recommandé)
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-notes-table"
    Environment = "Dev" # Ou une variable pour l'environnement
  }
}