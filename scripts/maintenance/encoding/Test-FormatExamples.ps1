# Test-FormatExamples.ps1
# Script pour tester les conversions avec les exemples

# Fonction pour tester la conversion d'un fichier
function Test-FileConversion {
    param (
        [string]$InputFile,
        [string]$InputFormat,
        [string]$OutputFormat,
        [string]$OutputFile
    )
    
    Write-Host "=== Test de conversion de $InputFormat vers $OutputFormat ===" -ForegroundColor Cyan
    Write-Host "Fichier d'entrée: $InputFile" -ForegroundColor Yellow
    Write-Host "Fichier de sortie: $OutputFile" -ForegroundColor Yellow
    
    # Exécuter la conversion
    $formatScript = Join-Path -Path $PSScriptRoot -ChildPath "Format-TextToRoadmap-Enhanced.ps1"
    & $formatScript -InputFile $InputFile -InputFormat $InputFormat -OutputFormat $OutputFormat -OutputFile $OutputFile -SectionTitle "Test de conversion" -Complexity "Moyenne" -TimeEstimate "2-3 semaines"
    
    Write-Host "Conversion terminée!" -ForegroundColor Green
    Write-Host ""
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "examples\output"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Tester les conversions depuis Markdown
$markdownFile = Join-Path -Path $PSScriptRoot -ChildPath "examples\example.md"
Test-FileConversion -InputFile $markdownFile -InputFormat "Markdown" -OutputFormat "Roadmap" -OutputFile "$outputDir\markdown_to_roadmap.txt"
Test-FileConversion -InputFile $markdownFile -InputFormat "Markdown" -OutputFormat "CSV" -OutputFile "$outputDir\markdown_to_csv.csv"
Test-FileConversion -InputFile $markdownFile -InputFormat "Markdown" -OutputFormat "JSON" -OutputFile "$outputDir\markdown_to_json.json"
Test-FileConversion -InputFile $markdownFile -InputFormat "Markdown" -OutputFormat "YAML" -OutputFile "$outputDir\markdown_to_yaml.yaml"

# Tester les conversions depuis CSV
$csvFile = Join-Path -Path $PSScriptRoot -ChildPath "examples\example.csv"
Test-FileConversion -InputFile $csvFile -InputFormat "CSV" -OutputFormat "Roadmap" -OutputFile "$outputDir\csv_to_roadmap.txt"
Test-FileConversion -InputFile $csvFile -InputFormat "CSV" -OutputFormat "Markdown" -OutputFile "$outputDir\csv_to_markdown.md"
Test-FileConversion -InputFile $csvFile -InputFormat "CSV" -OutputFormat "JSON" -OutputFile "$outputDir\csv_to_json.json"
Test-FileConversion -InputFile $csvFile -InputFormat "CSV" -OutputFormat "YAML" -OutputFile "$outputDir\csv_to_yaml.yaml"

# Tester les conversions depuis JSON
$jsonFile = Join-Path -Path $PSScriptRoot -ChildPath "examples\example.json"
Test-FileConversion -InputFile $jsonFile -InputFormat "JSON" -OutputFormat "Roadmap" -OutputFile "$outputDir\json_to_roadmap.txt"
Test-FileConversion -InputFile $jsonFile -InputFormat "JSON" -OutputFormat "Markdown" -OutputFile "$outputDir\json_to_markdown.md"
Test-FileConversion -InputFile $jsonFile -InputFormat "JSON" -OutputFormat "CSV" -OutputFile "$outputDir\json_to_csv.csv"
Test-FileConversion -InputFile $jsonFile -InputFormat "JSON" -OutputFormat "YAML" -OutputFile "$outputDir\json_to_yaml.yaml"

Write-Host "Tous les tests sont terminés!" -ForegroundColor Green
Write-Host "Les fichiers de sortie se trouvent dans le répertoire: $outputDir" -ForegroundColor Yellow
