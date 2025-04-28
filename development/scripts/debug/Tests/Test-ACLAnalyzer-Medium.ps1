# Test plus dÃ©taillÃ© pour ACLAnalyzer.ps1
# Importer le module Ã  tester
$scriptPath = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ACLAnalyzer.ps1"
. $modulePath

# CrÃ©er un dossier de test unique
$testGuid = [System.Guid]::NewGuid().ToString()
$testFolder = Join-Path -Path $env:TEMP -ChildPath "ACLTest_$testGuid"
$testSubFolder = Join-Path -Path $testFolder -ChildPath "SubFolder"
$testFile = Join-Path -Path $testFolder -ChildPath "testfile.txt"

# CrÃ©er le dossier et le fichier pour les tests
New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
New-Item -Path $testSubFolder -ItemType Directory -Force | Out-Null
"Test content" | Out-File -FilePath $testFile -Encoding utf8

# Ajouter une permission "Everyone" pour tester la dÃ©tection d'anomalies
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

# Test 1: Get-NTFSPermission
$result1 = Test-Result -TestName "Get-NTFSPermission sur un dossier" -TestScript {
    Get-NTFSPermission -Path $testFolder -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and $r.Count -gt 0 -and $r[0].Path -eq $testFolder
}

# Test 2: Get-NTFSPermission avec rÃ©cursivitÃ© limitÃ©e
$result2 = Test-Result -TestName "Get-NTFSPermission avec rÃ©cursivitÃ© limitÃ©e" -TestScript {
    Get-NTFSPermission -Path $testFolder -Recurse $true
} -ValidationScript {
    param($r)
    return $r -and $r.Count -gt 1 -and ($r | Where-Object { $_.Path -eq $testFile }).Count -gt 0
}

# Test 3: Get-NTFSPermissionInheritance
$result3 = Test-Result -TestName "Get-NTFSPermissionInheritance sur un dossier" -TestScript {
    Get-NTFSPermissionInheritance -Path $testFolder -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and $r.Path -eq $testFolder -and $r.InheritanceEnabled -eq $true
}

# Test 4: Get-NTFSPermissionInheritance sur un dossier avec hÃ©ritage dÃ©sactivÃ©
$result4 = Test-Result -TestName "Get-NTFSPermissionInheritance sur un dossier avec hÃ©ritage dÃ©sactivÃ©" -TestScript {
    Get-NTFSPermissionInheritance -Path $testSubFolder -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and $r.Path -eq $testSubFolder -and $r.InheritanceEnabled -eq $false
}

# Test 5: Get-NTFSOwnershipInfo
$result5 = Test-Result -TestName "Get-NTFSOwnershipInfo sur un dossier" -TestScript {
    Get-NTFSOwnershipInfo -Path $testFolder -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and $r.Path -eq $testFolder -and $r.Owner -ne $null
}

# Test 6: Find-NTFSPermissionAnomaly
$result6 = Test-Result -TestName "Find-NTFSPermissionAnomaly sur un dossier avec anomalie" -TestScript {
    Find-NTFSPermissionAnomaly -Path $testFolder -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and $r.Count -gt 0 -and $r[0].Path -eq $testFolder
}

# Test 7: New-NTFSPermissionReport au format texte
$result7 = Test-Result -TestName "New-NTFSPermissionReport au format texte" -TestScript {
    New-NTFSPermissionReport -Path $testFolder -OutputFormat "Text"
} -ValidationScript {
    param($r)
    return $r -and $r -match "RAPPORT D'ANALYSE DES PERMISSIONS NTFS"
}

# Test 8: New-NTFSPermissionReport au format HTML
$result8 = Test-Result -TestName "New-NTFSPermissionReport au format HTML" -TestScript {
    New-NTFSPermissionReport -Path $testFolder -OutputFormat "HTML"
} -ValidationScript {
    param($r)
    return $r -and $r -match "<html"
}

# Test 9: New-NTFSPermissionReport au format JSON
$result9 = Test-Result -TestName "New-NTFSPermissionReport au format JSON" -TestScript {
    New-NTFSPermissionReport -Path $testFolder -OutputFormat "JSON"
} -ValidationScript {
    param($r)
    return $r -and $r -match '"Path":'
}

# Nettoyer les fichiers de test
Write-Host "Nettoyage des fichiers de test..."
Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Tests terminÃ©s."
