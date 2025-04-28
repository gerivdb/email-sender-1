# Test pour les fonctions avancÃ©es de ACLAnalyzer.ps1
# Importer le module Ã  tester
$scriptPath = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ACLAnalyzer.ps1"
. $modulePath

# CrÃ©er un dossier de test unique
$testGuid = [System.Guid]::NewGuid().ToString()
$testFolder = Join-Path -Path $env:TEMP -ChildPath "ACLTest_$testGuid"
$testSubFolder = Join-Path -Path $testFolder -ChildPath "SubFolder"
$testReferenceFolder = Join-Path -Path $env:TEMP -ChildPath "ACLTest_Ref_$testGuid"

# CrÃ©er les dossiers pour les tests
New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
New-Item -Path $testSubFolder -ItemType Directory -Force | Out-Null
New-Item -Path $testReferenceFolder -ItemType Directory -Force | Out-Null

# Ajouter une permission "Everyone" pour tester la dÃ©tection et la correction d'anomalies
$acl = Get-Acl -Path $testFolder
$everyone = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WorldSid, $null)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($everyone, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl -Path $testFolder -AclObject $acl

# DÃ©sactiver l'hÃ©ritage sur le sous-dossier pour les tests
$acl = Get-Acl -Path $testSubFolder
$acl.SetAccessRuleProtection($true, $true)  # DÃ©sactiver l'hÃ©ritage mais conserver les rÃ¨gles hÃ©ritÃ©es
Set-Acl -Path $testSubFolder -AclObject $acl

# Fonction pour afficher les rÃ©sultats des tests
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
            Write-Host "  RÃ‰USSI: $TestName" -ForegroundColor Green
        } else {
            Write-Host "  Ã‰CHEC: $TestName - Validation Ã©chouÃ©e" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ERREUR: $TestName - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    return $result
}

# Test 1: Repair-NTFSPermissionAnomaly avec WhatIf
$result1 = Test-Result -TestName "Repair-NTFSPermissionAnomaly avec WhatIf" -TestScript {
    Repair-NTFSPermissionAnomaly -Path $testFolder -AnomalyType "HighRiskPermission" -WhatIf
} -ValidationScript {
    param($r)
    return $r -and $r.Count -gt 0 -and $r[0].CorrectionApplied -eq $false
}

# Test 2: Compare-NTFSPermission
$result2 = Test-Result -TestName "Compare-NTFSPermission entre deux dossiers" -TestScript {
    # Ajouter une permission diffÃ©rente au dossier de rÃ©fÃ©rence
    $acl = Get-Acl -Path $testReferenceFolder
    $users = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinUsersSid, $null)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($users, "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl -Path $testReferenceFolder -AclObject $acl
    
    # Comparer les permissions
    Compare-NTFSPermission -ReferencePath $testReferenceFolder -DifferencePath $testFolder
} -ValidationScript {
    param($r)
    return $r -and $r.HasDifferences -eq $true
}

# Test 3: Repair-NTFSPermissionAnomaly avec Force
$result3 = Test-Result -TestName "Repair-NTFSPermissionAnomaly avec Force" -TestScript {
    Repair-NTFSPermissionAnomaly -Path $testSubFolder -AnomalyType "InheritanceBreak" -Force
} -ValidationScript {
    param($r)
    # VÃ©rifier si la correction a Ã©tÃ© appliquÃ©e
    if ($r -and $r.Count -gt 0 -and $r[0].CorrectionApplied -eq $true) {
        # VÃ©rifier si l'hÃ©ritage a Ã©tÃ© rÃ©activÃ©
        $acl = Get-Acl -Path $testSubFolder
        return -not $acl.AreAccessRulesProtected
    }
    return $false
}

# Nettoyer les fichiers de test
Write-Host "Nettoyage des fichiers de test..."
Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $testReferenceFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Tests terminÃ©s."
