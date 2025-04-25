<#
.SYNOPSIS
    Tests unitaires pour la fonctionnalité de gestion des erreurs avancée du système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script contient des tests unitaires pour la fonctionnalité de gestion des erreurs avancée du système d'apprentissage des erreurs.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Définir les tests Pester
Describe "Tests de gestion des erreurs avancée" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "AdvancedErrorHandlingTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        
        # Définir les fonctions de gestion des erreurs avancée
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
                # Créer le dossier de sortie s'il n'existe pas
                if (-not (Test-Path -Path $OutputPath)) {
                    New-Item -Path $OutputPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }
                
                # Générer un ID unique pour l'erreur
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
                Write-Error "Erreur lors de la création du rapport d'erreur: $_"
                return $null
            }
        }
        
        function Get-ErrorStatistics {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $false)]
                [string]$ErrorReportsPath = (Join-Path -Path $script:testRoot -ChildPath "ErrorReports"),
                
                [Parameter(Mandatory = $false)]
                [string]$Category = $null,
                
                [Parameter(Mandatory = $false)]
                [string]$Source = $null,
                
                [Parameter(Mandatory = $false)]
                [DateTime]$StartDate = [DateTime]::MinValue,
                
                [Parameter(Mandatory = $false)]
                [DateTime]$EndDate = [DateTime]::MaxValue
            )
            
            try {
                # Vérifier que le dossier des rapports d'erreur existe
                if (-not (Test-Path -Path $ErrorReportsPath)) {
                    Write-Warning "Le dossier des rapports d'erreur '$ErrorReportsPath' n'existe pas."
                    return $null
                }
                
                # Récupérer tous les fichiers de rapport d'erreur
                $errorFiles = Get-ChildItem -Path $ErrorReportsPath -Filter "*.json" -File
                
                if ($errorFiles.Count -eq 0) {
                    Write-Warning "Aucun rapport d'erreur trouvé dans le dossier '$ErrorReportsPath'."
                    return $null
                }
                
                # Charger les rapports d'erreur
                $errorReports = @()
                foreach ($file in $errorFiles) {
                    $errorReport = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                    
                    # Convertir la date
                    if ($errorReport.Timestamp -is [string]) {
                        $errorReport.Timestamp = [DateTime]::Parse($errorReport.Timestamp)
                    }
                    
                    # Filtrer par catégorie
                    if ($Category -and $errorReport.Category -ne $Category) {
                        continue
                    }
                    
                    # Filtrer par source
                    if ($Source -and $errorReport.Source -ne $Source) {
                        continue
                    }
                    
                    # Filtrer par date
                    if ($errorReport.Timestamp -lt $StartDate -or $errorReport.Timestamp -gt $EndDate) {
                        continue
                    }
                    
                    $errorReports += $errorReport
                }
                
                # Calculer les statistiques
                $statistics = [PSCustomObject]@{
                    TotalErrors = $errorReports.Count
                    ErrorsByCategory = @{}
                    ErrorsBySource = @{}
                    ErrorsByDate = @{}
                    MostCommonErrors = @()
                    RecentErrors = @()
                }
                
                # Erreurs par catégorie
                $errorReports | Group-Object -Property Category | ForEach-Object {
                    $statistics.ErrorsByCategory[$_.Name] = $_.Count
                }
                
                # Erreurs par source
                $errorReports | Group-Object -Property Source | ForEach-Object {
                    $statistics.ErrorsBySource[$_.Name] = $_.Count
                }
                
                # Erreurs par date
                $errorReports | Group-Object -Property { $_.Timestamp.Date } | ForEach-Object {
                    $statistics.ErrorsByDate[$_.Name] = $_.Count
                }
                
                # Erreurs les plus courantes
                $statistics.MostCommonErrors = $errorReports | Group-Object -Property Message | Sort-Object -Property Count -Descending | Select-Object -First 5 | ForEach-Object {
                    [PSCustomObject]@{
                        Message = $_.Name
                        Count = $_.Count
                    }
                }
                
                # Erreurs récentes
                $statistics.RecentErrors = $errorReports | Sort-Object -Property Timestamp -Descending | Select-Object -First 5
                
                return $statistics
            }
            catch {
                Write-Error "Erreur lors de la récupération des statistiques d'erreur: $_"
                return $null
            }
        }
        
        function Find-SimilarErrors {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$ErrorMessage,
                
                [Parameter(Mandatory = $false)]
                [string]$ErrorReportsPath = (Join-Path -Path $script:testRoot -ChildPath "ErrorReports"),
                
                [Parameter(Mandatory = $false)]
                [int]$MaxResults = 5,
                
                [Parameter(Mandatory = $false)]
                [int]$MinSimilarityScore = 70
            )
            
            try {
                # Vérifier que le dossier des rapports d'erreur existe
                if (-not (Test-Path -Path $ErrorReportsPath)) {
                    Write-Warning "Le dossier des rapports d'erreur '$ErrorReportsPath' n'existe pas."
                    return $null
                }
                
                # Récupérer tous les fichiers de rapport d'erreur
                $errorFiles = Get-ChildItem -Path $ErrorReportsPath -Filter "*.json" -File
                
                if ($errorFiles.Count -eq 0) {
                    Write-Warning "Aucun rapport d'erreur trouvé dans le dossier '$ErrorReportsPath'."
                    return $null
                }
                
                # Charger les rapports d'erreur
                $errorReports = @()
                foreach ($file in $errorFiles) {
                    $errorReport = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                    $errorReports += $errorReport
                }
                
                # Calculer la similarité entre les messages d'erreur
                $similarErrors = @()
                foreach ($report in $errorReports) {
                    $similarityScore = Get-StringSimilarity -String1 $ErrorMessage -String2 $report.Message
                    
                    if ($similarityScore -ge $MinSimilarityScore) {
                        $similarErrors += [PSCustomObject]@{
                            ErrorId = $report.ErrorId
                            Message = $report.Message
                            SimilarityScore = $similarityScore
                            Source = $report.Source
                            Category = $report.Category
                            Timestamp = $report.Timestamp
                        }
                    }
                }
                
                # Trier les erreurs par score de similarité
                $similarErrors = $similarErrors | Sort-Object -Property SimilarityScore -Descending | Select-Object -First $MaxResults
                
                return $similarErrors
            }
            catch {
                Write-Error "Erreur lors de la recherche d'erreurs similaires: $_"
                return $null
            }
        }
        
        function Get-StringSimilarity {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$String1,
                
                [Parameter(Mandatory = $true)]
                [string]$String2
            )
            
            try {
                # Fonction simplifiée pour calculer la similarité entre deux chaînes
                # Dans un environnement réel, on utiliserait un algorithme plus sophistiqué
                
                # Convertir les chaînes en minuscules
                $s1 = $String1.ToLower()
                $s2 = $String2.ToLower()
                
                # Calculer la distance de Levenshtein simplifiée
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
                
                # Calculer le score de similarité
                $similarityScore = ($commonChars / $maxLength) * 100
                
                return [Math]::Round($similarityScore, 2)
            }
            catch {
                Write-Error "Erreur lors du calcul de la similarité entre les chaînes: $_"
                return 0
            }
        }
    }
    
    Context "Fonction New-ErrorReport" {
        It "Devrait créer un rapport d'erreur" {
            # Créer une erreur factice
            $exception = New-Object System.Exception("Erreur de test")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # Créer un rapport d'erreur
            $errorReport = New-ErrorReport -ErrorRecord $errorRecord -Source "TestSource" -Category "TestCategory"
            
            # Vérifier que le rapport a été créé correctement
            $errorReport | Should -Not -BeNullOrEmpty
            $errorReport.ErrorId | Should -Not -BeNullOrEmpty
            $errorReport.Source | Should -Be "TestSource"
            $errorReport.Category | Should -Be "TestCategory"
            $errorReport.Message | Should -Be "Erreur de test"
            
            # Vérifier que le fichier a été créé
            $errorFilePath = Join-Path -Path (Join-Path -Path $script:testRoot -ChildPath "ErrorReports") -ChildPath "$($errorReport.ErrorId).json"
            Test-Path -Path $errorFilePath | Should -BeTrue
        }
    }
    
    Context "Fonction Get-ErrorStatistics" {
        BeforeEach {
            # Créer plusieurs rapports d'erreur
            $errorReportsPath = Join-Path -Path $script:testRoot -ChildPath "ErrorReports"
            if (-not (Test-Path -Path $errorReportsPath)) {
                New-Item -Path $errorReportsPath -ItemType Directory -Force | Out-Null
            }
            
            # Créer des erreurs factices
            $errorCategories = @("Syntax", "Runtime", "Logic")
            $errorSources = @("Script1", "Script2", "Script3")
            
            for ($i = 0; $i -lt 10; $i++) {
                $exception = New-Object System.Exception("Erreur de test $i")
                $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                    $exception,
                    "TestError$i",
                    [System.Management.Automation.ErrorCategory]::NotSpecified,
                    $null
                )
                
                $category = $errorCategories[$i % $errorCategories.Count]
                $source = $errorSources[$i % $errorSources.Count]
                
                New-ErrorReport -ErrorRecord $errorRecord -Source $source -Category $category | Out-Null
            }
        }
        
        It "Devrait récupérer les statistiques d'erreur" {
            # Récupérer les statistiques d'erreur
            $statistics = Get-ErrorStatistics
            
            # Vérifier que les statistiques ont été récupérées correctement
            $statistics | Should -Not -BeNullOrEmpty
            $statistics.TotalErrors | Should -Be 10
            $statistics.ErrorsByCategory.Count | Should -Be 3
            $statistics.ErrorsBySource.Count | Should -Be 3
            $statistics.MostCommonErrors | Should -Not -BeNullOrEmpty
            $statistics.RecentErrors | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait filtrer les statistiques par catégorie" {
            # Récupérer les statistiques d'erreur filtrées par catégorie
            $statistics = Get-ErrorStatistics -Category "Syntax"
            
            # Vérifier que les statistiques ont été filtrées correctement
            $statistics | Should -Not -BeNullOrEmpty
            $statistics.TotalErrors | Should -BeGreaterThan 0
            $statistics.TotalErrors | Should -BeLessOrEqual 10
            $statistics.ErrorsByCategory.Count | Should -Be 1
            $statistics.ErrorsByCategory["Syntax"] | Should -Be $statistics.TotalErrors
        }
        
        It "Devrait filtrer les statistiques par source" {
            # Récupérer les statistiques d'erreur filtrées par source
            $statistics = Get-ErrorStatistics -Source "Script1"
            
            # Vérifier que les statistiques ont été filtrées correctement
            $statistics | Should -Not -BeNullOrEmpty
            $statistics.TotalErrors | Should -BeGreaterThan 0
            $statistics.TotalErrors | Should -BeLessOrEqual 10
            $statistics.ErrorsBySource.Count | Should -Be 1
            $statistics.ErrorsBySource["Script1"] | Should -Be $statistics.TotalErrors
        }
    }
    
    Context "Fonction Find-SimilarErrors" {
        BeforeEach {
            # Créer plusieurs rapports d'erreur
            $errorReportsPath = Join-Path -Path $script:testRoot -ChildPath "ErrorReports"
            if (-not (Test-Path -Path $errorReportsPath)) {
                New-Item -Path $errorReportsPath -ItemType Directory -Force | Out-Null
            }
            else {
                # Vider le dossier
                Remove-Item -Path (Join-Path -Path $errorReportsPath -ChildPath "*") -Force
            }
            
            # Créer des erreurs factices avec des messages similaires
            $errorMessages = @(
                "Impossible de trouver le chemin d'accès 'C:\config.txt'",
                "Impossible de trouver le chemin d'accès 'C:\data.txt'",
                "Impossible de trouver le chemin d'accès 'D:\logs\app.log'",
                "Erreur de syntaxe près de 'if ('",
                "Erreur de syntaxe près de 'foreach ('",
                "La variable '$data' est utilisée mais n'a pas été définie",
                "La variable '$config' est utilisée mais n'a pas été définie",
                "Accès refusé au fichier 'C:\Windows\System32\config.sys'",
                "Accès refusé au fichier 'C:\Windows\System32\drivers\etc\hosts'",
                "Le service 'WinRM' n'a pas pu être démarré"
            )
            
            for ($i = 0; $i -lt $errorMessages.Count; $i++) {
                $exception = New-Object System.Exception($errorMessages[$i])
                $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                    $exception,
                    "TestError$i",
                    [System.Management.Automation.ErrorCategory]::NotSpecified,
                    $null
                )
                
                New-ErrorReport -ErrorRecord $errorRecord -Source "TestSource" -Category "TestCategory" | Out-Null
            }
        }
        
        It "Devrait trouver des erreurs similaires" {
            # Rechercher des erreurs similaires
            $similarErrors = Find-SimilarErrors -ErrorMessage "Impossible de trouver le chemin d'accès 'C:\temp\file.txt'"
            
            # Vérifier que des erreurs similaires ont été trouvées
            $similarErrors | Should -Not -BeNullOrEmpty
            $similarErrors.Count | Should -BeGreaterThan 0
            $similarErrors[0].SimilarityScore | Should -BeGreaterThan 70
        }
        
        It "Devrait limiter le nombre de résultats" {
            # Rechercher des erreurs similaires avec une limite de résultats
            $similarErrors = Find-SimilarErrors -ErrorMessage "Erreur de syntaxe" -MaxResults 2
            
            # Vérifier que le nombre de résultats est limité
            $similarErrors | Should -Not -BeNullOrEmpty
            $similarErrors.Count | Should -BeLessOrEqual 2
        }
        
        It "Devrait filtrer les résultats par score de similarité" {
            # Rechercher des erreurs similaires avec un score de similarité minimum élevé
            $similarErrors = Find-SimilarErrors -ErrorMessage "Erreur de syntaxe" -MinSimilarityScore 90
            
            # Vérifier que les résultats sont filtrés par score de similarité
            if ($similarErrors) {
                $similarErrors[0].SimilarityScore | Should -BeGreaterOrEqual 90
            }
        }
    }
    
    Context "Fonction Get-StringSimilarity" {
        It "Devrait calculer la similarité entre deux chaînes identiques" {
            # Calculer la similarité entre deux chaînes identiques
            $similarityScore = Get-StringSimilarity -String1 "Test string" -String2 "Test string"
            
            # Vérifier que le score est de 100%
            $similarityScore | Should -Be 100
        }
        
        It "Devrait calculer la similarité entre deux chaînes différentes" {
            # Calculer la similarité entre deux chaînes différentes
            $similarityScore = Get-StringSimilarity -String1 "Test string" -String2 "Test strong"
            
            # Vérifier que le score est inférieur à 100%
            $similarityScore | Should -BeLessThan 100
            $similarityScore | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer la similarité entre deux chaînes complètement différentes" {
            # Calculer la similarité entre deux chaînes complètement différentes
            $similarityScore = Get-StringSimilarity -String1 "Test string" -String2 "Completely different"
            
            # Vérifier que le score est faible
            $similarityScore | Should -BeLessThan 50
        }
        
        It "Devrait gérer les chaînes vides" {
            # Calculer la similarité avec une chaîne vide
            $similarityScore = Get-StringSimilarity -String1 "" -String2 ""
            
            # Vérifier que le score est de 100%
            $similarityScore | Should -Be 100
        }
    }
    
    AfterAll {
        # Supprimer le répertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }
}
