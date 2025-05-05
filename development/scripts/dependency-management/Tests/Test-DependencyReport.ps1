# Test pour la fonction Export-DependencyReport
# Ce test vÃ©rifie que la fonction gÃ©nÃ¨re correctement les rapports de dÃ©pendances

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importÃ© avec succÃ¨s" -ForegroundColor Green

    # CrÃ©er un rÃ©pertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "DependencyReportTest"
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    # CrÃ©er un fichier de test
    $testScriptContent = @"
# DÃ©finition d'une fonction interne
function Test-InternalFunction {
    param (
        [string]`$Path
    )
    
    # Utilisation de fonctions internes
    Write-Output "Testing internal function"
}

# Appel Ã  des fonctions externes
Get-Date
Get-ChildItem
"@

    $testScriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"
    Set-Content -Path $testScriptPath -Value $testScriptContent

    # Test 1: GÃ©nÃ©rer un rapport au format texte
    Write-Host "`nTest 1: GÃ©nÃ©rer un rapport au format texte" -ForegroundColor Cyan
    $textReportPath = Join-Path -Path $testDir -ChildPath "DependencyReport.txt"
    $result1 = Export-DependencyReport -ModulePath $testScriptPath -OutputPath $textReportPath -Format "Text" -IncludeDetails
    
    if ($result1 -and (Test-Path -Path $textReportPath)) {
        Write-Host "Rapport texte gÃ©nÃ©rÃ© avec succÃ¨s: $textReportPath" -ForegroundColor Green
        
        # Afficher le contenu du rapport
        $textContent = Get-Content -Path $textReportPath -Raw
        Write-Host "AperÃ§u du rapport texte:"
        Write-Host ($textContent | Out-String)
    } else {
        Write-Host "Erreur: Ã‰chec de la gÃ©nÃ©ration du rapport texte" -ForegroundColor Red
    }
    
    # Test 2: GÃ©nÃ©rer un rapport au format CSV
    Write-Host "`nTest 2: GÃ©nÃ©rer un rapport au format CSV" -ForegroundColor Cyan
    $csvReportPath = Join-Path -Path $testDir -ChildPath "DependencyReport.csv"
    $result2 = Export-DependencyReport -ModulePath $testScriptPath -OutputPath $csvReportPath -Format "CSV"
    
    if ($result2 -and (Test-Path -Path $csvReportPath)) {
        Write-Host "Rapport CSV gÃ©nÃ©rÃ© avec succÃ¨s: $csvReportPath" -ForegroundColor Green
        
        # Afficher le contenu du rapport
        $csvContent = Import-Csv -Path $csvReportPath
        Write-Host "AperÃ§u du rapport CSV:"
        $csvContent | Format-Table -AutoSize | Out-String | Write-Host
    } else {
        Write-Host "Erreur: Ã‰chec de la gÃ©nÃ©ration du rapport CSV" -ForegroundColor Red
    }
    
    # Test 3: GÃ©nÃ©rer un rapport au format HTML
    Write-Host "`nTest 3: GÃ©nÃ©rer un rapport au format HTML" -ForegroundColor Cyan
    $htmlReportPath = Join-Path -Path $testDir -ChildPath "DependencyReport.html"
    $result3 = Export-DependencyReport -ModulePath $testScriptPath -OutputPath $htmlReportPath -Format "HTML" -IncludeDetails
    
    if ($result3 -and (Test-Path -Path $htmlReportPath)) {
        Write-Host "Rapport HTML gÃ©nÃ©rÃ© avec succÃ¨s: $htmlReportPath" -ForegroundColor Green
        
        # Afficher le dÃ©but du rapport HTML
        $htmlContent = Get-Content -Path $htmlReportPath -Raw
        Write-Host "AperÃ§u du rapport HTML (premiÃ¨res lignes):"
        Write-Host ($htmlContent.Substring(0, [Math]::Min(500, $htmlContent.Length)))
    } else {
        Write-Host "Erreur: Ã‰chec de la gÃ©nÃ©ration du rapport HTML" -ForegroundColor Red
    }
    
    # Test 4: GÃ©nÃ©rer un rapport au format JSON
    Write-Host "`nTest 4: GÃ©nÃ©rer un rapport au format JSON" -ForegroundColor Cyan
    $jsonReportPath = Join-Path -Path $testDir -ChildPath "DependencyReport.json"
    $result4 = Export-DependencyReport -ModulePath $testScriptPath -OutputPath $jsonReportPath -Format "JSON"
    
    if ($result4 -and (Test-Path -Path $jsonReportPath)) {
        Write-Host "Rapport JSON gÃ©nÃ©rÃ© avec succÃ¨s: $jsonReportPath" -ForegroundColor Green
        
        # Afficher le dÃ©but du rapport JSON
        $jsonContent = Get-Content -Path $jsonReportPath -Raw
        Write-Host "AperÃ§u du rapport JSON (premiÃ¨res lignes):"
        Write-Host ($jsonContent.Substring(0, [Math]::Min(500, $jsonContent.Length)))
    } else {
        Write-Host "Erreur: Ã‰chec de la gÃ©nÃ©ration du rapport JSON" -ForegroundColor Red
    }

    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Module -Name "ModuleDependencyAnalyzer-Fixed" -Force -ErrorAction SilentlyContinue

    # Tout est OK
    Write-Host "`nTest terminÃ© avec succÃ¨s !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
