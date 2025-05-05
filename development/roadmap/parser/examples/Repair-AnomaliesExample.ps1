# Repair-AnomaliesExample.ps1
# Exemple d'utilisation du script de correction automatique des anomalies de permissions SQL Server

# Chemin du script de correction
$repairScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Repair-SqlPermissionAnomalies.ps1"

# Exemple 1: GÃƒÂ©nÃƒÂ©rer un script de correction pour toutes les anomalies rÃƒÂ©parables
$generateParams = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    GenerateScript = $true
    ScriptOutputPath = "C:\Temp\SqlPermissionRepairScript.sql"
    Verbose = $true
}

Write-Host "Exemple 1: GÃƒÂ©nÃƒÂ©ration d'un script de correction" -ForegroundColor Cyan
& $repairScriptPath @generateParams

# Exemple 2: Corriger automatiquement certaines anomalies spÃƒÂ©cifiques (avec WhatIf)
$repairParams = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    RuleIds = @("SVR-003", "SVR-004", "DB-005", "OBJ-002")  # RÃƒÂ¨gles spÃƒÂ©cifiques ÃƒÂ  corriger
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Verbose = $true
    WhatIf = $true  # Simuler l'exÃƒÂ©cution sans effectuer les corrections
}

Write-Host "Exemple 2: Correction automatique de rÃƒÂ¨gles spÃƒÂ©cifiques (simulation)" -ForegroundColor Cyan
& $repairScriptPath @repairParams

# Exemple 3: Corriger automatiquement toutes les anomalies rÃƒÂ©parables (avec confirmation)
$repairAllParams = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Verbose = $true
    Confirm = $true  # Demander confirmation avant chaque correction
}

Write-Host "Exemple 3: Correction automatique de toutes les anomalies rÃƒÂ©parables (avec confirmation)" -ForegroundColor Cyan
# & $repairScriptPath @repairAllParams  # DÃƒÂ©commenter pour exÃƒÂ©cuter

# Exemple 4: Corriger automatiquement toutes les anomalies rÃƒÂ©parables (sans confirmation)
$repairAllForceParams = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Force = $true  # Ne pas demander de confirmation
    Verbose = $true
}

Write-Host "Exemple 4: Correction automatique de toutes les anomalies rÃƒÂ©parables (sans confirmation)" -ForegroundColor Cyan
# & $repairScriptPath @repairAllForceParams  # DÃƒÂ©commenter pour exÃƒÂ©cuter
