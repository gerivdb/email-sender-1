# Contraintes d’encodage, de format et de compatibilité (diff Edit)

- **Encodage recommandé** : UTF-8 sans BOM (Byte Order Mark)
- **Compatibilité** :
  - Gérer les fins de ligne CRLF (Windows) et LF (Linux/Mac)
  - Toujours détecter et préserver le format de fin de ligne du fichier d’origine
- **Fichiers supportés** :
  - Texte : .md, .go, .py, .js, .json, .yaml, .env, etc.
  - Fichiers binaires : non supportés (le script doit refuser ou ignorer)
- **Recherche du bloc SEARCH** :
  - Correspondance stricte (y compris espaces, indentation, retours à la ligne)
  - Vérifier l’unicité du bloc SEARCH dans le fichier avant remplacement
- **Sécurité** :
  - Toujours générer un backup du fichier avant modification
  - Option dry-run pour prévisualiser le diff sans appliquer
- **Rollback** :
  - Permettre la restauration facile à partir du backup
- **Multi-plateforme** :
  - Compatible Windows, Linux, Mac (Python recommandé)

## Bonnes pratiques

- Inclure 1-2 lignes de contexte dans le bloc SEARCH pour fiabiliser le patch
- Vérifier l’encodage du fichier avant modification
- Ne jamais appliquer sur des fichiers binaires ou volumineux sans précaution
