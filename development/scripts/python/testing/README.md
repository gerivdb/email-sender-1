# TestOmnibus

TestOmnibus est un outil d'exÃ©cution et d'analyse rapide des tests Python. Il permet d'exÃ©cuter les tests Python, d'analyser les erreurs, et de gÃ©nÃ©rer des rapports dÃ©taillÃ©s pour faciliter le dÃ©bogage.

## FonctionnalitÃ©s

- **ExÃ©cution des tests**
  - ExÃ©cution parallÃ¨le des tests avec pytest
  - Support des patterns de test avancÃ©s
  - IntÃ©gration avec pytest-testmon pour exÃ©cuter uniquement les tests affectÃ©s
  - Support du dÃ©bogage interactif avec pdb

- **Analyse des erreurs**
  - DÃ©tection des patterns d'erreur
  - Analyse des tendances d'erreurs au fil du temps
  - Visualisation des erreurs avec des graphiques

- **Rapports**
  - GÃ©nÃ©ration de rapports HTML dÃ©taillÃ©s
  - GÃ©nÃ©ration de rapports de couverture de code
  - IntÃ©gration avec Allure pour des rapports interactifs
  - GÃ©nÃ©ration de rapports JUnit pour Jenkins

- **IntÃ©gration**
  - Sauvegarde des erreurs dans une base de donnÃ©es
  - IntÃ©gration avec le systÃ¨me d'apprentissage des erreurs
  - IntÃ©gration avec Jenkins pour l'intÃ©gration continue
  - IntÃ©gration avec Allure pour des rapports avancÃ©s

## PrÃ©requis

- Python 3.6+
- pytest
- pytest-cov (pour la couverture de code)
- pytest-xdist (pour l'exÃ©cution parallÃ¨le)
- pytest-testmon (optionnel, pour l'exÃ©cution des tests affectÃ©s)
- allure-pytest (optionnel, pour les rapports Allure)
- Allure (optionnel, pour gÃ©nÃ©rer les rapports Allure)

## Installation

```powershell
# Installer les dÃ©pendances de base

python -m pip install pytest pytest-cov pytest-xdist pytest-testmon

# Installer les dÃ©pendances pour Allure (optionnel)

python -m pip install allure-pytest

# Installer Allure avec Scoop (Windows, optionnel)

scoop install allure

# Ou installer Allure avec Homebrew (macOS, optionnel)

# brew install allure

```plaintext
## Utilisation

### Utilisation directe du script Python

```bash
# ExÃ©cuter tous les tests dans le rÃ©pertoire development/testing/tests/python

python run_testomnibus.py -d development/testing/tests/python

# ExÃ©cuter les tests avec des options avancÃ©es

python run_testomnibus.py -d development/testing/tests/python -p "test_*.py" -j 4 -v --analyze --report --report-dir reports

# ExÃ©cuter les tests avec Allure

python run_testomnibus.py -d development/testing/tests/python --allure --allure-dir allure-results

# ExÃ©cuter les tests avec Jenkins

python run_testomnibus.py -d development/testing/tests/python --jenkins --jenkins-dir jenkins-results

# ExÃ©cuter les tests avec toutes les options

python run_testomnibus.py -d development/testing/tests/python -p "test_*.py" -j 4 -v --analyze --report --cov --allure --jenkins
```plaintext
### Utilisation du wrapper PowerShell

```powershell
# ExÃ©cuter tous les tests dans le rÃ©pertoire development/testing/tests/python

.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python

# ExÃ©cuter les tests avec des options avancÃ©es

.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -Pattern "test_*.py" -Jobs 4 -VerboseOutput -Analyze -GenerateReport -ReportDirectory reports

# ExÃ©cuter les tests avec Allure

.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -GenerateAllureReport -AllureDirectory allure-results -OpenAllureReport

# ExÃ©cuter les tests avec Jenkins

.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -GenerateJenkinsReport -JenkinsDirectory jenkins-results

# ExÃ©cuter les tests avec toutes les options

.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -Pattern "test_*.py" -Jobs 4 -VerboseOutput -Analyze -GenerateReport -GenerateCoverage -GenerateAllureReport -GenerateJenkinsReport -InstallDependencies -OpenReport
```plaintext
## Options disponibles

### Options du script Python

```plaintext
usage: run_testomnibus.py [-h] [-d DIRECTORY] [-p PATTERN] [-j JOBS] [-v] [--pdb]
                         [--report] [--report-dir REPORT_DIR] [--analyze]
                         [--save-errors] [--error-db ERROR_DB] [--testmon]
                         [--cov] [--cov-report COV_REPORT] [--tb TB]
                         [--allure] [--allure-dir ALLURE_DIR] [--jenkins]
                         [--jenkins-dir JENKINS_DIR]

TestOmnibus - ExÃ©cution et analyse des tests Python

options:
  -h, --help            affiche ce message d'aide et quitte
  -d DIRECTORY, --directory DIRECTORY
                        RÃ©pertoire des tests (dÃ©faut: tests)
  -p PATTERN, --pattern PATTERN
                        Pattern des fichiers de test (dÃ©faut: test_*.py)
  -j JOBS, --jobs JOBS  Nombre de processus parallÃ¨les (dÃ©faut: nombre de cÅ“urs)
  -v, --verbose         Mode verbeux
  --pdb                 Lancer pdb en cas d'Ã©chec
  --report              GÃ©nÃ©rer un rapport HTML
  --report-dir REPORT_DIR
                        RÃ©pertoire des rapports (dÃ©faut: test_reports)
  --analyze             Analyser les erreurs
  --save-errors         Sauvegarder les erreurs dans la base de donnÃ©es
  --error-db ERROR_DB   Chemin de la base de donnÃ©es d'erreurs (dÃ©faut: error_database.json)
  --testmon             Utiliser pytest-testmon pour exÃ©cuter uniquement les tests affectÃ©s
  --cov                 GÃ©nÃ©rer un rapport de couverture
  --cov-report COV_REPORT
                        Format du rapport de couverture (html, xml, term) (dÃ©faut: html)
  --tb TB               Format des tracebacks (auto, short, long, native) (dÃ©faut: auto)
  --allure              GÃ©nÃ©rer un rapport Allure
  --allure-dir ALLURE_DIR
                        RÃ©pertoire des rÃ©sultats Allure (dÃ©faut: allure-results)
  --jenkins             GÃ©nÃ©rer un rapport JUnit pour Jenkins
  --jenkins-dir JENKINS_DIR
                        RÃ©pertoire des rÃ©sultats Jenkins (dÃ©faut: jenkins-results)
```plaintext
### Options du wrapper PowerShell

```powershell
.\Invoke-TestOmnibus.ps1
    [-TestDirectory <string>]           # RÃ©pertoire des tests (dÃ©faut: development/testing/tests/python)

    [-Pattern <string>]                 # Pattern des fichiers de test (dÃ©faut: test_*.py)

    [-Jobs <int>]                       # Nombre de processus parallÃ¨les (dÃ©faut: nombre de cÅ“urs)

    [-VerboseOutput]                    # Mode verbeux

    [-Pdb]                              # Lancer pdb en cas d'Ã©chec

    [-GenerateReport]                   # GÃ©nÃ©rer un rapport HTML

    [-ReportDirectory <string>]         # RÃ©pertoire des rapports (dÃ©faut: test_reports)

    [-Analyze]                          # Analyser les erreurs

    [-SaveErrors]                       # Sauvegarder les erreurs dans la base de donnÃ©es

    [-ErrorDatabase <string>]           # Chemin de la base de donnÃ©es d'erreurs (dÃ©faut: error_database.json)

    [-UseTestmon]                       # Utiliser pytest-testmon pour exÃ©cuter uniquement les tests affectÃ©s

    [-GenerateCoverage]                 # GÃ©nÃ©rer un rapport de couverture

    [-CoverageFormat <string>]          # Format du rapport de couverture (html, xml, term) (dÃ©faut: html)

    [-TracebackFormat <string>]         # Format des tracebacks (auto, short, long, native) (dÃ©faut: auto)

    [-InstallDependencies]              # Installer automatiquement les dÃ©pendances nÃ©cessaires

    [-OpenReport]                       # Ouvrir le rapport HTML aprÃ¨s sa gÃ©nÃ©ration

    [-GenerateAllureReport]             # GÃ©nÃ©rer un rapport Allure

    [-AllureDirectory <string>]         # RÃ©pertoire des rÃ©sultats Allure (dÃ©faut: allure-results)

    [-GenerateJenkinsReport]            # GÃ©nÃ©rer un rapport JUnit pour Jenkins

    [-JenkinsDirectory <string>]        # RÃ©pertoire des rÃ©sultats Jenkins (dÃ©faut: jenkins-results)

    [-OpenAllureReport]                 # Ouvrir le rapport Allure aprÃ¨s sa gÃ©nÃ©ration

```plaintext
## Exemples d'utilisation

### ExÃ©cution simple

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python
```plaintext
### ExÃ©cution avec gÃ©nÃ©ration de rapport

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -GenerateReport -OpenReport
```plaintext
### ExÃ©cution avec analyse des erreurs

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -Analyze -SaveErrors
```plaintext
### ExÃ©cution avec couverture de code

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -GenerateCoverage -CoverageFormat html
```plaintext
### ExÃ©cution des tests affectÃ©s uniquement

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -UseTestmon
```plaintext
### ExÃ©cution en mode dÃ©bogage

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -Pdb
```plaintext
### ExÃ©cution avec Allure

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -GenerateAllureReport -OpenAllureReport
```plaintext
### ExÃ©cution avec Jenkins

```powershell
.\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -GenerateJenkinsReport
```plaintext
### IntÃ©gration avec Allure

```powershell
.\Integrate-Allure.ps1 -TestDirectory development/testing/tests/python -OpenReport -InstallAllure
```plaintext
### IntÃ©gration avec Jenkins

```powershell
.\Integrate-Jenkins.ps1 -TestDirectory development/testing/tests/python -JenkinsUrl "http://jenkins.example.com" -JenkinsJob "python-tests" -JenkinsToken "token" -JenkinsUser "user"
```plaintext
## IntÃ©gration avec le systÃ¨me d'apprentissage des erreurs

TestOmnibus peut Ãªtre intÃ©grÃ© avec votre systÃ¨me d'apprentissage des erreurs existant en utilisant l'option `--save-errors` (ou `-SaveErrors` en PowerShell). Cette option sauvegarde les erreurs dÃ©tectÃ©es dans une base de donnÃ©es JSON qui peut Ãªtre utilisÃ©e pour analyser les patterns d'erreur et suggÃ©rer des corrections.

La base de donnÃ©es d'erreurs est structurÃ©e comme suit :

```json
{
  "errors": [
    {
      "signature": "AssertionError: 1 + 1 devrait Ãªtre Ã©gal Ã  2, pas Ã  3",
      "type": "AssertionError",
      "message": "1 + 1 devrait Ãªtre Ã©gal Ã  2, pas Ã  3",
      "files": ["development/testing/tests/python/test_example.py"],
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
```plaintext
## Personnalisation

Vous pouvez personnaliser TestOmnibus en modifiant les fichiers suivants :

- `run_testomnibus.py` : Script principal Python
- `Invoke-TestOmnibus.ps1` : Wrapper PowerShell

## IntÃ©gration avec CI/CD

TestOmnibus peut Ãªtre facilement intÃ©grÃ© dans votre pipeline CI/CD. Voici des exemples d'utilisation :

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
        .\development\scripts\python\testing\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -GenerateReport -Analyze -GenerateCoverage -GenerateAllureReport -GenerateJenkinsReport

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
```plaintext
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
                powershell '.\development\scripts\python\testing\Invoke-TestOmnibus.ps1 -TestDirectory development/testing/tests/python -GenerateReport -Analyze -GenerateCoverage -GenerateJenkinsReport'
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
```plaintext