# Guide de gestion des caractères accentués français dans n8n

Ce guide explique comment résoudre les problèmes d'encodage des caractères accentués français dans les workflows n8n.

## Problématique

Les workflows n8n peuvent rencontrer des problèmes avec les caractères accentués français (é, è, à, ê, etc.) lors de l'importation. Ces caractères sont souvent mal encodés et apparaissent comme des symboles incorrects (�) dans les noms des workflows et des nœuds, ainsi que dans le contenu des workflows.

## Solutions

### 1. Correction des caractères accentués

Le script `fix_all_workflows.py` remplace les caractères accentués par leurs équivalents non accentués dans les fichiers JSON des workflows.

```bash
python fix_all_workflows.py
```

Ce script :
- Lit tous les fichiers JSON dans le répertoire "workflows"
- Remplace les caractères accentués par leurs équivalents non accentués
- Sauvegarde les fichiers corrigés dans le répertoire "workflows-fixed-all"

### 2. Importation des workflows corrigés

Le script `import-fixed-all-workflows.ps1` utilise l'API n8n pour importer les workflows avec les caractères corrigés.

```powershell
.\import-fixed-all-workflows.ps1
```

Ce script :
- Se connecte à l'API n8n
- Importe tous les workflows corrigés du répertoire "workflows-fixed-all"
- Affiche un rapport détaillé des importations réussies et échouées

### 3. Suppression des doublons et des workflows mal encodés

Le script `remove-duplicate-workflows.ps1` identifie et supprime les workflows en double ou mal encodés dans n8n.

```powershell
.\remove-duplicate-workflows.ps1
```

Ce script :
- Récupère tous les workflows existants dans n8n
- Identifie les doublons et les workflows avec des caractères mal encodés
- Demande confirmation avant de les supprimer
- Supprime les workflows sélectionnés

## Autres scripts utiles

### Liste des workflows

Le script `list-workflows.ps1` liste les workflows existants dans n8n.

```powershell
.\list-workflows.ps1
```

### Suppression de tous les workflows

Le script `delete-all-workflows-auto.ps1` supprime tous les workflows existants sans confirmation.

```powershell
.\delete-all-workflows-auto.ps1
```

⚠️ **Attention** : Ce script supprime tous les workflows sans confirmation. Utilisez-le avec précaution.

## Processus recommandé

1. Sauvegardez vos workflows existants
2. Exécutez `fix_all_workflows.py` pour corriger l'encodage des caractères
3. Supprimez les workflows existants dans n8n (manuellement ou avec `delete-all-workflows-auto.ps1`)
4. Importez les workflows corrigés avec `import-fixed-all-workflows.ps1`
5. Vérifiez que les workflows importés fonctionnent correctement

## Limitations connues

- L'API n8n ne gère pas correctement les caractères accentués lors de l'importation
- Certains fichiers JSON complexes peuvent nécessiter une correction manuelle avant l'importation
- L'importation via l'interface utilisateur peut être plus fiable pour les fichiers problématiques

## Exemples de caractères problématiques et leurs remplacements

| Caractère accentué | Remplacement |
|-------------------|--------------|
| é | e |
| è | e |
| ê | e |
| ë | e |
| à | a |
| â | a |
| ä | a |
| ç | c |
| î | i |
| ï | i |
| ô | o |
| ö | o |
| ù | u |
| û | u |
| ü | u |
| ÿ | y |

## Dépannage

### Problème : Les caractères accentués sont toujours mal encodés après l'importation

**Solution** : Essayez d'importer les workflows manuellement via l'interface utilisateur de n8n. L'API n8n peut avoir des limitations dans la gestion des caractères accentués.

### Problème : Erreur lors de l'importation d'un workflow

**Solution** : Vérifiez le format JSON du fichier. Certains fichiers JSON complexes peuvent nécessiter une correction manuelle avant l'importation.

### Problème : Les scripts PowerShell ne fonctionnent pas correctement

**Solution** : Assurez-vous que PowerShell est configuré pour utiliser l'encodage UTF-8. Vous pouvez définir l'encodage avec la commande suivante :

```powershell
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

## Ressources additionnelles

- [Documentation n8n sur l'importation de workflows](https://docs.n8n.io/workflows/workflows/)
- [Documentation Python sur l'encodage des caractères](https://docs.python.org/3/howto/unicode.html)
- [Documentation PowerShell sur l'encodage des caractères](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding)
