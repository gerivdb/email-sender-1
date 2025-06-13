# Schémas de données pour le MCP

Ce répertoire contient les schémas de données utilisés par le MCP (Model Context Protocol).

## Schéma des mémoires

Le fichier `memory_schema.json` définit le schéma pour les mémoires du système MCP. Ce schéma est utilisé pour valider les données avant leur stockage dans la base de données vectorielle.

### Structure principale

```json
{
  "id": "string",           // Identifiant unique de la mémoire
  "content": "string",      // Contenu textuel de la mémoire
  "metadata": { ... },      // Métadonnées associées à la mémoire
  "embedding": [number],    // Embedding vectoriel de la mémoire
  "created_at": "string",   // Date de création (format ISO)
  "updated_at": "string",   // Date de mise à jour (format ISO)
  "expires_at": "string",   // Date d'expiration (optionnelle)
  "ttl": number,            // Durée de vie en secondes (optionnelle)
  "importance": number,     // Importance (0-1)
  "relevance_score": number, // Score de pertinence (0-1)
  "related_memories": ["string"], // Identifiants des mémoires liées
  "version": number         // Version de la mémoire
}
```plaintext
### Métadonnées

Les métadonnées sont structurées pour permettre une recherche et un filtrage efficaces :

```json
"metadata": {
  "source": "string",       // Source de la mémoire
  "type": "string",         // Type de mémoire (document, conversation, code, etc.)
  "embedding_model": "string", // Modèle utilisé pour l'embedding
  "doc_type": "string",     // Type de document (markdown, python, etc.)
  "title": "string",        // Titre de la mémoire
  "tags": ["string"],       // Tags associés
  "categories": ["string"], // Catégories associées
  "author": "string",       // Auteur
  "created_by": "string",   // Créateur (utilisateur ou processus)
  "modified_by": "string",  // Dernier modificateur
  "parent_id": "string",    // ID de la mémoire parente
  "chunk_info": { ... },    // Informations sur le chunking
  "file_info": { ... },     // Informations sur le fichier source
  "code_info": { ... },     // Informations spécifiques au code
  "roadmap_info": { ... },  // Informations spécifiques aux roadmaps
  "content_stats": { ... }, // Statistiques sur le contenu
  "custom_metadata": { ... } // Métadonnées personnalisées
}
```plaintext
### Types de mémoires

Le système supporte différents types de mémoires, chacun avec des métadonnées spécifiques :

- **document** : Documents textuels (markdown, texte, etc.)
- **conversation** : Conversations avec l'utilisateur
- **code** : Extraits de code source
- **task** : Tâches à accomplir
- **roadmap** : Plans de développement
- **system** : Informations système
- **user_preference** : Préférences utilisateur
- **custom** : Type personnalisé

### Validation

Pour valider une mémoire par rapport au schéma, utilisez le script `validate_memory_schema.py` :

```bash
python validate_memory_schema.py --schema path/to/memory_schema.json --memory path/to/memory.json
```plaintext
Pour générer un exemple de mémoire valide :

```bash
python validate_memory_schema.py --output path/to/output.json
```plaintext
## Utilisation avec Qdrant

Le schéma est compatible avec Qdrant pour le stockage vectoriel. Les champs importants pour Qdrant sont :

- `id` : Identifiant unique de la mémoire
- `embedding` : Vecteur d'embedding pour la recherche sémantique
- `metadata` : Stocké comme payload pour le filtrage et la récupération

## Bonnes pratiques

1. **Identifiants** : Utilisez des identifiants uniques et prévisibles pour faciliter la récupération
2. **Embeddings** : Normalisez les vecteurs d'embedding pour optimiser la recherche par similarité
3. **Métadonnées** : Incluez des métadonnées riches pour améliorer le filtrage et la recherche
4. **TTL** : Utilisez `expires_at` ou `ttl` pour les mémoires temporaires
5. **Chunking** : Pour les documents longs, utilisez `chunk_info` pour suivre la relation entre les chunks
