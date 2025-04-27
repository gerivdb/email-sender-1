# Test simple pour RegistryACLAnalyzer.ps1
# Importer le module Ã  tester
$scriptPath = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "RegistryACLAnalyzer.ps1"
. $modulePath

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

# Test 1: Get-RegistryPermission sur une clÃ© de registre existante
$result1 = Test-Result -TestName "Get-RegistryPermission sur HKLM:\SOFTWARE" -TestScript {
    Get-RegistryPermission -Path "HKLM:\SOFTWARE" -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and $r.Count -gt 0 -and $r[0].Path -eq "HKLM:\SOFTWARE"
}

# Test 2: Get-RegistryPermission avec rÃ©cursivitÃ© limitÃ©e
$result2 = Test-Result -TestName "Get-RegistryPermission avec rÃ©cursivitÃ© limitÃ©e" -TestScript {
    Get-RegistryPermission -Path "HKCU:\Software\Microsoft" -Recurse $true
} -ValidationScript {
    param($r)
    return $r -and $r.Count -gt 1
}

# Test 3: Get-RegistryPermission avec filtrage des permissions hÃ©ritÃ©es
$result3 = Test-Result -TestName "Get-RegistryPermission avec filtrage des permissions hÃ©ritÃ©es" -TestScript {
    Get-RegistryPermission -Path "HKCU:\Software" -Recurse $false -IncludeInherited $false
} -ValidationScript {
    param($r)
    return $r -and (-not ($r | Where-Object { $_.IsInherited -eq $true }))
}

# Test 4: Get-RegistryPermissionInheritance sur une clÃ© de registre existante
$result4 = Test-Result -TestName "Get-RegistryPermissionInheritance sur HKLM:\SOFTWARE" -TestScript {
    Get-RegistryPermissionInheritance -Path "HKLM:\SOFTWARE" -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and $r.Path -eq "HKLM:\SOFTWARE" -and $r.InheritanceEnabled -ne $null
}

# Test 5: Get-RegistryPermissionInheritance avec rÃ©cursivitÃ© limitÃ©e
$result5 = Test-Result -TestName "Get-RegistryPermissionInheritance avec rÃ©cursivitÃ© limitÃ©e" -TestScript {
    Get-RegistryPermissionInheritance -Path "HKCU:\Software\Microsoft" -Recurse $true
} -ValidationScript {
    param($r)
    return $r -and $r.Count -gt 1
}

# Test 6: Get-RegistryOwnershipInfo sur une clÃ© de registre existante
$result6 = Test-Result -TestName "Get-RegistryOwnershipInfo sur HKLM:\SOFTWARE" -TestScript {
    Get-RegistryOwnershipInfo -Path "HKLM:\SOFTWARE" -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and $r.Path -eq "HKLM:\SOFTWARE" -and $r.Owner -ne $null
}

# Test 7: Get-RegistryOwnershipInfo avec rÃ©cursivitÃ© limitÃ©e
$result7 = Test-Result -TestName "Get-RegistryOwnershipInfo avec rÃ©cursivitÃ© limitÃ©e" -TestScript {
    Get-RegistryOwnershipInfo -Path "HKCU:\Software\Microsoft" -Recurse $true
} -ValidationScript {
    param($r)
    return $r -and $r.Count -gt 1
}

# Test 8: Find-RegistryPermissionAnomaly sur une clÃ© de registre existante
$result8 = Test-Result -TestName "Find-RegistryPermissionAnomaly sur HKLM:\SOFTWARE" -TestScript {
    Find-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE" -Recurse $false
} -ValidationScript {
    param($r)
    return $r -ne $null
}

# Test 9: Find-RegistryPermissionAnomaly avec rÃ©cursivitÃ© limitÃ©e
$result9 = Test-Result -TestName "Find-RegistryPermissionAnomaly avec rÃ©cursivitÃ© limitÃ©e" -TestScript {
    Find-RegistryPermissionAnomaly -Path "HKCU:\Software\Microsoft" -Recurse $true
} -ValidationScript {
    param($r)
    return $r -ne $null
}

# Test 10: New-RegistryPermissionReport au format texte
$result10 = Test-Result -TestName "New-RegistryPermissionReport au format texte" -TestScript {
    New-RegistryPermissionReport -Path "HKLM:\SOFTWARE" -OutputFormat "Text"
} -ValidationScript {
    param($r)
    return $r -and $r -match "RAPPORT D'ANALYSE DES PERMISSIONS DE REGISTRE"
}

# Test 11: New-RegistryPermissionReport au format HTML
$result11 = Test-Result -TestName "New-RegistryPermissionReport au format HTML" -TestScript {
    New-RegistryPermissionReport -Path "HKLM:\SOFTWARE" -OutputFormat "HTML"
} -ValidationScript {
    param($r)
    return $r -and $r -match "<html"
}

# Test 12: New-RegistryPermissionReport au format JSON
$result12 = Test-Result -TestName "New-RegistryPermissionReport au format JSON" -TestScript {
    New-RegistryPermissionReport -Path "HKLM:\SOFTWARE" -OutputFormat "JSON"
} -ValidationScript {
    param($r)
    return $r -and $r -match '"Path":'
}

# Test 13: Repair-RegistryPermissionAnomaly avec WhatIf
$result13 = Test-Result -TestName "Repair-RegistryPermissionAnomaly avec WhatIf" -TestScript {
    Repair-RegistryPermissionAnomaly -Path "HKCU:\Software" -AnomalyType "All" -WhatIf
} -ValidationScript {
    param($r)
    # Si aucune anomalie n'est trouvÃ©e, la fonction retourne $null, ce qui est OK
    # Si des anomalies sont trouvÃ©es, la fonction retourne un tableau d'objets
    return $r -eq $null -or $r -is [array]
}

# Test 14: Compare-RegistryPermission entre deux clÃ©s de registre
$result14 = Test-Result -TestName "Compare-RegistryPermission entre deux clÃ©s de registre" -TestScript {
    Compare-RegistryPermission -ReferencePath "HKLM:\SOFTWARE\Microsoft" -DifferencePath "HKLM:\SOFTWARE\Classes" -IncludeInherited $true
} -ValidationScript {
    param($r)
    return $r -and $r.ReferencePath -eq "HKLM:\SOFTWARE\Microsoft" -and $r.DifferencePath -eq "HKLM:\SOFTWARE\Classes" -and $r.Summary -ne $null
}

# Test 15: Export-RegistryPermission au format JSON
$tempFolder = Join-Path -Path $env:TEMP -ChildPath "RegistryACLAnalyzerTest"
$jsonPath = Join-Path -Path $tempFolder -ChildPath "permissions.json"
New-Item -Path $tempFolder -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

$result15 = Test-Result -TestName "Export-RegistryPermission au format JSON" -TestScript {
    Export-RegistryPermission -Path "HKLM:\SOFTWARE\Microsoft" -OutputPath $jsonPath -Format "JSON" -Recurse $false
} -ValidationScript {
    param($r)
    return $r -and (Test-Path -Path $r)
}

# Test 16: Import-RegistryPermission avec WhatIf
$result16 = Test-Result -TestName "Import-RegistryPermission avec WhatIf" -TestScript {
    Import-RegistryPermission -InputPath $jsonPath -TargetPath "HKCU:\Software\Test" -Format "JSON" -WhatIf
} -ValidationScript {
    param($r)
    # Si le chemin cible n'existe pas, la fonction retourne $null, ce qui est OK
    # Si le chemin cible existe, la fonction retourne un tableau d'objets
    return $r -eq $null -or $r -is [array]
}

# Nettoyer les fichiers temporaires
Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Tests terminÃ©s."
