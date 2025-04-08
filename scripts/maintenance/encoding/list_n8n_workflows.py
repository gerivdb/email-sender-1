import requests
import json
from datetime import datetime

# Configuration
n8n_url = "http://localhost:5678"
api_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw"  # Jeton API AUGMENT

def format_date(date_str):
    if not date_str:
        return "Non disponible"
    try:
        date_obj = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
        return date_obj.strftime("%d/%m/%Y %H:%M:%S")
    except:
        return date_str

# Vérifier la connexion à n8n
print(f"Vérification de la connexion à n8n ({n8n_url})...", end="")
try:
    headers = {
        "X-N8N-API-KEY": api_token
    }
    response = requests.get(f"{n8n_url}/api/v1/workflows", headers=headers)
    response.raise_for_status()
    print(" Connecté!")
except Exception as e:
    print(f" Échec de connexion!")
    print(f"Erreur: {str(e)}")
    exit(1)

# Récupérer tous les workflows existants
print("\nListe des workflows dans n8n:")
print("=================================")
try:
    workflows = response.json()
    
    if not workflows or len(workflows) == 0:
        print("Aucun workflow trouvé dans n8n.")
        exit(0)
    
    # Afficher la liste des workflows
    for workflow in workflows:
        print(f"- {workflow.get('name', 'Sans nom')} (ID: {workflow.get('id', 'N/A')})")
        print(f"  Créé le: {format_date(workflow.get('createdAt'))}")
        print(f"  Mis à jour le: {format_date(workflow.get('updatedAt'))}")
        print(f"  Actif: {workflow.get('active', False)}")
        print("  ---------------------------------")
    
    print(f"\nTotal: {len(workflows)} workflows")
except Exception as e:
    print(f"Erreur lors de la récupération des workflows: {str(e)}")
    exit(1)
