# Script de test pour vérifier la compatibilité entre PowerShell 5.1 et 7.x
# Ce script teste les fonctions de conversion d'énumérations sur différentes versions de PowerShell

# Fonction pour afficher les informations sur la version de PowerShell
function Show-PowerShellVersionInfo {
    $psVersion = $PSVersionTable.PSVersion
    $psEdition = if ($PSVersionTable.ContainsKey('PSEdition')) { $PSVersionTable.PSEdition } else { 'Desktop' }
    
    Write-Host "=== Informations sur PowerShell ===" -ForegroundColor Cyan
    Write-Host "Version: $psVersion" -ForegroundColor Cyan
    Write-Host "Edition: $psEdition" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
}

# Fonction pour exécuter les tests
function Invoke-CompatibilityTests {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulePath
    )
    
    # Importer le module
    Import-Module $ModulePath -Force
    
    # Afficher les informations sur la version de PowerShell
    Show-PowerShellVersionInfo
    
    # Récupérer les informations sur la version de PowerShell avec la fonction du module
    $psInfo = Get-PowerShellVersionInfo
    
    Write-Host "`n=== Informations sur la version de PowerShell (Get-PowerShellVersionInfo) ===" -ForegroundColor Magenta
    $psInfo | Format-List
    
    # Tester les fonctions de conversion ApartmentState
    Write-Host "`n=== Tests pour les fonctions de conversion ApartmentState ===" -ForegroundColor Magenta
    
    # Test 1: ConvertTo-ApartmentState
    Write-Host "`n--- Test 1: ConvertTo-ApartmentState ---" -ForegroundColor Cyan
    try {
        $result1 = ConvertTo-ApartmentState -Value "STA"
        Write-Host "ConvertTo-ApartmentState -Value 'STA' = $result1 (Type: $($result1.GetType().FullName))" -ForegroundColor Green
        
        $result2 = ConvertTo-ApartmentState -Value "MTA"
        Write-Host "ConvertTo-ApartmentState -Value 'MTA' = $result2 (Type: $($result2.GetType().FullName))" -ForegroundColor Green
        
        $result3 = ConvertTo-ApartmentState -Value "sta"
        Write-Host "ConvertTo-ApartmentState -Value 'sta' = $result3 (Type: $($result3.GetType().FullName))" -ForegroundColor Green
        
        try {
            $result4 = ConvertTo-ApartmentState -Value "InvalidValue"
            Write-Host "ConvertTo-ApartmentState -Value 'InvalidValue' = $result4 (Type: $($result4.GetType().FullName))" -ForegroundColor Green
        } catch {
            Write-Host "ConvertTo-ApartmentState -Value 'InvalidValue' a levé une exception (attendu): $_" -ForegroundColor Yellow
        }
        
        $result5 = ConvertTo-ApartmentState -Value "InvalidValue" -DefaultValue ([System.Threading.ApartmentState]::MTA)
        Write-Host "ConvertTo-ApartmentState -Value 'InvalidValue' -DefaultValue MTA = $result5 (Type: $($result5.GetType().FullName))" -ForegroundColor Green
    } catch {
        Write-Host "ERREUR: $_" -ForegroundColor Red
    }
    
    # Test 2: ConvertFrom-ApartmentState
    Write-Host "`n--- Test 2: ConvertFrom-ApartmentState ---" -ForegroundColor Cyan
    try {
        $result1 = ConvertFrom-ApartmentState -EnumValue ([System.Threading.ApartmentState]::STA)
        Write-Host "ConvertFrom-ApartmentState -EnumValue STA = '$result1' (Type: $($result1.GetType().FullName))" -ForegroundColor Green
        
        $result2 = ConvertFrom-ApartmentState -EnumValue ([System.Threading.ApartmentState]::MTA)
        Write-Host "ConvertFrom-ApartmentState -EnumValue MTA = '$result2' (Type: $($result2.GetType().FullName))" -ForegroundColor Green
        
        try {
            $result3 = ConvertFrom-ApartmentState -EnumValue "NotAnEnum"
            Write-Host "ConvertFrom-ApartmentState -EnumValue 'NotAnEnum' = '$result3' (Type: $($result3.GetType().FullName))" -ForegroundColor Green
        } catch {
            Write-Host "ConvertFrom-ApartmentState -EnumValue 'NotAnEnum' a levé une exception (attendu): $_" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "ERREUR: $_" -ForegroundColor Red
    }
    
    # Test 3: Test-ApartmentState
    Write-Host "`n--- Test 3: Test-ApartmentState ---" -ForegroundColor Cyan
    try {
        $result1 = Test-ApartmentState -Value ([System.Threading.ApartmentState]::STA)
        Write-Host "Test-ApartmentState -Value STA = $result1" -ForegroundColor $(if ($result1) { "Green" } else { "Red" })
        
        $result2 = Test-ApartmentState -Value "STA"
        Write-Host "Test-ApartmentState -Value 'STA' = $result2" -ForegroundColor $(if ($result2) { "Green" } else { "Red" })
        
        $result3 = Test-ApartmentState -Value "sta"
        Write-Host "Test-ApartmentState -Value 'sta' = $result3" -ForegroundColor $(if ($result3) { "Green" } else { "Red" })
        
        $result4 = Test-ApartmentState -Value "sta" -IgnoreCase $false
        Write-Host "Test-ApartmentState -Value 'sta' -IgnoreCase `$false = $result4" -ForegroundColor $(if (!$result4) { "Green" } else { "Red" })
        
        $result5 = Test-ApartmentState -Value 0
        Write-Host "Test-ApartmentState -Value 0 = $result5" -ForegroundColor $(if ($result5) { "Green" } else { "Red" })
        
        $result6 = Test-ApartmentState -Value 1
        Write-Host "Test-ApartmentState -Value 1 = $result6" -ForegroundColor $(if ($result6) { "Green" } else { "Red" })
        
        $result7 = Test-ApartmentState -Value "InvalidValue"
        Write-Host "Test-ApartmentState -Value 'InvalidValue' = $result7" -ForegroundColor $(if (!$result7) { "Green" } else { "Red" })
        
        $result8 = Test-ApartmentState -Value 999
        Write-Host "Test-ApartmentState -Value 999 = $result8" -ForegroundColor $(if (!$result8) { "Green" } else { "Red" })
    } catch {
        Write-Host "ERREUR: $_" -ForegroundColor Red
    }
    
    # Tester les fonctions de conversion PSThreadOptions
    Write-Host "`n=== Tests pour les fonctions de conversion PSThreadOptions ===" -ForegroundColor Magenta
    
    # Test 4: ConvertTo-PSThreadOptions
    Write-Host "`n--- Test 4: ConvertTo-PSThreadOptions ---" -ForegroundColor Cyan
    try {
        $result1 = ConvertTo-PSThreadOptions -Value "Default"
        Write-Host "ConvertTo-PSThreadOptions -Value 'Default' = $result1 (Type: $($result1.GetType().FullName))" -ForegroundColor Green
        
        $result2 = ConvertTo-PSThreadOptions -Value "UseNewThread"
        Write-Host "ConvertTo-PSThreadOptions -Value 'UseNewThread' = $result2 (Type: $($result2.GetType().FullName))" -ForegroundColor Green
        
        $result3 = ConvertTo-PSThreadOptions -Value "ReuseThread"
        Write-Host "ConvertTo-PSThreadOptions -Value 'ReuseThread' = $result3 (Type: $($result3.GetType().FullName))" -ForegroundColor Green
        
        $result4 = ConvertTo-PSThreadOptions -Value "default"
        Write-Host "ConvertTo-PSThreadOptions -Value 'default' = $result4 (Type: $($result4.GetType().FullName))" -ForegroundColor Green
        
        try {
            $result5 = ConvertTo-PSThreadOptions -Value "InvalidValue"
            Write-Host "ConvertTo-PSThreadOptions -Value 'InvalidValue' = $result5 (Type: $($result5.GetType().FullName))" -ForegroundColor Green
        } catch {
            Write-Host "ConvertTo-PSThreadOptions -Value 'InvalidValue' a levé une exception (attendu): $_" -ForegroundColor Yellow
        }
        
        $result6 = ConvertTo-PSThreadOptions -Value "InvalidValue" -DefaultValue ([System.Management.Automation.Runspaces.PSThreadOptions]::Default)
        Write-Host "ConvertTo-PSThreadOptions -Value 'InvalidValue' -DefaultValue Default = $result6 (Type: $($result6.GetType().FullName))" -ForegroundColor Green
    } catch {
        Write-Host "ERREUR: $_" -ForegroundColor Red
    }
    
    # Test 5: ConvertFrom-PSThreadOptions
    Write-Host "`n--- Test 5: ConvertFrom-PSThreadOptions ---" -ForegroundColor Cyan
    try {
        $result1 = ConvertFrom-PSThreadOptions -EnumValue ([System.Management.Automation.Runspaces.PSThreadOptions]::Default)
        Write-Host "ConvertFrom-PSThreadOptions -EnumValue Default = '$result1' (Type: $($result1.GetType().FullName))" -ForegroundColor Green
        
        $result2 = ConvertFrom-PSThreadOptions -EnumValue ([System.Management.Automation.Runspaces.PSThreadOptions]::UseNewThread)
        Write-Host "ConvertFrom-PSThreadOptions -EnumValue UseNewThread = '$result2' (Type: $($result2.GetType().FullName))" -ForegroundColor Green
        
        $result3 = ConvertFrom-PSThreadOptions -EnumValue ([System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread)
        Write-Host "ConvertFrom-PSThreadOptions -EnumValue ReuseThread = '$result3' (Type: $($result3.GetType().FullName))" -ForegroundColor Green
        
        try {
            $result4 = ConvertFrom-PSThreadOptions -EnumValue "NotAnEnum"
            Write-Host "ConvertFrom-PSThreadOptions -EnumValue 'NotAnEnum' = '$result4' (Type: $($result4.GetType().FullName))" -ForegroundColor Green
        } catch {
            Write-Host "ConvertFrom-PSThreadOptions -EnumValue 'NotAnEnum' a levé une exception (attendu): $_" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "ERREUR: $_" -ForegroundColor Red
    }
    
    # Test 6: Test-PSThreadOptions
    Write-Host "`n--- Test 6: Test-PSThreadOptions ---" -ForegroundColor Cyan
    try {
        $result1 = Test-PSThreadOptions -Value ([System.Management.Automation.Runspaces.PSThreadOptions]::Default)
        Write-Host "Test-PSThreadOptions -Value Default = $result1" -ForegroundColor $(if ($result1) { "Green" } else { "Red" })
        
        $result2 = Test-PSThreadOptions -Value "Default"
        Write-Host "Test-PSThreadOptions -Value 'Default' = $result2" -ForegroundColor $(if ($result2) { "Green" } else { "Red" })
        
        $result3 = Test-PSThreadOptions -Value "default"
        Write-Host "Test-PSThreadOptions -Value 'default' = $result3" -ForegroundColor $(if ($result3) { "Green" } else { "Red" })
        
        $result4 = Test-PSThreadOptions -Value "default" -IgnoreCase $false
        Write-Host "Test-PSThreadOptions -Value 'default' -IgnoreCase `$false = $result4" -ForegroundColor $(if (!$result4) { "Green" } else { "Red" })
        
        $result5 = Test-PSThreadOptions -Value 0
        Write-Host "Test-PSThreadOptions -Value 0 = $result5" -ForegroundColor $(if ($result5) { "Green" } else { "Red" })
        
        $result6 = Test-PSThreadOptions -Value 1
        Write-Host "Test-PSThreadOptions -Value 1 = $result6" -ForegroundColor $(if ($result6) { "Green" } else { "Red" })
        
        $result7 = Test-PSThreadOptions -Value 2
        Write-Host "Test-PSThreadOptions -Value 2 = $result7" -ForegroundColor $(if ($result7) { "Green" } else { "Red" })
        
        $result8 = Test-PSThreadOptions -Value "InvalidValue"
        Write-Host "Test-PSThreadOptions -Value 'InvalidValue' = $result8" -ForegroundColor $(if (!$result8) { "Green" } else { "Red" })
        
        $result9 = Test-PSThreadOptions -Value 999
        Write-Host "Test-PSThreadOptions -Value 999 = $result9" -ForegroundColor $(if (!$result9) { "Green" } else { "Red" })
    } catch {
        Write-Host "ERREUR: $_" -ForegroundColor Red
    }
    
    # Tester la journalisation des conversions
    Write-Host "`n=== Tests pour la journalisation des conversions ===" -ForegroundColor Magenta
    
    # Test 7: Write-ConversionLog
    Write-Host "`n--- Test 7: Write-ConversionLog ---" -ForegroundColor Cyan
    try {
        # Créer un dossier temporaire pour les logs
        $tempFolder = Join-Path -Path $env:TEMP -ChildPath "UnifiedParallelTests_$(Get-Random)"
        New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
        
        # Définir un chemin de log temporaire
        $tempLogPath = Join-Path -Path $tempFolder -ChildPath "ConversionLog.log"
        
        # Journaliser un message
        Write-ConversionLog -Message "Test de journalisation" -LogToFile $true -LogToConsole $true -LogFilePath $tempLogPath
        
        # Vérifier que le fichier de log a été créé
        if (Test-Path -Path $tempLogPath) {
            Write-Host "Fichier de log créé: $tempLogPath" -ForegroundColor Green
            $logContent = Get-Content -Path $tempLogPath -Raw
            Write-Host "Contenu du log:" -ForegroundColor Green
            Write-Host $logContent
        } else {
            Write-Host "ERREUR: Le fichier de log n'a pas été créé." -ForegroundColor Red
        }
        
        # Supprimer le dossier temporaire
        if (Test-Path -Path $tempFolder) {
            Remove-Item -Path $tempFolder -Recurse -Force
        }
    } catch {
        Write-Host "ERREUR: $_" -ForegroundColor Red
    }
    
    Write-Host "`n=== Tests terminés ===" -ForegroundColor Cyan
}

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"

# Exécuter les tests
Invoke-CompatibilityTests -ModulePath $modulePath
