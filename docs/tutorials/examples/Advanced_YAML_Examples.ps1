# Exemples avancés d'utilisation des fonctionnalités YAML
# Ce script contient des exemples avancés d'utilisation des fonctionnalités YAML du module UnifiedSegmenter

# Importer le module UnifiedSegmenter
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"
. $unifiedSegmenterPath

# Initialiser le segmenteur unifié
$initResult = Initialize-UnifiedSegmenter
if (-not $initResult) {
    Write-Error "Erreur lors de l'initialisation du segmenteur unifié"
    return
}

# Créer un répertoire temporaire pour les exemples
$tempDir = Join-Path -Path $env:TEMP -ChildPath "AdvancedYamlExamples"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers d'exemple
$yamlFilePath = Join-Path -Path $tempDir -ChildPath "example.yaml"
$yamlComplexFilePath = Join-Path -Path $tempDir -ChildPath "complex_example.yaml"
$yamlInvalidFilePath = Join-Path -Path $tempDir -ChildPath "invalid_example.yaml"
$outputDir = Join-Path -Path $tempDir -ChildPath "output"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# Créer un fichier YAML d'exemple
$yamlContent = @"
name: Example Object
version: 1.0.0
description: This is an example YAML file
enabled: true
settings:
  timeout: 30
  retries: 3
  logging: debug
items:
  - id: 1
    name: Item 1
    value: Value 1
  - id: 2
    name: Item 2
    value: Value 2
  - id: 3
    name: Item 3
    value: Value 3
metadata:
  created: 2025-06-06
  author: EMAIL_SENDER_1 Team
  tags:
    - example
    - yaml
    - test
"@
Set-Content -Path $yamlFilePath -Value $yamlContent -Encoding UTF8

# Créer un fichier YAML complexe
$yamlComplexContent = @"
# Configuration for the application
application:
  name: Complex YAML Example
  version: 2.0.0
  description: |
    This is a complex YAML file with various data types,
    multi-line strings, and nested structures.
  
  # Database configuration
  database:
    host: localhost
    port: 5432
    name: example_db
    credentials:
      username: admin
      password: !secret password
      connection_pool: 10
    tables:
      - name: users
        columns:
          - name: id
            type: integer
            primary_key: true
          - name: username
            type: string
            nullable: false
          - name: email
            type: string
            nullable: false
          - name: created_at
            type: datetime
            default: CURRENT_TIMESTAMP
      - name: products
        columns:
          - name: id
            type: integer
            primary_key: true
          - name: name
            type: string
          - name: price
            type: decimal
          - name: category
            type: string
  
  # Server configuration
  server:
    host: 0.0.0.0
    port: 8080
    ssl:
      enabled: true
      cert_file: /etc/ssl/cert.pem
      key_file: /etc/ssl/key.pem
    middleware:
      - name: cors
        config:
          allowed_origins:
            - https://example.com
            - https://api.example.com
          allowed_methods:
            - GET
            - POST
            - PUT
            - DELETE
      - name: authentication
        config:
          jwt_secret: !secret jwt_secret
          token_expiry: 3600
      - name: rate_limiter
        config:
          requests_per_minute: 60
          burst: 10
  
  # Logging configuration
  logging:
    level: info
    format: json
    outputs:
      - type: file
        path: /var/log/app.log
        rotation:
          max_size: 100MB
          max_files: 10
      - type: stdout
  
  # Feature flags
  features:
    enable_new_ui: true
    enable_analytics: false
    experimental:
      enable_cache: true
      enable_websockets: false
  
  # Environment-specific overrides
  environments:
    development:
      logging:
        level: debug
      features:
        experimental:
          enable_websockets: true
    production:
      server:
        port: 80
      logging:
        level: warn
      database:
        host: db.example.com
"@
Set-Content -Path $yamlComplexFilePath -Value $yamlComplexContent -Encoding UTF8

# Créer un fichier YAML invalide
$yamlInvalidContent = @"
name: Invalid YAML Example
items:
  - id: 1
    name: Item 1
  - id: 2
    name: Item 2
  - id: 3
  name: Item 3  # Indentation incorrecte
metadata:
  created: 2025-06-06
  tags:
    - example
    - yaml
    - test
"@
Set-Content -Path $yamlInvalidFilePath -Value $yamlInvalidContent -Encoding UTF8

# Exemple 1 : Validation avancée de fichier YAML
Write-Host "`n=== Exemple 1 : Validation avancée de fichier YAML ===" -ForegroundColor Green
Write-Host "Validation d'un fichier YAML valide..."
$isValid = Test-FileValidity -FilePath $yamlFilePath -Format "YAML"
Write-Host "Le fichier YAML est valide: $isValid"

Write-Host "`nValidation d'un fichier YAML complexe..."
$isComplexValid = Test-FileValidity -FilePath $yamlComplexFilePath -Format "YAML"
Write-Host "Le fichier YAML complexe est valide: $isComplexValid"

Write-Host "`nValidation d'un fichier YAML invalide..."
$isInvalid = Test-FileValidity -FilePath $yamlInvalidFilePath -Format "YAML"
Write-Host "Le fichier YAML invalide est valide: $isInvalid"

# Exemple 2 : Analyse détaillée d'un fichier YAML
Write-Host "`n=== Exemple 2 : Analyse détaillée d'un fichier YAML ===" -ForegroundColor Green
$yamlAnalysisPath = Join-Path -Path $outputDir -ChildPath "yaml_analysis.json"
$yamlAnalysisResult = Get-FileAnalysis -FilePath $yamlFilePath -Format "YAML" -OutputFile $yamlAnalysisPath
Write-Host "Analyse YAML enregistrée dans: $yamlAnalysisResult"

# Créer un script Python pour analyser le fichier YAML
$pythonScriptPath = Join-Path -Path $tempDir -ChildPath "analyze_yaml.py"
$pythonScript = @"
import json
import sys

# Charger l'analyse YAML
with open(r'$yamlAnalysisPath', 'r', encoding='utf-8') as f:
    analysis = json.load(f)

# Afficher les informations générales
print("Informations générales:")
print(f"  Taille du fichier: {analysis['file_info']['file_size_kb']:.2f} KB")
print(f"  Encodage: {analysis['file_info']['encoding']}")

# Fonction pour afficher la structure de manière récursive
def print_structure(structure, indent=0):
    indent_str = "  " * indent
    
    if structure['type'] == 'dict':
        print(f"{indent_str}Type: Dictionnaire")
        print(f"{indent_str}Nombre de clés: {structure['key_count']}")
        print(f"{indent_str}Clés: {', '.join(structure['keys'])}")
        
        if 'nested' in structure:
            print(f"{indent_str}Structure imbriquée:")
            for key, nested in structure['nested'].items():
                print(f"{indent_str}  Clé '{key}':")
                print_structure(nested, indent + 2)
    
    elif structure['type'] == 'list':
        print(f"{indent_str}Type: Liste")
        print(f"{indent_str}Nombre d'éléments: {structure['item_count']}")
        
        if 'sample_items' in structure and structure['sample_items']:
            print(f"{indent_str}Échantillon d'éléments:")
            for i, item in enumerate(structure['sample_items']):
                print(f"{indent_str}  Élément {i}:")
                print_structure(item, indent + 2)
    
    elif structure['type'] == 'string':
        print(f"{indent_str}Type: Chaîne de caractères")
        print(f"{indent_str}Longueur: {structure['length']}")
        print(f"{indent_str}Échantillon: {structure['sample']}")
    
    elif structure['type'] == 'number':
        print(f"{indent_str}Type: Nombre")
        print(f"{indent_str}Valeur: {structure['value']}")
    
    elif structure['type'] == 'boolean':
        print(f"{indent_str}Type: Booléen")
        print(f"{indent_str}Valeur: {structure['value']}")
    
    else:
        print(f"{indent_str}Type: {structure['type']}")

# Afficher la structure
print("\nStructure du fichier YAML:")
print_structure(analysis['structure'])
"@
Set-Content -Path $pythonScriptPath -Value $pythonScript -Encoding UTF8

# Exécuter le script Python
Write-Host "`nAnalyse détaillée du fichier YAML:"
& python $pythonScriptPath

# Exemple 3 : Conversion YAML vers différents formats
Write-Host "`n=== Exemple 3 : Conversion YAML vers différents formats ===" -ForegroundColor Green

# YAML vers JSON
$yamlToJsonPath = Join-Path -Path $outputDir -ChildPath "yaml_to_json.json"
$yamlToJsonResult = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $yamlToJsonPath -InputFormat "YAML" -OutputFormat "JSON"
Write-Host "Conversion YAML vers JSON réussie: $yamlToJsonResult"

# YAML vers XML
$yamlToXmlPath = Join-Path -Path $outputDir -ChildPath "yaml_to_xml.xml"
$yamlToXmlResult = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $yamlToXmlPath -InputFormat "YAML" -OutputFormat "XML"
Write-Host "Conversion YAML vers XML réussie: $yamlToXmlResult"

# YAML vers CSV
$yamlToCsvPath = Join-Path -Path $outputDir -ChildPath "yaml_to_csv.csv"
$yamlToCsvResult = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $yamlToCsvPath -InputFormat "YAML" -OutputFormat "CSV"
Write-Host "Conversion YAML vers CSV réussie: $yamlToCsvResult"

# Exemple 4 : Extraction de données spécifiques d'un fichier YAML
Write-Host "`n=== Exemple 4 : Extraction de données spécifiques d'un fichier YAML ===" -ForegroundColor Green

# Créer un script Python pour extraire des données spécifiques
$extractScriptPath = Join-Path -Path $tempDir -ChildPath "extract_yaml_data.py"
$extractScript = @"
import yaml
import json
import sys

# Charger le fichier YAML
with open(r'$yamlComplexFilePath', 'r', encoding='utf-8-sig') as f:
    data = yaml.safe_load(f)

# Extraire des données spécifiques
database_config = data['application']['database']
server_config = data['application']['server']
features = data['application']['features']

# Créer un nouveau dictionnaire avec les données extraites
extracted_data = {
    'database': {
        'host': database_config['host'],
        'port': database_config['port'],
        'name': database_config['name']
    },
    'server': {
        'host': server_config['host'],
        'port': server_config['port'],
        'ssl_enabled': server_config['ssl']['enabled']
    },
    'features': features
}

# Afficher les données extraites
print(json.dumps(extracted_data, indent=2))

# Enregistrer les données extraites dans un fichier
output_file = r'$outputDir/extracted_data.json'
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(extracted_data, f, indent=2)

print(f"\nDonnées extraites enregistrées dans: {output_file}")
"@
Set-Content -Path $extractScriptPath -Value $extractScript -Encoding UTF8

# Exécuter le script d'extraction
Write-Host "Extraction de données spécifiques du fichier YAML complexe:"
& python $extractScriptPath

# Exemple 5 : Fusion de fichiers YAML
Write-Host "`n=== Exemple 5 : Fusion de fichiers YAML ===" -ForegroundColor Green

# Créer des fichiers YAML à fusionner
$yamlPart1Path = Join-Path -Path $tempDir -ChildPath "part1.yaml"
$yamlPart2Path = Join-Path -Path $tempDir -ChildPath "part2.yaml"
$yamlPart3Path = Join-Path -Path $tempDir -ChildPath "part3.yaml"

$yamlPart1Content = @"
# Configuration de base
name: Merged YAML Example
version: 1.0.0
description: This is a merged YAML file
"@
Set-Content -Path $yamlPart1Path -Value $yamlPart1Content -Encoding UTF8

$yamlPart2Content = @"
# Configuration de la base de données
database:
  host: localhost
  port: 5432
  name: example_db
  username: admin
  password: password123
"@
Set-Content -Path $yamlPart2Path -Value $yamlPart2Content -Encoding UTF8

$yamlPart3Content = @"
# Configuration du serveur
server:
  host: 0.0.0.0
  port: 8080
  ssl: true
"@
Set-Content -Path $yamlPart3Path -Value $yamlPart3Content -Encoding UTF8

# Créer un script Python pour fusionner les fichiers YAML
$mergeScriptPath = Join-Path -Path $tempDir -ChildPath "merge_yaml.py"
$mergeScript = @"
import yaml
import sys

# Fonction pour fusionner deux dictionnaires de manière récursive
def merge_dicts(dict1, dict2):
    result = dict1.copy()
    for key, value in dict2.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = merge_dicts(result[key], value)
        else:
            result[key] = value
    return result

# Charger les fichiers YAML
yaml_files = [r'$yamlPart1Path', r'$yamlPart2Path', r'$yamlPart3Path']
merged_data = {}

for file_path in yaml_files:
    with open(file_path, 'r', encoding='utf-8-sig') as f:
        data = yaml.safe_load(f)
        merged_data = merge_dicts(merged_data, data)

# Enregistrer le résultat fusionné
output_file = r'$outputDir/merged.yaml'
with open(output_file, 'w', encoding='utf-8') as f:
    yaml.dump(merged_data, f, default_flow_style=False, sort_keys=False)

print(f"Fusion réussie: {len(yaml_files)} fichiers fusionnés dans {output_file}")

# Afficher le contenu fusionné
print("\nContenu fusionné:")
print(yaml.dump(merged_data, default_flow_style=False, sort_keys=False))
"@
Set-Content -Path $mergeScriptPath -Value $mergeScript -Encoding UTF8

# Exécuter le script de fusion
Write-Host "Fusion de fichiers YAML:"
& python $mergeScriptPath

# Vérifier que le fichier fusionné est valide
$mergedYamlPath = Join-Path -Path $outputDir -ChildPath "merged.yaml"
$isMergedValid = Test-FileValidity -FilePath $mergedYamlPath -Format "YAML"
Write-Host "Le fichier YAML fusionné est valide: $isMergedValid"

# Nettoyer
Write-Host "`nNettoyage des fichiers d'exemple..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nExemples terminés."
