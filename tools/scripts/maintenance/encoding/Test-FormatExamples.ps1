# Test-FormatExamples.ps1
# Script pour tester les conversions avec les exemples

# Fonction pour tester la conversion d'un fichier

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

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal

    
    Write-Host "=== Test de conversion de $InputFormat vers $OutputFormat ===" -ForegroundColor Cyan
    Write-Host "Fichier d'entrÃ©e: $InputFile" -ForegroundColor Yellow
    Write-Host "Fichier de sortie: $OutputFile" -ForegroundColor Yellow
    
    # ExÃ©cuter la conversion
    $formatScript = Join-Path -Path $PSScriptRoot -ChildPath "Format-TextToRoadmap-Enhanced.ps1"
    & $formatScript -InputFile $InputFile -InputFormat $InputFormat -OutputFormat $OutputFormat -OutputFile $OutputFile -SectionTitle "Test de conversion" -Complexity "Moyenne" -TimeEstimate "2-3 semaines"
    
    Write-Host "Conversion terminÃ©e!" -ForegroundColor Green
    Write-Host ""
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
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

Write-Host "Tous les tests sont terminÃ©s!" -ForegroundColor Green
Write-Host "Les fichiers de sortie se trouvent dans le rÃ©pertoire: $outputDir" -ForegroundColor Yellow

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
