# Guide d'installation du système de journal de bord RAG

Ce guide détaille les étapes pour installer et configurer le système de journal de bord RAG.

## Prérequis

Avant de commencer l'installation, assurez-vous que votre système dispose des éléments suivants:

- **Windows 10/11**: Le système est conçu pour fonctionner sur Windows
- **Python 3.8+**: Les scripts sont développés en Python 3.8 ou supérieur
- **Git**: Nécessaire pour l'intégration GitHub
- **PowerShell 5.1+**: Les scripts d'automatisation sont écrits en PowerShell
- **Droits d'administrateur**: Certaines fonctionnalités (tâches planifiées) nécessitent des droits d'administrateur

## Installation rapide

Pour une installation rapide, exécutez le script d'installation principal:

```powershell
.\install-journal-system.ps1
```

Ce script installera toutes les dépendances nécessaires et configurera les répertoires requis.

## Installation manuelle

Si vous préférez une installation manuelle, suivez les étapes ci-dessous.

### 1. Cloner le dépôt

Si ce n'est pas déjà fait, clonez le dépôt:

```powershell
git clone https://github.com/votre-utilisateur/votre-repo.git
cd votre-repo
```

### 2. Installer les dépendances Python

Installez les dépendances Python nécessaires:

```powershell
# Dépendances de base
pip install requests python-dotenv

# Dépendances pour l'analyse
pip install numpy pandas matplotlib wordcloud scikit-learn

# Dépendances pour l'application web
pip install fastapi uvicorn
```

### 3. Créer les répertoires nécessaires

Créez les répertoires nécessaires pour le système:

```powershell
# Répertoires du journal
mkdir -Force projet/documentation\journal_de_bord\entries
mkdir -Force projet/documentation\journal_de_bord\analysis
mkdir -Force projet/documentation\journal_de_bord\github
mkdir -Force projet/documentation\journal_de_bord\rag

# Répertoires de documentation
mkdir -Force projet/documentation\documentation\technique
mkdir -Force projet/documentation\documentation\workflow
mkdir -Force projet/documentation\documentation\api
mkdir -Force projet/documentation\documentation\journal_insights
```

### 4. Configurer l'intégration GitHub (optionnel)

Si vous souhaitez utiliser l'intégration GitHub, configurez-la:

```powershell
.\development\scripts\cmd\setup-github-integration.ps1
```

Ce script vous demandera:
- Votre token GitHub
- Le nom du propriétaire du dépôt
- Le nom du dépôt

Ces informations seront stockées dans un fichier `.env` à la racine du projet.

### 5. Exécuter les analyses initiales (optionnel)

Si vous souhaitez générer les analyses initiales:

```powershell
.\development\scripts\cmd\setup-journal-analysis.ps1
```

### 6. Configurer les tâches planifiées (optionnel, nécessite des droits d'administrateur)

Si vous souhaitez configurer les tâches planifiées pour l'automatisation:

```powershell
.\development\scripts\cmd\setup-journal-tasks.ps1
.\development\scripts\cmd\setup-journal-sync-task.ps1
```

## Structure des répertoires après installation

Après l'installation, votre projet devrait avoir la structure suivante:

```
.
├── .augment/
│   └── memories/
│       └── journal_memories.json
├── .env                           # Configuration GitHub (si configurée)
├── .git/
│   └── hooks/
│       └── pre-commit             # Hook Git pre-commit (si configuré)
├── projet/documentation/
│   ├── documentation/             # Documentation du système
│   └── journal_de_bord/
│       ├── analysis/              # Résultats des analyses
│       ├── entries/               # Entrées du journal
│       ├── github/                # Données d'intégration GitHub
│       └── rag/                   # Données du système RAG
├── development/scripts/
│   ├── cmd/                       # Scripts PowerShell
│   └── python/
│       └── journal/               # Scripts Python
│           ├── web_routes/        # Routes de l'API web
│           ├── github_integration.py
│           ├── journal_analyzer.py
│           ├── journal_entry.py
│           ├── journal_rag_simple.py
│           ├── journal_search_simple.py
│           └── web_app.py
└── install-journal-system.ps1     # Script d'installation principal
```

## Vérification de l'installation

Pour vérifier que l'installation a réussi, vous pouvez:

1. Créer une entrée de journal:
   ```powershell
   python scripts\python\journal\journal_entry.py "Test d'installation" --tags test installation
   ```

2. Rechercher dans le journal:
   ```powershell
   python scripts\python\journal\journal_search_simple.py --query "installation"
   ```

3. Démarrer l'application web:
   ```powershell
   .\development\scripts\cmd\start-journal-web.ps1
   ```
   Puis accéder à http://localhost:8000 dans votre navigateur.

## Dépannage

### Problèmes d'installation des dépendances Python

Si vous rencontrez des problèmes lors de l'installation des dépendances Python:

```powershell
# Mettre à jour pip
python -m pip install --upgrade pip

# Installer les dépendances une par une
pip install requests
pip install python-dotenv
# etc.
```

### Problèmes de permissions

Si vous rencontrez des problèmes de permissions:

1. Exécutez PowerShell en tant qu'administrateur
2. Vérifiez la politique d'exécution PowerShell:
   ```powershell
   Get-ExecutionPolicy
   ```
   Si elle est restrictive, vous pouvez la modifier temporairement:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

### Problèmes d'encodage

Si vous rencontrez des problèmes d'encodage avec les caractères accentués:

1. Vérifiez que tous les fichiers sont encodés en UTF-8
2. Utilisez l'accent grave (`) comme caractère d'échappement pour les apostrophes dans PowerShell

## Installation pour le développement

Si vous souhaitez contribuer au développement du système:

1. Créez un environnement virtuel Python:
   ```powershell
   python -m venv venv
   .\venv\Scripts\Activate.ps1
   ```

2. Installez les dépendances de développement:
   ```powershell
   pip install -r requirements-dev.txt
   ```

3. Configurez les hooks Git de pré-commit:
   ```powershell
   pre-commit install
   ```

## Mise à jour

Pour mettre à jour le système:

1. Tirez les dernières modifications:
   ```powershell
   git pull
   ```

2. Mettez à jour les dépendances:
   ```powershell
   pip install -r requirements.txt
   ```

3. Exécutez le script d'installation:
   ```powershell
   .\install-journal-system.ps1
   ```

## Désinstallation

Pour désinstaller le système:

1. Supprimez les tâches planifiées (si configurées):
   ```powershell
   schtasks /delete /tn "Journal_Daily" /f
   schtasks /delete /tn "Journal_Weekly" /f
   schtasks /delete /tn "Journal_Sync" /f
   ```

2. Supprimez le hook Git pre-commit (si configuré):
   ```powershell
   rm .git\hooks\pre-commit
   rm .git\hooks\pre-commit.bat
   ```

3. Supprimez les répertoires créés:
   ```powershell
   rm -r projet/documentation\journal_de_bord
   rm -r projet/documentation\documentation
   rm -r .augment\memories\journal_memories.json
   ```

4. Désinstallez les dépendances Python (optionnel):
   ```powershell
   pip uninstall -r requirements.txt -y
   ```
