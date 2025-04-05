# Documentation des scripts workflow

Ce document décrit l'organisation des scripts workflow et leur fonction.

## Delete

Ce dossier contient 4 script(s) pour delete les workflows.

### delete-all-workflows-auto.ps1

Script pour supprimer automatiquement tous les workflows existants dans n8n

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\delete-all-workflows-auto.ps1
```

### delete-all-workflows-force.ps1

Script pour supprimer tous les workflows existants dans n8n sans confirmation

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\delete-all-workflows-force.ps1
```

### delete-all-workflows-improved.ps1

Script amélioré pour supprimer les workflows dans n8n
 Basé sur la documentation officielle de l'API n8n

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\delete-all-workflows-improved.ps1
```

### delete-all-workflows.ps1

Script pour supprimer tous les workflows existants dans n8n

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\delete-all-workflows.ps1
```

## Fix

Ce dossier contient 4 script(s) pour fix les workflows.

### fix-encoding-simple.ps1

Script pour corriger l'encodage des caractères accentués dans les fichiers JSON

 Créer un répertoire pour les fichiers corrigés
$

**Exemple d'utilisation :**
```powershell
.\fix-encoding-simple.ps1
```

### fix-encoding-utf8.ps1

Script pour corriger l'encodage des fichiers JSON en UTF-8 avec BOM

 Créer un répertoire pour les fichiers corrigés
$

**Exemple d'utilisation :**
```powershell
.\fix-encoding-utf8.ps1
```

### fix-encoding.ps1

Script pour corriger l'encodage des caractères accentués dans les fichiers JSON
 Ce script remplace les séquences d'échappement Unicode par les caractères accentués correspondants

 Fonction pour remplacer les séquences d'échappement Unicode par les caractères accentués
f

**Exemple d'utilisation :**
```powershell
.\fix-encoding.ps1
```

### fix-workflow-names.ps1

Script pour corriger les noms des workflows en remplaçant les caractères accentués

 Créer un répertoire pour les fichiers corrigés
$

**Exemple d'utilisation :**
```powershell
.\fix-workflow-names.ps1
```

## Import

Ce dossier contient 10 script(s) pour import les workflows.

### import-fixed-all-workflows.ps1

Script pour importer les workflows corrigés dans n8n

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\import-fixed-all-workflows.ps1
```

### import-fixed-workflows.ps1

Script pour importer les workflows corrigés dans n8n

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\import-fixed-workflows.ps1
```

### import-no-accents-workflows.ps1

Script pour importer les workflows sans accents dans n8n

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\import-no-accents-workflows.ps1
```

### import-utf8-workflows.ps1

Script pour importer les workflows corrigés dans n8n

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\import-utf8-workflows.ps1
```

### import-workflows-auto.ps1

Script pour importer automatiquement les workflows n8n via l'API

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\import-workflows-auto.ps1
```

### import-workflows-final.ps1

Script pour importer automatiquement les workflows n8n via l'API (version finale)

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\import-workflows-final.ps1
```

### import-workflows-v2.ps1

Script pour importer automatiquement les workflows n8n via l'API (version 2)

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\import-workflows-v2.ps1
```

### import-workflows-v3.ps1

Script pour importer automatiquement les workflows n8n via l'API (version 3)

 Configuration
$

**Exemple d'utilisation :**
```powershell
.\import-workflows-v3.ps1
```

### import-workflows-with-token.ps1

Script pour importer les workflows n8n via l'API avec un jeton d'authentification

 Remplacez cette valeur par votre jeton d'authentification
$

**Exemple d'utilisation :**
```powershell
.\import-workflows-with-token.ps1
```

### import-workflows.ps1

Script pour importer les workflows n8n via l'API

 Fonction pour importer un workflow
f

**Exemple d'utilisation :**
```powershell
.\import-workflows.ps1
```

## Monitoring

Ce dossier contient 4 script(s) pour monitoring les workflows.

### check-workflow-fixed.ps1

Script simplifie pour verifier les resultats du workflow
 Version avec encodage corrige

W

**Exemple d'utilisation :**
```powershell
.\check-workflow-fixed.ps1
```

### check-workflow-results.ps1

Script pour verifier les resultats du workflow apres son execution

W

**Exemple d'utilisation :**
```powershell
.\check-workflow-results.ps1
```

### check-workflow-simple.ps1

Script simplifie pour verifier les resultats du workflow

W

**Exemple d'utilisation :**
```powershell
.\check-workflow-simple.ps1
```

### verify-mcp-status.ps1

Script pour verifier l'etat des MCP dans n8n

W

**Exemple d'utilisation :**
```powershell
.\verify-mcp-status.ps1
```

## Remove-accents

Ce dossier contient 0 script(s) pour remove accents les workflows.

Aucun script dans ce dossier.

## Testing

Ce dossier contient 1 script(s) pour testing les workflows.

### simulate-workflow-execution.ps1

Script pour simuler l'execution du workflow et verifier si les MCP fonctionnent correctement

W

**Exemple d'utilisation :**
```powershell
.\simulate-workflow-execution.ps1
```

## Utility

Ce dossier contient 0 script(s) pour utility les workflows.

Aucun script dans ce dossier.

## Validation

Ce dossier contient 5 script(s) pour validation les workflows.

### check_credentials.py

Vérifier si le nœud nécessite des credentials
        n

**Exemple d'utilisation :**
```bash
python check_credentials.py
```

### check_expressions.py

Trouve toutes les expressions dans un objet JSON

**Exemple d'utilisation :**
```bash
python check_expressions.py
```

### check_n8n_workflows.py

Créer un dictionnaire des nœuds par ID
    n

**Exemple d'utilisation :**
```bash
python check_n8n_workflows.py
```

### check_webhooks.py

Vérifier les nœuds Wait qui utilisent des webhooks
    f

**Exemple d'utilisation :**
```bash
python check_webhooks.py
```

### validate_json.py

Liste des fichiers à valider
    f

**Exemple d'utilisation :**
```bash
python validate_json.py
```

