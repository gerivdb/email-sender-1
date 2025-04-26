# Test pour les fonctions avancées de ACLAnalyzer.ps1
# Importer le module à tester
$scriptPath = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ACLAnalyzer.ps1"
. $modulePath

# Créer un dossier de test unique
$testGuid = [System.Guid]::NewGuid().ToString()
$testFolder = Join-Path -Path $env:TEMP -ChildPath "ACLTest_$testGuid"
$testSubFolder = Join-Path -Path $testFolder -ChildPath "SubFolder"
$testReferenceFolder = Join-Path -Path $env:TEMP -ChildPath "ACLTest_Ref_$testGuid"

# Créer les dossiers pour les tests
New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
New-Item -Path $testSubFolder -ItemType Directory -Force | Out-Null
New-Item -Path $testReferenceFolder -ItemType Directory -Force | Out-Null

# Ajouter une permission "Everyone" pour tester la détection et la correction d'anomalies
$acl = Get-Acl -Path $testFolder
$everyone = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WorldSid, $null)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($everyone, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl -Path $testFolder -AclObject $acl

# Désactiver l'héritage sur le sous-dossier pour les tests
$acl = Get-Acl -Path $testSubFolder
$acl.SetAccessRuleProtection($true, $true)  # Désactiver l'héritage mais conserver les règles héritées
Set-Acl -Path $testSubFolder -AclObject $acl

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

# Test 1: Repair-NTFSPermissionAnomaly avec WhatIf
$result1 = Test-Result -TestName "Repair-NTFSPermissionAnomaly avec WhatIf" -TestScript {
    Repair-NTFSPermissionAnomaly -Path $testFolder -AnomalyType "HighRiskPermission" -WhatIf
} -ValidationScript {
    param($r)
    return $r -and $r.Count -gt 0 -and $r[0].CorrectionApplied -eq $false
}

# Test 2: Compare-NTFSPermission
$result2 = Test-Result -TestName "Compare-NTFSPermission entre deux dossiers" -TestScript {
    # Ajouter une permission différente au dossier de référence
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
    # Vérifier si la correction a été appliquée
    if ($r -and $r.Count -gt 0 -and $r[0].CorrectionApplied -eq $true) {
        # Vérifier si l'héritage a été réactivé
        $acl = Get-Acl -Path $testSubFolder
        return -not $acl.AreAccessRulesProtected
    }
    return $false
}

# Nettoyer les fichiers de test
Write-Host "Nettoyage des fichiers de test..."
Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $testReferenceFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Tests terminés."
