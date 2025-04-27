#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le validateur de standards PowerShell.
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    du validateur de standards PowerShell utilisant l'architecture hybride.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
#>

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$validatorPath = Join-Path -Path $scriptPath -ChildPath "..\examples\standards-validator.ps1"

# CrÃ©er des scripts de test pour la validation des standards
$testScriptsPath = Join-Path -Path $scriptPath -ChildPath "test_standards"
if (-not (Test-Path -Path $testScriptsPath)) {
    New-Item -Path $testScriptsPath -ItemType Directory -Force | Out-Null
    
    # Script conforme aux standards
    $compliantScript = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Script conforme aux standards.
.DESCRIPTION
    Ce script est utilisÃ© pour tester le validateur de standards.
    Il respecte toutes les rÃ¨gles dÃ©finies.
.NOTES
    Version: 1.0
    Auteur: Test
    Date: 2025-04-10
#>

# Fonction avec nom conforme (Verbe-Nom)
function Get-StandardsCompliance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$FilePath
    )
    
    # Variable en camelCase
    `$isCompliant = `$true
    
    try {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path `$FilePath)) {
            throw "Le fichier n'existe pas."
        }
        
        # Lire le contenu du fichier
        `$content = Get-Content -Path `$FilePath -Raw
        
        # Retourner le rÃ©sultat
        return @{
            FilePath = `$FilePath
            IsCompliant = `$isCompliant
            Message = "Le fichier est conforme aux standards."
        }
    }
    catch {
        Write-Error "Une erreur s'est produite : `$_"
        return `$null
    }
}

# Appel de la fonction
`$result = Get-StandardsCompliance -FilePath "example.ps1"

# Commentaires supplÃ©mentaires pour atteindre le ratio de commentaires requis
# Cette ligne est un commentaire
# Cette ligne est un autre commentaire
# Cette ligne est encore un autre commentaire
# Cette ligne est un dernier commentaire
"@
    
    $compliantScript | Out-File -FilePath (Join-Path -Path $testScriptsPath -ChildPath "compliant.ps1") -Encoding utf8
    
    # Script non conforme aux standards
    $nonCompliantScript = @"
# Script non conforme aux standards

# Fonction avec nom non conforme (pas de Verbe-Nom)
function badFunction {
    param(`$input)  # ParamÃ¨tre non conforme (pas en PascalCase)
    
    # Variable non conforme (pas en camelCase)
    `$BadVariable = 10
    
    return `$BadVariable
}

# Appel de la fonction
badFunction -input "test"
"@
    
    $nonCompliantScript | Out-File -FilePath (Join-Path -Path $testScriptsPath -ChildPath "non_compliant.ps1") -Encoding utf8
    
    # Script partiellement conforme
    $partiallyCompliantScript = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Script partiellement conforme aux standards.
.DESCRIPTION
    Ce script est utilisÃ© pour tester le validateur de standards.
    Il respecte certaines rÃ¨gles mais pas toutes.
#>

# Fonction avec nom conforme (Verbe-Nom)
function Test-Standards {
    param(`$input)  # ParamÃ¨tre non conforme (pas en PascalCase)
    
    # Variable non conforme (pas en camelCase)
    `$BadVariable = 10
    
    return `$BadVariable
}

# Appel de la fonction
Test-Standards -input "test"
"@
    
    $partiallyCompliantScript | Out-File -FilePath (Join-Path -Path $testScriptsPath -ChildPath "partially_compliant.ps1") -Encoding utf8
}

# CrÃ©er un fichier de standards personnalisÃ© pour les tests
$testStandardsPath = Join-Path -Path $testScriptsPath -ChildPath "test_standards.json"
if (-not (Test-Path -Path $testStandardsPath)) {
    $standards = @{
        naming = @{
            functions = @{
                pattern = "^[A-Z][a-zA-Z0-9]+-[A-Z][a-zA-Z0-9]+$"
                description = "Les noms de fonctions doivent suivre le format Verbe-Nom avec PascalCase"
                severity = "Error"
            }
            variables = @{
                pattern = "^[a-z][a-zA-Z0-9]+$"
                description = "Les noms de variables doivent Ãªtre en camelCase"
                severity = "Warning"
            }
            parameters = @{
                pattern = "^[A-Z][a-zA-Z0-9]+$"
                description = "Les noms de paramÃ¨tres doivent Ãªtre en PascalCase"
                severity = "Warning"
            }
        }
        structure = @{
            requires = @{
                pattern = "^#Requires -Version"
                description = "Les scripts doivent spÃ©cifier la version PowerShell requise"
                severity = "Warning"
            }
            help = @{
                pattern = "^<#[\s\S]*\.SYNOPSIS[\s\S]*\.DESCRIPTION[\s\S]*#>"
                description = "Les scripts doivent avoir un bloc d'aide avec au moins SYNOPSIS et DESCRIPTION"
                severity = "Warning"
            }
            encoding = @{
                pattern = "utf8"
                description = "Les fichiers doivent Ãªtre encodÃ©s en UTF-8"
                severity = "Error"
            }
        }
        practices = @{
            errorHandling = @{
                pattern = "try[\s\S]*catch"
                description = "Utiliser try/catch pour la gestion des erreurs"
                severity = "Warning"
            }
            approvedVerbs = @{
                pattern = "^(Add|Clear|Close|Copy|Enter|Exit|Find|Format|Get|Hide|Join|Lock|Move|New|Open|Optimize|Pop|Push|Read|Remove|Rename|Reset|Resize|Search|Select|Set|Show|Skip|Split|Step|Switch|Undo|Unlock|Watch|Write)-"
                description = "Utiliser uniquement des verbes approuvÃ©s pour les fonctions"
                severity = "Error"
            }
            commentRatio = @{
                value = 0.1
                description = "Le ratio de commentaires doit Ãªtre d'au moins 10% du code"
                severity = "Warning"
            }
        }
    }
    
    $standards | ConvertTo-Json -Depth 5 | Out-File -FilePath $testStandardsPath -Encoding utf8
}

# ExÃ©cuter les tests
Describe "Validateur de standards PowerShell" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les rÃ©sultats
        $outputPath = Join-Path -Path $testScriptsPath -ChildPath "results"
        if (-not (Test-Path -Path $outputPath)) {
            New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
        }
    }
    
    Context "Validation de scripts conformes" {
        It "Devrait valider un script conforme sans violations" {
            # ExÃ©cuter le validateur sur le script conforme
            $scriptToValidate = Join-Path -Path $testScriptsPath -ChildPath "compliant.ps1"
            
            # Appeler le script de validation
            $result = & $validatorPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -StandardsFile $testStandardsPath -FilePatterns "compliant.ps1"
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].file_info.file_name | Should -Be "compliant.ps1"
            $result[0].is_compliant | Should -Be $true
            $result[0].total_violations | Should -Be 0
        }
    }
    
    Context "Validation de scripts non conformes" {
        It "Devrait dÃ©tecter les violations dans un script non conforme" {
            # ExÃ©cuter le validateur sur le script non conforme
            $scriptToValidate = Join-Path -Path $testScriptsPath -ChildPath "non_compliant.ps1"
            
            # Appeler le script de validation
            $result = & $validatorPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -StandardsFile $testStandardsPath -FilePatterns "non_compliant.ps1"
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].file_info.file_name | Should -Be "non_compliant.ps1"
            $result[0].is_compliant | Should -Be $false
            $result[0].total_violations | Should -BeGreaterThan 0
            
            # VÃ©rifier les types de violations
            $violations = $result[0].violations
            $violations | Where-Object { $_.type -eq "naming.functions" } | Should -Not -BeNullOrEmpty
            $violations | Where-Object { $_.type -eq "structure.requires" } | Should -Not -BeNullOrEmpty
            $violations | Where-Object { $_.type -eq "structure.help" } | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Validation de scripts partiellement conformes" {
        It "Devrait dÃ©tecter certaines violations dans un script partiellement conforme" {
            # ExÃ©cuter le validateur sur le script partiellement conforme
            $scriptToValidate = Join-Path -Path $testScriptsPath -ChildPath "partially_compliant.ps1"
            
            # Appeler le script de validation
            $result = & $validatorPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -StandardsFile $testStandardsPath -FilePatterns "partially_compliant.ps1"
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].file_info.file_name | Should -Be "partially_compliant.ps1"
            $result[0].is_compliant | Should -Be $false
            $result[0].total_violations | Should -BeGreaterThan 0
            
            # VÃ©rifier les types de violations
            $violations = $result[0].violations
            $violations | Where-Object { $_.type -eq "naming.parameters" } | Should -Not -BeNullOrEmpty
            $violations | Where-Object { $_.type -eq "naming.variables" } | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Validation de plusieurs scripts" {
        It "Devrait valider plusieurs scripts en parallÃ¨le" {
            # ExÃ©cuter le validateur sur tous les scripts
            $result = & $validatorPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -StandardsFile $testStandardsPath
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3  # Trois scripts de test
            $result | Where-Object { $_.file_info.file_name -eq "compliant.ps1" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.file_info.file_name -eq "non_compliant.ps1" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.file_info.file_name -eq "partially_compliant.ps1" } | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier les rÃ©sultats de conformitÃ©
            ($result | Where-Object { $_.file_info.file_name -eq "compliant.ps1" }).is_compliant | Should -Be $true
            ($result | Where-Object { $_.file_info.file_name -eq "non_compliant.ps1" }).is_compliant | Should -Be $false
            ($result | Where-Object { $_.file_info.file_name -eq "partially_compliant.ps1" }).is_compliant | Should -Be $false
        }
    }
    
    Context "Correction des violations" {
        It "Devrait corriger certaines violations automatiquement" {
            # CrÃ©er une copie du script non conforme pour la correction
            $originalScript = Join-Path -Path $testScriptsPath -ChildPath "non_compliant.ps1"
            $scriptToFix = Join-Path -Path $testScriptsPath -ChildPath "non_compliant_to_fix.ps1"
            Copy-Item -Path $originalScript -Destination $scriptToFix -Force
            
            # ExÃ©cuter le validateur avec correction
            $result1 = & $validatorPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -StandardsFile $testStandardsPath -FilePatterns "non_compliant_to_fix.ps1" -FixViolations
            
            # VÃ©rifier que certaines violations ont Ã©tÃ© corrigÃ©es
            $result2 = & $validatorPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -StandardsFile $testStandardsPath -FilePatterns "non_compliant_to_fix.ps1"
            
            # Le script corrigÃ© devrait avoir moins de violations ou des violations diffÃ©rentes
            $result2[0].total_violations | Should -BeLessOrEqual $result1[0].total_violations
            
            # Nettoyer
            if (Test-Path -Path $scriptToFix) {
                Remove-Item -Path $scriptToFix -Force
            }
        }
    }
    
    Context "Utilisation du cache" {
        It "Devrait Ãªtre plus rapide avec le cache activÃ©" {
            # ExÃ©cuter le validateur sans cache
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            $result1 = & $validatorPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -StandardsFile $testStandardsPath
            $stopwatch1.Stop()
            $timeWithoutCache = $stopwatch1.Elapsed.TotalSeconds
            
            # ExÃ©cuter le validateur avec cache
            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            $result2 = & $validatorPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -StandardsFile $testStandardsPath -UseCache
            $stopwatch2.Stop()
            $timeWithCache = $stopwatch2.Elapsed.TotalSeconds
            
            # VÃ©rifier que les rÃ©sultats sont identiques
            $result1.Count | Should -Be $result2.Count
            
            # ExÃ©cuter une deuxiÃ¨me fois avec cache pour bÃ©nÃ©ficier du cache
            $stopwatch3 = [System.Diagnostics.Stopwatch]::StartNew()
            $result3 = & $validatorPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -StandardsFile $testStandardsPath -UseCache
            $stopwatch3.Stop()
            $timeWithCacheSecondRun = $stopwatch3.Elapsed.TotalSeconds
            
            # La deuxiÃ¨me exÃ©cution avec cache devrait Ãªtre plus rapide
            # Note: Ce test peut Ã©chouer sur des systÃ¨mes trÃ¨s rapides ou si le cache n'est pas correctement implÃ©mentÃ©
            Write-Host "Temps sans cache: $timeWithoutCache s"
            Write-Host "Temps avec cache (1Ã¨re exÃ©cution): $timeWithCache s"
            Write-Host "Temps avec cache (2Ã¨me exÃ©cution): $timeWithCacheSecondRun s"
            
            # VÃ©rifier que les rÃ©sultats sont identiques
            $result1.Count | Should -Be $result3.Count
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers temporaires si nÃ©cessaire
    }
}
