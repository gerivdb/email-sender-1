# Test pour les fonctions d'exportation et d'importation de ACLAnalyzer.ps1
# Importer le module à tester
$scriptPath = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ACLAnalyzer.ps1"
. $modulePath

# Créer un dossier de test unique
$testGuid = [System.Guid]::NewGuid().ToString()
$testFolder = Join-Path -Path $env:TEMP -ChildPath "ACLTest_$testGuid"
$testSubFolder = Join-Path -Path $testFolder -ChildPath "SubFolder"
$exportFolder = Join-Path -Path $env:TEMP -ChildPath "ACLExport_$testGuid"
$exportPath = Join-Path -Path $exportFolder -ChildPath "permissions.json"

# Créer les dossiers pour les tests
New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
New-Item -Path $testSubFolder -ItemType Directory -Force | Out-Null
New-Item -Path $exportFolder -ItemType Directory -Force | Out-Null

# Fonction pour afficher les résultats des tests
function Test-Result {
    param (
        [string]$TestName,
        [scriptblock]$TestScript,
        [scriptblock]$ValidationScript
    )
    
    Write-Host "Test: $TestName"
    try {
        $result = & $TestScript
        $valid = & $ValidationScript $result
        
        if ($valid) {
            Write-Host "  RÉUSSI: $TestName" -ForegroundColor Green
        } else {
            Write-Host "  ÉCHEC: $TestName - Validation échouée" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ERREUR: $TestName - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    return $result
}

# Test 1: Export-NTFSPermission
$result1 = Test-Result -TestName "Export-NTFSPermission au format JSON" -TestScript {
    Export-NTFSPermission -Path $testFolder -OutputPath $exportPath -Format "JSON" -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and (Test-Path -Path $r)
}

# Test 2: Export-NTFSPermission au format XML
$xmlPath = Join-Path -Path $exportFolder -ChildPath "permissions.xml"
$result2 = Test-Result -TestName "Export-NTFSPermission au format XML" -TestScript {
    Export-NTFSPermission -Path $testFolder -OutputPath $xmlPath -Format "XML" -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and (Test-Path -Path $r)
}

# Test 3: Export-NTFSPermission au format CSV
$csvPath = Join-Path -Path $exportFolder -ChildPath "permissions.csv"
$result3 = Test-Result -TestName "Export-NTFSPermission au format CSV" -TestScript {
    Export-NTFSPermission -Path $testFolder -OutputPath $csvPath -Format "CSV" -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and (Test-Path -Path $r)
}

# Test 4: Import-NTFSPermission avec WhatIf
$result4 = Test-Result -TestName "Import-NTFSPermission avec WhatIf" -TestScript {
    Import-NTFSPermission -InputPath $exportPath -TargetPath $testSubFolder -Format "JSON" -WhatIf
} -ValidationScript {
    param($r)
    return $r -ne $null
}

# Nettoyer les fichiers de test
Write-Host "Nettoyage des fichiers de test..."
Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $exportFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Tests terminés."
