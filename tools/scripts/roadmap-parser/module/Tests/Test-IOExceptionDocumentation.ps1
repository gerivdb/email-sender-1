<#
.SYNOPSIS
    Tests pour valider la documentation d'IOException et ses caractéristiques.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation d'IOException et ses caractéristiques.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-17
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir les tests
Describe "Tests de la documentation d'IOException et ses caractéristiques" {
    Context "IOException" {
        It "Devrait être une sous-classe de SystemException" {
            [System.IO.IOException] | Should -BeOfType [System.Type]
            [System.IO.IOException].IsSubclassOf([System.SystemException]) | Should -Be $true
        }
        
        It "Devrait permettre de spécifier un message et un HResult" {
            $exception = [System.IO.IOException]::new("Message de test", -2147024784)
            $exception.Message | Should -Be "Message de test"
            $exception.HResult | Should -Be -2147024784
        }
        
        It "Exemple 1: Devrait gérer les erreurs de lecture de fichier" {
            function Read-FileWithIOExceptionHandling {
                param (
                    [string]$FilePath
                )
                
                try {
                    $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
                    $reader = [System.IO.StreamReader]::new($fileStream)
                    $content = $reader.ReadToEnd()
                    $reader.Close()
                    $fileStream.Close()
                    return $content
                } catch [System.IO.IOException] {
                    return "Erreur d'E/S: $($_.Exception.Message)"
                } finally {
                    if ($reader -ne $null) { $reader.Dispose() }
                    if ($fileStream -ne $null) { $fileStream.Dispose() }
                }
            }
            
            # Créer un fichier temporaire pour le test
            $tempFile = [System.IO.Path]::GetTempFileName()
            [System.IO.File]::WriteAllText($tempFile, "Contenu de test")
            
            # Test avec un fichier valide
            Read-FileWithIOExceptionHandling -FilePath $tempFile | Should -Be "Contenu de test"
            
            # Test avec un fichier inexistant
            Read-FileWithIOExceptionHandling -FilePath "fichier_inexistant.txt" | Should -Match "Erreur d'E/S:"
            
            # Nettoyer
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
        
        It "Exemple 3: Devrait démontrer un fichier verrouillé par un autre processus" {
            function Test-LockedFile {
                param (
                    [string]$FilePath
                )
                
                $fileStream1 = $null
                $fileStream2 = $null
                $result = $false
                
                try {
                    # Créer un fichier et le garder ouvert
                    $fileStream1 = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
                    
                    # Tenter d'ouvrir le même fichier dans un autre flux
                    try {
                        $fileStream2 = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
                        $result = $false  # Si on arrive ici, le test a échoué
                    } catch [System.IO.IOException] {
                        $result = $true  # Si on attrape une IOException, le test a réussi
                    }
                } finally {
                    if ($fileStream1 -ne $null) { $fileStream1.Dispose() }
                    if ($fileStream2 -ne $null) { $fileStream2.Dispose() }
                }
                
                return $result
            }
            
            $tempFile = [System.IO.Path]::GetTempFileName()
            Test-LockedFile -FilePath $tempFile | Should -Be $true
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
        
        It "Exemple 4: Devrait simuler une erreur de disque plein" {
            function Simulate-DiskFullIOException {
                param (
                    [string]$Message = "There is not enough space on the disk."
                )
                
                try {
                    throw [System.IO.IOException]::new($Message, -2147024784)
                } catch [System.IO.IOException] {
                    return @{
                        Message = $_.Exception.Message
                        HResult = $_.Exception.HResult
                        IsDiskFull = $_.Exception.HResult -eq -2147024784
                    }
                }
            }
            
            $result = Simulate-DiskFullIOException
            $result.Message | Should -Be "There is not enough space on the disk."
            $result.HResult | Should -Be -2147024784
            $result.IsDiskFull | Should -Be $true
        }
        
        It "Exemple 5: Devrait gérer la copie de fichier avec IOException" {
            function Copy-FileWithIOExceptionHandling {
                param (
                    [string]$SourcePath,
                    [string]$DestinationPath
                )
                
                try {
                    [System.IO.File]::Copy($SourcePath, $DestinationPath, $true)
                    return "Success"
                } catch [System.IO.FileNotFoundException] {
                    return "FileNotFound"
                } catch [System.IO.IOException] {
                    return "IOException"
                }
            }
            
            # Créer un fichier temporaire pour le test
            $sourceFile = [System.IO.Path]::GetTempFileName()
            $destinationFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "copied_file.tmp")
            
            # Écrire du contenu dans le fichier source
            [System.IO.File]::WriteAllText($sourceFile, "Contenu de test")
            
            # Test avec des fichiers valides
            Copy-FileWithIOExceptionHandling -SourcePath $sourceFile -DestinationPath $destinationFile | Should -Be "Success"
            
            # Test avec un fichier source inexistant
            Copy-FileWithIOExceptionHandling -SourcePath "fichier_inexistant.txt" -DestinationPath $destinationFile | Should -Be "FileNotFound"
            
            # Nettoyer
            Remove-Item -Path $sourceFile -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $destinationFile -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context "Prévention des IOException" {
        It "Technique 1: Devrait utiliser des blocs try-catch-finally" {
            function Process-FileWithProperCleanup {
                param (
                    [string]$FilePath
                )
                
                $fileStream = $null
                $result = $false
                
                try {
                    $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
                    # Simuler un traitement
                    $result = $true
                } catch [System.IO.IOException] {
                    $result = $false
                } finally {
                    # Vérifier que la ressource est bien nettoyée
                    if ($fileStream -ne $null) {
                        $fileStream.Dispose()
                    }
                }
                
                return $result
            }
            
            # Créer un fichier temporaire pour le test
            $tempFile = [System.IO.Path]::GetTempFileName()
            
            # Test avec un fichier valide
            Process-FileWithProperCleanup -FilePath $tempFile | Should -Be $true
            
            # Test avec un fichier inexistant
            Process-FileWithProperCleanup -FilePath "fichier_inexistant.txt" | Should -Be $false
            
            # Nettoyer
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
        
        It "Technique 3: Devrait vérifier les conditions préalables" {
            function Write-FileWithPreCheck {
                param (
                    [string]$FilePath,
                    [string]$Content
                )
                
                # Vérifier si le répertoire existe
                $directory = [System.IO.Path]::GetDirectoryName($FilePath)
                if (-not [System.IO.Directory]::Exists($directory)) {
                    return "DirectoryNotFound"
                }
                
                # Vérifier si le fichier est en lecture seule
                if ([System.IO.File]::Exists($FilePath)) {
                    $fileInfo = [System.IO.FileInfo]::new($FilePath)
                    if ($fileInfo.IsReadOnly) {
                        return "FileReadOnly"
                    }
                }
                
                # Maintenant, tenter d'écrire dans le fichier
                try {
                    [System.IO.File]::WriteAllText($FilePath, $Content)
                    return "Success"
                } catch [System.IO.IOException] {
                    return "IOException"
                }
            }
            
            # Créer un fichier temporaire pour le test
            $tempFile = [System.IO.Path]::GetTempFileName()
            
            # Test avec un fichier valide
            Write-FileWithPreCheck -FilePath $tempFile -Content "Test" | Should -Be "Success"
            
            # Test avec un répertoire inexistant
            Write-FileWithPreCheck -FilePath "Z:\dossier_inexistant\fichier.txt" -Content "Test" | Should -Be "DirectoryNotFound"
            
            # Nettoyer
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
        
        It "Technique 5: Devrait implémenter des mécanismes de retry" {
            function Read-FileWithRetry {
                param (
                    [string]$FilePath,
                    [int]$MaxRetries = 3,
                    [scriptblock]$FailureCondition
                )
                
                $retryCount = 0
                $result = @{
                    Success = $false
                    RetryCount = 0
                    Content = $null
                }
                
                while ($retryCount -lt $MaxRetries) {
                    try {
                        if ($retryCount -lt $FailureCondition.Invoke()) {
                            throw [System.IO.IOException]::new("Erreur simulée pour le test")
                        }
                        
                        $result.Content = "Contenu simulé"
                        $result.Success = $true
                        return $result
                    } catch [System.IO.IOException] {
                        $retryCount++
                        $result.RetryCount = $retryCount
                        
                        if ($retryCount -ge $MaxRetries) {
                            return $result
                        }
                    }
                }
                
                return $result
            }
            
            # Test avec échec puis succès après 2 tentatives
            $result1 = Read-FileWithRetry -FilePath "test.txt" -FailureCondition { 2 }
            $result1.Success | Should -Be $true
            $result1.RetryCount | Should -Be 2
            
            # Test avec échec permanent (plus de tentatives que le maximum)
            $result2 = Read-FileWithRetry -FilePath "test.txt" -MaxRetries 2 -FailureCondition { 3 }
            $result2.Success | Should -Be $false
            $result2.RetryCount | Should -Be 2
        }
    }
    
    Context "Débogage des IOException" {
        It "Devrait fournir des informations de débogage utiles" {
            function Debug-IOException {
                param (
                    [System.IO.IOException]$Exception
                )
                
                $result = @{
                    Message = $Exception.Message
                    HResult = $Exception.HResult
                    HResultHex = "0x{0:X8}" -f $Exception.HResult
                    Interpretation = ""
                }
                
                # Interpréter le code HResult
                switch ($Exception.HResult) {
                    -2147024784 { $result.Interpretation = "Espace disque insuffisant" }
                    -2147024864 { $result.Interpretation = "Le fichier est utilisé par un autre processus" }
                    -2147024891 { $result.Interpretation = "Accès refusé" }
                    -2147024893 { $result.Interpretation = "Chemin introuvable" }
                    -2147024894 { $result.Interpretation = "Fichier introuvable" }
                    default { $result.Interpretation = "Code d'erreur non reconnu" }
                }
                
                return $result
            }
            
            # Test avec différents codes HResult
            $exception1 = [System.IO.IOException]::new("Disk full", -2147024784)
            $result1 = Debug-IOException -Exception $exception1
            $result1.Interpretation | Should -Be "Espace disque insuffisant"
            
            $exception2 = [System.IO.IOException]::new("File in use", -2147024864)
            $result2 = Debug-IOException -Exception $exception2
            $result2.Interpretation | Should -Be "Le fichier est utilisé par un autre processus"
            
            $exception3 = [System.IO.IOException]::new("Unknown error", -1)
            $result3 = Debug-IOException -Exception $exception3
            $result3.Interpretation | Should -Be "Code d'erreur non reconnu"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
