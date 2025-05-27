#!/usr/bin/env pwsh
# Démonstration du Code Generation Framework

Write-Host "Code Generation Framework Demo" -ForegroundColor Cyan

# Créer le dossier temp
New-Item -Path "temp" -ItemType Directory -Force | Out-Null

# Exemple 1: Générer un script PowerShell d'analyse
$params1 = @{
    ScriptName = "Analyze-EmailPerformance"
    Description = "Analyse les performances des envois d'emails"
    FunctionName = "AnalyzeEmailPerformance"
    InputType = "logs d'emails"
    Implementation = '$results.Results = @(' + "`n        # Analyser les logs`n        # Calculer métriques`n    )"
}

& "$PSScriptRoot/Generate-Code.ps1" -Type "powershell" -Parameters $params1 -OutputPath "temp/Analyze-EmailPerformance.ps1"

# Exemple 2: Générer un service Go
$params2 = @{
    PackageName = "notification"
    ServiceName = "Email"
    EntityName = "EmailMessage"
    Fields = "Subject string json:subject`nBody string json:body`nTo string json:to"
    ValidationRules = "if entity.Subject == empty then return error subject required"
}

& "$PSScriptRoot/Generate-Code.ps1" -Type "go-service" -Parameters $params2 -OutputPath "temp/email_service.go"

# Exemple 3: Générer une suite de tests
$params3 = @{
    ComponentName = "EmailService"
}

& "$PSScriptRoot/Generate-Code.ps1" -Type "test-suite" -Parameters $params3 -OutputPath "temp/EmailService.Tests.ps1"

Write-Host "`nSuccessfully generated 3 examples in temp/ folder" -ForegroundColor Green
Write-Host "Time saved: ~12h of boilerplate code" -ForegroundColor Yellow
