# Test-FormatExamples-Simple.ps1
# Version simplifiee pour tester les conversions de format

# Creer le repertoire de sortie s'il n'existe pas
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "examples\output"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Chemins des fichiers d'exemple
$markdownFile = Join-Path -Path $PSScriptRoot -ChildPath "examples\example.md"
$csvFile = Join-Path -Path $PSScriptRoot -ChildPath "examples\example.csv"
$jsonFile = Join-Path -Path $PSScriptRoot -ChildPath "examples\example.json"

# Chemin du script de conversion
$formatScript = Join-Path -Path $PSScriptRoot -ChildPath "Format-TextToRoadmap-Enhanced.ps1"

# Tester la conversion de Markdown vers Roadmap
Write-Host "Test: Markdown -> Roadmap" -ForegroundColor Cyan
& $formatScript -InputFile $markdownFile -InputFormat "Markdown" -OutputFormat "Roadmap" -OutputFile "$outputDir\markdown_to_roadmap.txt" -SectionTitle "Test de conversion" -Complexity "Moyenne" -TimeEstimate "2 semaines"

# Tester la conversion de CSV vers Roadmap
Write-Host "Test: CSV -> Roadmap" -ForegroundColor Cyan
& $formatScript -InputFile $csvFile -InputFormat "CSV" -OutputFormat "Roadmap" -OutputFile "$outputDir\csv_to_roadmap.txt" -SectionTitle "Test de conversion" -Complexity "Moyenne" -TimeEstimate "2 semaines"

# Tester la conversion de JSON vers Roadmap
Write-Host "Test: JSON -> Roadmap" -ForegroundColor Cyan
& $formatScript -InputFile $jsonFile -InputFormat "JSON" -OutputFormat "Roadmap" -OutputFile "$outputDir\json_to_roadmap.txt" -SectionTitle "Test de conversion" -Complexity "Moyenne" -TimeEstimate "2 semaines"

Write-Host "Tests termines! Fichiers de sortie dans: $outputDir" -ForegroundColor Green
