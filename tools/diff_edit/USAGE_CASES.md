# Cas d’usage de la méthode diff Edit (v67)

## Checklist des cas d’usage

- Modification ciblée de contenu dans un fichier markdown (doc technique, notes, README)
- Patch de code source (Go, Python, JS, etc.) sur une ligne ou un bloc
- Mise à jour de fichiers de configuration (JSON, YAML, .env)
- Remplacement batch multi-fichiers d’un bloc commun (ex : copyright, header)
- Correction automatisée de documentation ou de code sur plusieurs fichiers
- Application de correctifs rapides sur des scripts ou des templates

## Exemples

| Type de fichier      | Exemple SEARCH           | Exemple REPLACE                | Remarque                        |
|----------------------|-------------------------|--------------------------------|---------------------------------|
| Markdown             | Ancien contenu          | Nouveau contenu                | Simple remplacement             |
| Code Go              | return a + b            | return a + b // modifié        | Avec contexte                   |
| Config JSON          | "key": "old"            | "key": "new"                   | Attention aux espaces           |
| Batch multi-fichiers | Bloc commun dans plusieurs fichiers | Bloc modifié         | Gérer les erreurs partielles    |
