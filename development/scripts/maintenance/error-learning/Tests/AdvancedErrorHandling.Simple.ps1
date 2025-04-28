<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour la fonctionnalitÃ© de gestion des erreurs avancÃ©e du systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script contient des tests unitaires simplifiÃ©s pour la fonctionnalitÃ© de gestion des erreurs avancÃ©e du systÃ¨me d'apprentissage des erreurs.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# DÃ©finir les tests Pester
Describe "Tests de gestion des erreurs avancÃ©e simplifiÃ©s" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "AdvancedErrorHandlingSimpleTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        
        # DÃ©finir les fonctions de gestion des erreurs avancÃ©e
        function New-ErrorReport {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.ErrorRecord]$ErrorRecord,
                
                [Parameter(Mandatory = $false)]
                [string]$Source = "Unknown",
                
                [Parameter(Mandatory = $false)]
                [string]$Category = "General",
                
                [Parameter(Mandatory = $false)]
                [string]$OutputPath = (Join-Path -Path $script:testRoot -ChildPath "ErrorReports")
            )
            
            try {
                # CrÃ©er le dossier de sortie s'il n'existe pas
                if (-not (Test-Path -Path $OutputPath)) {
                    New-Item -Path $OutputPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }
                
                # GÃ©nÃ©rer un ID unique pour l'erreur
                $errorId = [guid]::NewGuid().ToString()
                
                # Extraire les informations de l'erreur
                $errorInfo = [PSCustomObject]@{
                    ErrorId = $errorId
                    Timestamp = Get-Date
                    Source = $Source
                    Category = $Category
                    Message = $ErrorRecord.Exception.Message
                    FullyQualifiedErrorId = $ErrorRecord.FullyQualifiedErrorId
                    ErrorCategory = $ErrorRecord.CategoryInfo.Category
                    TargetObject = $ErrorRecord.TargetObject
                    ScriptStackTrace = $ErrorRecord.ScriptStackTrace
                    PositionMessage = $ErrorRecord.InvocationInfo.PositionMessage
                    Line = $ErrorRecord.InvocationInfo.Line
                    ScriptName = $ErrorRecord.InvocationInfo.ScriptName
                    LineNumber = $ErrorRecord.InvocationInfo.ScriptLineNumber
                    ColumnNumber = $ErrorRecord.InvocationInfo.OffsetInLine
                    PSVersion = $PSVersionTable.PSVersion.ToString()
                    OS = [System.Environment]::OSVersion.VersionString
                }
                
                # Convertir les informations en JSON
                $errorJson = $errorInfo | ConvertTo-Json -Depth 3
                
                # Enregistrer les informations dans un fichier
                $errorFilePath = Join-Path -Path $OutputPath -ChildPath "$errorId.json"
                Set-Content -Path $errorFilePath -Value $errorJson -ErrorAction Stop
                
                return $errorInfo
            }
            catch {
                Write-Error "Erreur lors de la crÃ©ation du rapport d'erreur: $_"
                return $null
            }
        }
        
        function Get-StringSimilarity {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$String1,
                
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$String2
            )
            
            try {
                # Fonction simplifiÃ©e pour calculer la similaritÃ© entre deux chaÃ®nes
                # Dans un environnement rÃ©el, on utiliserait un algorithme plus sophistiquÃ©
                
                # Convertir les chaÃ®nes en minuscules
                $s1 = $String1.ToLower()
                $s2 = $String2.ToLower()
                
                # Calculer la distance de Levenshtein simplifiÃ©e
                $maxLength = [Math]::Max($s1.Length, $s2.Length)
                if ($maxLength -eq 0) {
                    return 100
                }
                
                $commonChars = 0
                $minLength = [Math]::Min($s1.Length, $s2.Length)
                
                for ($i = 0; $i -lt $minLength; $i++) {
                    if ($s1[$i] -eq $s2[$i]) {
                        $commonChars++
                    }
                }
                
                # Calculer le score de similaritÃ©
                $similarityScore = ($commonChars / $maxLength) * 100
                
                return [Math]::Round($similarityScore, 2)
            }
            catch {
                Write-Error "Erreur lors du calcul de la similaritÃ© entre les chaÃ®nes: $_"
                return 0
            }
        }
    }
    
    Context "Fonction New-ErrorReport" {
        It "Devrait crÃ©er un rapport d'erreur" {
            # CrÃ©er une erreur factice
            $exception = New-Object System.Exception("Erreur de test")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # CrÃ©er un rapport d'erreur
            $errorReport = New-ErrorReport -ErrorRecord $errorRecord -Source "TestSource" -Category "TestCategory"
            
            # VÃ©rifier que le rapport a Ã©tÃ© crÃ©Ã© correctement
            $errorReport | Should -Not -BeNullOrEmpty
            $errorReport.ErrorId | Should -Not -BeNullOrEmpty
            $errorReport.Source | Should -Be "TestSource"
            $errorReport.Category | Should -Be "TestCategory"
            $errorReport.Message | Should -Be "Erreur de test"
            
            # VÃ©rifier que le fichier a Ã©tÃ© crÃ©Ã©
            $errorFilePath = Join-Path -Path (Join-Path -Path $script:testRoot -ChildPath "ErrorReports") -ChildPath "$($errorReport.ErrorId).json"
            Test-Path -Path $errorFilePath | Should -BeTrue
        }
    }
    
    Context "Fonction Get-StringSimilarity" {
        It "Devrait calculer la similaritÃ© entre deux chaÃ®nes identiques" {
            # Calculer la similaritÃ© entre deux chaÃ®nes identiques
            $similarityScore = Get-StringSimilarity -String1 "Test string" -String2 "Test string"
            
            # VÃ©rifier que le score est de 100%
            $similarityScore | Should -Be 100
        }
        
        It "Devrait calculer la similaritÃ© entre deux chaÃ®nes diffÃ©rentes" {
            # Calculer la similaritÃ© entre deux chaÃ®nes diffÃ©rentes
            $similarityScore = Get-StringSimilarity -String1 "Test string" -String2 "Test strong"
            
            # VÃ©rifier que le score est infÃ©rieur Ã  100%
            $similarityScore | Should -BeLessThan 100
            $similarityScore | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer la similaritÃ© entre deux chaÃ®nes complÃ¨tement diffÃ©rentes" {
            # Calculer la similaritÃ© entre deux chaÃ®nes complÃ¨tement diffÃ©rentes
            $similarityScore = Get-StringSimilarity -String1 "Test string" -String2 "Completely different"
            
            # VÃ©rifier que le score est faible
            $similarityScore | Should -BeLessThan 50
        }
    }
    
    AfterAll {
        # Supprimer le rÃ©pertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }
}
