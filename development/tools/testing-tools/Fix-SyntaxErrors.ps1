#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige les erreurs de syntaxe dans les fichiers de test.

.DESCRIPTION
    Ce script corrige les erreurs de syntaxe courantes dans les fichiers de test,
    notamment les accolades supplÃ©mentaires et les lignes mal formatÃ©es.

.PARAMETER TestFile
    Le fichier de test Ã  corriger. Si non spÃ©cifiÃ©, tous les fichiers de test seront corrigÃ©s.

.EXAMPLE
    .\Fix-SyntaxErrors.ps1
    Corrige les erreurs de syntaxe dans tous les fichiers de test.

.EXAMPLE
    .\Fix-SyntaxErrors.ps1 -TestFile "Format-Converters.Tests.ps1"
    Corrige les erreurs de syntaxe dans le fichier Format-Converters.Tests.ps1.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TestFile
)

# Fonction pour corriger les erreurs de syntaxe dans un fichier de test
function Repair-SyntaxErrors {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    Write-Host "Correction des erreurs de syntaxe dans le fichier : $FilePath" -ForegroundColor Cyan
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    # CrÃ©er une copie de sauvegarde du fichier
    $backupPath = "$FilePath.backup"
    Copy-Item -Path $FilePath -Destination $backupPath -Force
    Write-Host "Copie de sauvegarde crÃ©Ã©e : $backupPath" -ForegroundColor Yellow
    
    # Corriger les erreurs de syntaxe spÃ©cifiques Ã  Format-Converters.Tests.ps1
    if ($FilePath -like "*Format-Converters.Tests.ps1") {
        # Corriger l'accolade supplÃ©mentaire Ã  la ligne 67
        $content = $content -replace "return \`$filePath\r?\n\}\r?\n\}", "return `$filePath`r`n}"
        
        # Corriger l'accolade supplÃ©mentaire Ã  la ligne 597
        $content = $content -replace "\$xmlResult\.DetectedFormat \| Should -Be `"XML`"\r?\n\s+\}\r?\n\s+\}\r?\n\}", "`$xmlResult.DetectedFormat | Should -Be `"XML`"`r`n        }`r`n    }"
        
        # Corriger les lignes mal formatÃ©es autour de la ligne 618
        $content = $content -replace "\.SourceFormat -eq \`$SourceFormat \}\r?\n\s+\}\r?\n\s+if \(\`$TargetFormat\) \{\r?\n\s+\`$converters = \`$converters \| Where-Object \{ #Requires", "# Corrected content`r`n    if (`$TargetFormat) {`r`n        `$converters = `$converters | Where-Object { `$_.TargetFormat -eq `$TargetFormat }`r`n    }`r`n    `r`n    return `$converters`r`n}`r`n`r`n#Requires"
        
        # Corriger les lignes mal formatÃ©es autour de la ligne 1135
        $content = $content -replace "\.TargetFormat -eq \`$TargetFormat \}\r?\n\s+\}\r?\n\s+return \`$converters\r?\n\}\r?\n\}", "# Removed duplicate content"
    }
    
    # Enregistrer les modifications
    $content | Set-Content -Path $FilePath -Encoding UTF8
    
    Write-Host "Erreurs de syntaxe corrigÃ©es dans le fichier : $FilePath" -ForegroundColor Green
}

# Obtenir les fichiers de test Ã  corriger
$testFiles = @()

if ($TestFile) {
    $testFilePath = Join-Path -Path $PSScriptRoot -ChildPath $TestFile
    if (Test-Path -Path $testFilePath -PathType Leaf) {
        $testFiles += $testFilePath
    }
    else {
        Write-Error "Le fichier de test '$TestFile' n'existe pas."
        exit 1
    }
}
else {
    $testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" | 
        Where-Object { $_.Name -notlike "*.Simplified.ps1" } |
        ForEach-Object { $_.FullName }
}

# Corriger les erreurs de syntaxe dans chaque fichier de test
foreach ($file in $testFiles) {
    Repair-SyntaxErrors -FilePath $file
}

Write-Host "`nLes erreurs de syntaxe ont Ã©tÃ© corrigÃ©es dans tous les fichiers de test." -ForegroundColor Green
Write-Host "ExÃ©cutez les tests pour vÃ©rifier si les problÃ¨mes ont Ã©tÃ© rÃ©solus." -ForegroundColor Green
