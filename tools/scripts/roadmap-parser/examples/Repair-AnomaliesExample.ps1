# Repair-AnomaliesExample.ps1
# Exemple d'utilisation du script de correction automatique des anomalies de permissions SQL Server

# Chemin du script de correction
$repairScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Repair-SqlPermissionAnomalies.ps1"

# Exemple 1: GÃ©nÃ©rer un script de correction pour toutes les anomalies rÃ©parables
$generateParams = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    GenerateScript = $true
    ScriptOutputPath = "C:\Temp\SqlPermissionRepairScript.sql"
    Verbose = $true
}

Write-Host "Exemple 1: GÃ©nÃ©ration d'un script de correction" -ForegroundColor Cyan
& $repairScriptPath @generateParams

# Exemple 2: Corriger automatiquement certaines anomalies spÃ©cifiques (avec WhatIf)
$repairParams = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    RuleIds = @("SVR-003", "SVR-004", "DB-005", "OBJ-002")  # RÃ¨gles spÃ©cifiques Ã  corriger
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Verbose = $true
    WhatIf = $true  # Simuler l'exÃ©cution sans effectuer les corrections
}

Write-Host "Exemple 2: Correction automatique de rÃ¨gles spÃ©cifiques (simulation)" -ForegroundColor Cyan
& $repairScriptPath @repairParams

# Exemple 3: Corriger automatiquement toutes les anomalies rÃ©parables (avec confirmation)
$repairAllParams = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Verbose = $true
    Confirm = $true  # Demander confirmation avant chaque correction
}

Write-Host "Exemple 3: Correction automatique de toutes les anomalies rÃ©parables (avec confirmation)" -ForegroundColor Cyan
# & $repairScriptPath @repairAllParams  # DÃ©commenter pour exÃ©cuter

# Exemple 4: Corriger automatiquement toutes les anomalies rÃ©parables (sans confirmation)
$repairAllForceParams = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Force = $true  # Ne pas demander de confirmation
    Verbose = $true
}

Write-Host "Exemple 4: Correction automatique de toutes les anomalies rÃ©parables (sans confirmation)" -ForegroundColor Cyan
# & $repairScriptPath @repairAllForceParams  # DÃ©commenter pour exÃ©cuter
