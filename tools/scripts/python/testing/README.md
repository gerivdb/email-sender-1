# TestOmnibus

TestOmnibus est un outil d'exécution et d'analyse rapide des tests Python. Il permet d'exécuter les tests Python, d'analyser les erreurs, et de générer des rapports détaillés pour faciliter le débogage.

## Fonctionnalités

- **Exécution des tests**
  - Exécution parallèle des tests avec pytest
  - Support des patterns de test avancés
  - Intégration avec pytest-testmon pour exécuter uniquement les tests affectés
  - Support du débogage interactif avec pdb

- **Analyse des erreurs**
  - Détection des patterns d'erreur
  - Analyse des tendances d'erreurs au fil du temps
  - Visualisation des erreurs avec des graphiques

- **Rapports**
  - Génération de rapports HTML détaillés
  - Génération de rapports de couverture de code
  - Intégration avec Allure pour des rapports interactifs
  - Génération de rapports JUnit pour Jenkins

- **Intégration**
  - Sauvegarde des erreurs dans une base de données
  - Intégration avec le système d'apprentissage des erreurs
  - Intégration avec Jenkins pour l'intégration continue
  - Intégration avec Allure pour des rapports avancés

## Prérequis

- Python 3.6+
- pytest
- pytest-cov (pour la couverture de code)
- pytest-xdist (pour l'exécution parallèle)
- pytest-testmon (optionnel, pour l'exécution des tests affectés)
- allure-pytest (optionnel, pour les rapports Allure)
- Allure (optionnel, pour générer les rapports Allure)

## Installation

```powershell
# Installer les dépendances de base
python -m pip install pytest pytest-cov pytest-xdist pytest-testmon

# Installer les dépendances pour Allure (optionnel)
python -m pip install allure-pytest

# Installer Allure avec Scoop (Windows, optionnel)
scoop install allure

# Ou installer Allure avec Homebrew (macOS, optionnel)
# brew install allure
```

## Utilisation

### Utilisation directe du script Python

```bash
# Exécuter tous les tests dans le répertoire tests/python
python run_testomnibus.py -d tests/python

# Exécuter les tests avec des options avancées
python run_testomnibus.py -d tests/python -p "test_*.py" -j 4 -v --analyze --report --report-dir reports

# Exécuter les tests avec Allure
python run_testomnibus.py -d tests/python --allure --allure-dir allure-results

# Exécuter les tests avec Jenkins
python run_testomnibus.py -d tests/python --jenkins --jenkins-dir jenkins-results

# Exécuter les tests avec toutes les options
python run_testomnibus.py -d tests/python -p "test_*.py" -j 4 -v --analyze --report --cov --allure --jenkins
```

### Utilisation du wrapper PowerShell

```powershell
# Exécuter tous les tests dans le répertoire tests/python
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python

# Exécuter les tests avec des options avancées
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -Pattern "test_*.py" -Jobs 4 -VerboseOutput -Analyze -GenerateReport -ReportDirectory reports

# Exécuter les tests avec Allure
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -GenerateAllureReport -AllureDirectory allure-results -OpenAllureReport

# Exécuter les tests avec Jenkins
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -GenerateJenkinsReport -JenkinsDirectory jenkins-results

# Exécuter les tests avec toutes les options
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -Pattern "test_*.py" -Jobs 4 -VerboseOutput -Analyze -GenerateReport -GenerateCoverage -GenerateAllureReport -GenerateJenkinsReport -InstallDependencies -OpenReport
```

## Options disponibles

### Options du script Python

```
usage: run_testomnibus.py [-h] [-d DIRECTORY] [-p PATTERN] [-j JOBS] [-v] [--pdb]
                         [--report] [--report-dir REPORT_DIR] [--analyze]
                         [--save-errors] [--error-db ERROR_DB] [--testmon]
                         [--cov] [--cov-report COV_REPORT] [--tb TB]
                         [--allure] [--allure-dir ALLURE_DIR] [--jenkins]
                         [--jenkins-dir JENKINS_DIR]

TestOmnibus - Exécution et analyse des tests Python

options:
  -h, --help            affiche ce message d'aide et quitte
  -d DIRECTORY, --directory DIRECTORY
                        Répertoire des tests (défaut: tests)
  -p PATTERN, --pattern PATTERN
                        Pattern des fichiers de test (défaut: test_*.py)
  -j JOBS, --jobs JOBS  Nombre de processus parallèles (défaut: nombre de cœurs)
  -v, --verbose         Mode verbeux
  --pdb                 Lancer pdb en cas d'échec
  --report              Générer un rapport HTML
  --report-dir REPORT_DIR
                        Répertoire des rapports (défaut: test_reports)
  --analyze             Analyser les erreurs
  --save-errors         Sauvegarder les erreurs dans la base de données
  --error-db ERROR_DB   Chemin de la base de données d'erreurs (défaut: error_database.json)
  --testmon             Utiliser pytest-testmon pour exécuter uniquement les tests affectés
  --cov                 Générer un rapport de couverture
  --cov-report COV_REPORT
                        Format du rapport de couverture (html, xml, term) (défaut: html)
  --tb TB               Format des tracebacks (auto, short, long, native) (défaut: auto)
  --allure              Générer un rapport Allure
  --allure-dir ALLURE_DIR
                        Répertoire des résultats Allure (défaut: allure-results)
  --jenkins             Générer un rapport JUnit pour Jenkins
  --jenkins-dir JENKINS_DIR
                        Répertoire des résultats Jenkins (défaut: jenkins-results)
```

### Options du wrapper PowerShell

```powershell
.\Invoke-TestOmnibus.ps1
    [-TestDirectory <string>]           # Répertoire des tests (défaut: tests/python)
    [-Pattern <string>]                 # Pattern des fichiers de test (défaut: test_*.py)
    [-Jobs <int>]                       # Nombre de processus parallèles (défaut: nombre de cœurs)
    [-VerboseOutput]                    # Mode verbeux
    [-Pdb]                              # Lancer pdb en cas d'échec
    [-GenerateReport]                   # Générer un rapport HTML
    [-ReportDirectory <string>]         # Répertoire des rapports (défaut: test_reports)
    [-Analyze]                          # Analyser les erreurs
    [-SaveErrors]                       # Sauvegarder les erreurs dans la base de données
    [-ErrorDatabase <string>]           # Chemin de la base de données d'erreurs (défaut: error_database.json)
    [-UseTestmon]                       # Utiliser pytest-testmon pour exécuter uniquement les tests affectés
    [-GenerateCoverage]                 # Générer un rapport de couverture
    [-CoverageFormat <string>]          # Format du rapport de couverture (html, xml, term) (défaut: html)
    [-TracebackFormat <string>]         # Format des tracebacks (auto, short, long, native) (défaut: auto)
    [-InstallDependencies]              # Installer automatiquement les dépendances nécessaires
    [-OpenReport]                       # Ouvrir le rapport HTML après sa génération
    [-GenerateAllureReport]             # Générer un rapport Allure
    [-AllureDirectory <string>]         # Répertoire des résultats Allure (défaut: allure-results)
    [-GenerateJenkinsReport]            # Générer un rapport JUnit pour Jenkins
    [-JenkinsDirectory <string>]        # Répertoire des résultats Jenkins (défaut: jenkins-results)
    [-OpenAllureReport]                 # Ouvrir le rapport Allure après sa génération
```

## Exemples d'utilisation

### Exécution simple

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python
```

### Exécution avec génération de rapport

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -GenerateReport -OpenReport
```

### Exécution avec analyse des erreurs

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -Analyze -SaveErrors
```

### Exécution avec couverture de code

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -GenerateCoverage -CoverageFormat html
```

### Exécution des tests affectés uniquement

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -UseTestmon
```

### Exécution en mode débogage

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -Pdb
```

### Exécution avec Allure

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -GenerateAllureReport -OpenAllureReport
```

### Exécution avec Jenkins

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -GenerateJenkinsReport
```

### Intégration avec Allure

```powershell
.\Integrate-Allure.ps1 -TestDirectory tests/python -OpenReport -InstallAllure
```

### Intégration avec Jenkins

```powershell
.\Integrate-Jenkins.ps1 -TestDirectory tests/python -JenkinsUrl "http://jenkins.example.com" -JenkinsJob "python-tests" -JenkinsToken "token" -JenkinsUser "user"
```

## Intégration avec le système d'apprentissage des erreurs

TestOmnibus peut être intégré avec votre système d'apprentissage des erreurs existant en utilisant l'option `--save-errors` (ou `-SaveErrors` en PowerShell). Cette option sauvegarde les erreurs détectées dans une base de données JSON qui peut être utilisée pour analyser les patterns d'erreur et suggérer des corrections.

La base de données d'erreurs est structurée comme suit :

```json
{
  "errors": [
    {
      "signature": "AssertionError: 1 + 1 devrait être égal à 2, pas à 3",
      "type": "AssertionError",
      "message": "1 + 1 devrait être égal à 2, pas à 3",
      "files": ["tests/python/test_example.py"],
      "first_seen": "2025-04-11T10:15:30.123456",
      "last_seen": "2025-04-11T10:15:30.123456",
      "occurrences": 1,
      "resolved": false
    }
  ],
  "history": [
    {
      "timestamp": "2025-04-11T10:15:30.123456",
      "total_tests": 10,
      "passed_tests": 7,
      "failed_tests": 3,
      "error_count": 1
    }
  ]
}
```

## Personnalisation

Vous pouvez personnaliser TestOmnibus en modifiant les fichiers suivants :

- `run_testomnibus.py` : Script principal Python
- `Invoke-TestOmnibus.ps1` : Wrapper PowerShell

## Intégration avec CI/CD

TestOmnibus peut être facilement intégré dans votre pipeline CI/CD. Voici des exemples d'utilisation :

### GitHub Actions

```yaml
name: Tests Python

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        python -m pip install pytest pytest-cov pytest-xdist allure-pytest

    - name: Install Allure
      run: |
        Invoke-WebRequest -Uri "https://github.com/allure-framework/allure2/releases/download/2.24.0/allure-2.24.0.zip" -OutFile "allure.zip"
        Expand-Archive -Path "allure.zip" -DestinationPath "allure"
        echo "$PWD/allure/allure-2.24.0/bin" | Out-File -FilePath $env:GITHUB_PATH -Append

    - name: Run TestOmnibus
      shell: pwsh
      run: |
        .\scripts\python\testing\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -GenerateReport -Analyze -GenerateCoverage -GenerateAllureReport -GenerateJenkinsReport

    - name: Upload test report
      uses: actions/upload-artifact@v3
      with:
        name: test-report
        path: test_reports/

    - name: Upload Allure results
      uses: actions/upload-artifact@v3
      with:
        name: allure-results
        path: allure-results/

    - name: Upload Jenkins results
      uses: actions/upload-artifact@v3
      with:
        name: jenkins-results
        path: jenkins-results/
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Python') {
            steps {
                bat 'python -m pip install --upgrade pip'
                bat 'python -m pip install pytest pytest-cov pytest-xdist allure-pytest'
            }
        }

        stage('Run Tests') {
            steps {
                powershell '.\scripts\python\testing\Invoke-TestOmnibus.ps1 -TestDirectory tests/python -GenerateReport -Analyze -GenerateCoverage -GenerateJenkinsReport'
            }
        }

        stage('Publish Results') {
            steps {
                junit 'jenkins-results/*.xml'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'test_reports',
                    reportFiles: 'testomnibus_report_*.html',
                    reportName: 'TestOmnibus Report'
                ])
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'test_reports/*, jenkins-results/*', allowEmptyArchive: true
        }
    }
}
```
