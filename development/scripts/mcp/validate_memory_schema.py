"""
Script pour valider le schéma de métadonnées des mémoires.
Ce script vérifie que le schéma JSON est valide et conforme aux attentes.
"""

import os
import json
import jsonschema
from jsonschema import validate
from datetime import datetime
import argparse


def load_schema(schema_path):
    """
    Charge le schéma JSON depuis un fichier.
    
    Args:
        schema_path: Chemin vers le fichier de schéma.
        
    Returns:
        Le schéma JSON chargé.
    """
    try:
        with open(schema_path, 'r', encoding='utf-8') as f:
            schema = json.load(f)
        return schema
    except Exception as e:
        raise Exception(f"Erreur lors du chargement du schéma: {e}")


def validate_schema(schema):
    """
    Valide que le schéma JSON est conforme au standard JSON Schema.
    
    Args:
        schema: Le schéma JSON à valider.
        
    Returns:
        True si le schéma est valide, False sinon.
    """
    try:
        # Valider que le schéma est conforme au méta-schéma JSON Schema
        jsonschema.validators.validator_for(schema).check_schema(schema)
        return True
    except Exception as e:
        print(f"Erreur de validation du schéma: {e}")
        return False


def create_sample_memory(schema):
    """
    Crée un exemple de mémoire conforme au schéma.
    
    Args:
        schema: Le schéma JSON à utiliser.
        
    Returns:
        Un exemple de mémoire conforme au schéma.
    """
    # Créer un exemple de mémoire avec les champs requis
    memory = {
        "id": "memory_123456",
        "content": "Ceci est un exemple de contenu de mémoire.",
        "metadata": {
            "source": "exemple",
            "type": "document",
            "embedding_model": "openai/text-embedding-3-small",
            "doc_type": "markdown",
            "title": "Exemple de mémoire",
            "tags": ["exemple", "test"],
            "categories": ["documentation"],
            "author": "Système",
            "created_by": "validate_memory_schema.py",
            "chunk_info": {
                "chunk_id": "chunk_1",
                "chunk_index": 0,
                "total_chunks": 1,
                "chunk_size": 1000,
                "chunk_overlap": 200,
                "start_index": 0,
                "end_index": 1000
            },
            "file_info": {
                "file_path": "/path/to/file.md",
                "file_name": "file.md",
                "file_extension": ".md",
                "file_size": 1024,
                "file_modified_at": datetime.now().isoformat(),
                "file_created_at": datetime.now().isoformat()
            },
            "content_stats": {
                "char_count": 100,
                "word_count": 20,
                "line_count": 5
            }
        },
        "embedding": [0.1, 0.2, 0.3, 0.4, 0.5],
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
        "importance": 0.8,
        "version": 1
    }
    
    return memory


def validate_memory(memory, schema):
    """
    Valide qu'une mémoire est conforme au schéma.
    
    Args:
        memory: La mémoire à valider.
        schema: Le schéma JSON à utiliser.
        
    Returns:
        True si la mémoire est valide, False sinon.
    """
    try:
        validate(instance=memory, schema=schema)
        return True
    except jsonschema.exceptions.ValidationError as e:
        print(f"Erreur de validation de la mémoire: {e}")
        return False


def main():
    """
    Fonction principale.
    """
    parser = argparse.ArgumentParser(description="Valide le schéma de métadonnées des mémoires")
    parser.add_argument("--schema", help="Chemin vers le fichier de schéma", 
                        default="D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/projet/mcp/schemas/memory_schema.json")
    parser.add_argument("--memory", help="Chemin vers un fichier de mémoire à valider (optionnel)")
    parser.add_argument("--output", help="Chemin pour sauvegarder l'exemple de mémoire (optionnel)")
    
    args = parser.parse_args()
    
    # Charger le schéma
    schema = load_schema(args.schema)
    
    # Valider le schéma
    if validate_schema(schema):
        print("✅ Le schéma est valide")
    else:
        print("❌ Le schéma n'est pas valide")
        return
    
    # Créer un exemple de mémoire
    sample_memory = create_sample_memory(schema)
    
    # Valider l'exemple de mémoire
    if validate_memory(sample_memory, schema):
        print("✅ L'exemple de mémoire est valide")
    else:
        print("❌ L'exemple de mémoire n'est pas valide")
        return
    
    # Valider une mémoire fournie
    if args.memory:
        try:
            with open(args.memory, 'r', encoding='utf-8') as f:
                memory = json.load(f)
            
            if validate_memory(memory, schema):
                print(f"✅ La mémoire {args.memory} est valide")
            else:
                print(f"❌ La mémoire {args.memory} n'est pas valide")
        except Exception as e:
            print(f"Erreur lors du chargement de la mémoire: {e}")
    
    # Sauvegarder l'exemple de mémoire
    if args.output:
        try:
            with open(args.output, 'w', encoding='utf-8') as f:
                json.dump(sample_memory, f, indent=2, ensure_ascii=False)
            print(f"✅ Exemple de mémoire sauvegardé dans {args.output}")
        except Exception as e:
            print(f"Erreur lors de la sauvegarde de l'exemple de mémoire: {e}")


if __name__ == "__main__":
    main()
