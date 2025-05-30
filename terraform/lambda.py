import json
import os
import uuid
import boto3
from datetime import datetime
import logging

# Configuration du logger
# Il est préférable d'utiliser le module logging plutôt que print() pour les logs dans Lambda
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialiser les clients AWS en dehors du handler pour la réutilisation (performance)
try:
    dynamodb_resource = boto3.resource('dynamodb')
    DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')

    if not DYNAMODB_TABLE_NAME:
        logger.error("La variable d'environnement DYNAMODB_TABLE_NAME n'est pas définie.")
        # Cette erreur est critique et empêchera la fonction de fonctionner correctement.
        # On pourrait lever une exception ici pour que Lambda marque l'initialisation comme échouée.
        # Pour cet exemple, on laisse la fonction potentiellement échouer plus tard si table est None.
        table = None
    else:
        table = dynamodb_resource.Table(DYNAMODB_TABLE_NAME)
except Exception as e:
    logger.error(f"Erreur lors de l'initialisation des ressources AWS: {e}")
    table = None # Assurer que table est None si l'initialisation échoue

def build_response(status_code, body_content):
    """Helper function to build the API Gateway proxy response."""
    return {
        'statusCode': status_code,
        'body': json.dumps(body_content),
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*' # Pour CORS, à restreindre en production
        }
    }

def create_note(event_body):
    """Crée une nouvelle note."""
    try:
        body = json.loads(event_body or '{}') # Gérer le cas où body est None
    except json.JSONDecodeError:
        logger.error("Corps de la requête JSON invalide.")
        return build_response(400, {'error': 'Corps de la requête JSON invalide'})

    content = body.get('content')
    if not content:
        logger.warning("Tentative de création de note sans contenu.")
        return build_response(400, {'error': 'Le contenu de la note (content) est requis'})

    note_id = str(uuid.uuid4())
    timestamp = datetime.utcnow().isoformat() + "Z" # Ajout de Z pour format UTC standard

    item = {
        'noteId': note_id,
        'content': content,
        'createdAt': timestamp,
        'updatedAt': timestamp
    }

    try:
        table.put_item(Item=item)
        logger.info(f"Note créée avec ID: {note_id}")
        return build_response(201, {'noteId': note_id, 'message': 'Note créée avec succès'})
    except Exception as e:
        logger.error(f"Erreur lors de l'écriture dans DynamoDB: {e}")
        return build_response(500, {'error': 'Erreur interne du serveur lors de la création de la note'})


def get_note(note_id_param):
    """Récupère une note par son ID."""
    if not note_id_param:
        return build_response(400, {'error': 'noteId est requis dans le chemin'})

    try:
        response = table.get_item(Key={'noteId': note_id_param})
        item = response.get('Item')

        if item:
            logger.info(f"Note récupérée avec ID: {note_id_param}")
            return build_response(200, item)
        else:
            logger.warning(f"Note non trouvée avec ID: {note_id_param}")
            return build_response(404, {'error': 'Note non trouvée'})
    except Exception as e:
        logger.error(f"Erreur lors de la lecture depuis DynamoDB pour ID {note_id_param}: {e}")
        return build_response(500, {'error': 'Erreur interne du serveur lors de la récupération de la note'})


def lambda_handler(event, context):
    logger.info(f"Événement reçu: {json.dumps(event)}")

    if table is None:
        logger.critical("La table DynamoDB n'est pas initialisée. Vérifiez la configuration.")
        return build_response(500, {'error': "Erreur critique de configuration du serveur"})

    http_method = event.get('httpMethod')
    path = event.get('path')

    # Routage simple basé sur la méthode et le chemin
    if http_method == 'POST' and path == '/notes':
        return create_note(event.get('body'))

    elif http_method == 'GET':
        path_params = event.get('pathParameters')
        if path_params and 'noteId' in path_params and path == f"/notes/{path_params['noteId']}":
            return get_note(path_params['noteId'])
        else:
            logger.warning(f"Chemin GET non supporté ou noteId manquant: {path}")
            return build_response(404, {'error': 'Ressource non trouvée ou noteId manquant'})

    else:
        logger.warning(f"Méthode {http_method} ou chemin {path} non supporté(e).")
        return build_response(405, {'error': f"Méthode {http_method} non supportée pour le chemin {path}"})