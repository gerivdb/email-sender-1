<#
.SYNOPSIS
    Tests unitaires pour les fonctions de diagnostic des permissions de fichiers.
.DESCRIPTION
    Ce script contient des tests unitaires pour valider les fonctions de diagnostic
    des permissions de fichiers et dossiers.
.NOTES
    Auteur: Augment Code
    Date de création: 2023-11-15
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Certains tests pourraient ne pas fonctionner correctement."
}

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\FilePermissionDiagnostic.ps1"
. $scriptPath

Describe "Test-PathPermissions" {
    BeforeAll {
        # Créer un fichier temporaire pour les tests
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value "Test content"

        # Créer un dossier temporaire pour les tests
        $tempFolder = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
        New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null

        # Créer un fichier en lecture seule
        $readOnlyFile = Join-Path -Path $tempFolder -ChildPath "readonly.txt"
        Set-Content -Path $readOnlyFile -Value "Read-only content"
        Set-ItemProperty -Path $readOnlyFile -Name IsReadOnly -Value $true
    }

    AfterAll {
        # Nettoyer les fichiers temporaires
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $readOnlyFile -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
        Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "Validation des paramètres" {
        It "Devrait retourner une erreur si le chemin n'existe pas" {
            $result = Test-PathPermissions -Path "C:\CheMin_Qui_Nexiste_Pas_12345" -Detailed
            $result.Exists | Should -Be $false
            $result.Error | Should -Be "Le chemin n'existe pas"
        }

        It "Devrait retourner un booléen si Detailed n'est pas spécifié" {
            $result = Test-PathPermissions -Path $tempFile -TestRead
            $result | Should -BeOfType [bool]
        }

        It "Devrait retourner un objet détaillé si Detailed est spécifié" {
            $result = Test-PathPermissions -Path $tempFile -TestRead -Detailed
            $result | Should -BeOfType [PSCustomObject]
            $result.Path | Should -Be $tempFile
        }
    }

    Context "Tests d'accès aux fichiers" {
        It "Devrait détecter correctement l'accès en lecture à un fichier" {
            $result = Test-PathPermissions -Path $tempFile -TestRead -Detailed
            $result.ReadAccess | Should -Be $true
        }

        It "Devrait détecter correctement l'accès en écriture à un fichier" {
            $result = Test-PathPermissions -Path $tempFile -TestWrite -Detailed
            $result.WriteAccess | Should -Be $true
        }

        It "Devrait détecter correctement un fichier en lecture seule" {
            $result = Test-PathPermissions -Path $readOnlyFile -TestWrite -Detailed
            $result.IsReadOnly | Should -Be $true
            $result.WriteAccess | Should -Be $false
        }
    }

    Context "Tests d'accès aux dossiers" {
        It "Devrait détecter correctement l'accès en lecture à un dossier" {
            $result = Test-PathPermissions -Path $tempFolder -TestRead -Detailed
            $result.ReadAccess | Should -Be $true
            $result.IsContainer | Should -Be $true
        }

        It "Devrait détecter correctement l'accès en écriture à un dossier" {
            $result = Test-PathPermissions -Path $tempFolder -TestWrite -Detailed
            $result.WriteAccess | Should -Be $true
        }
    }

    Context "Tests combinés" {
        It "Devrait combiner correctement les résultats de plusieurs tests" {
            $result = Test-PathPermissions -Path $tempFile -TestRead -TestWrite -Detailed
            $result.ReadAccess | Should -Be $true
            $result.WriteAccess | Should -Be $true
            $result.AllAccess | Should -Be $true
        }

        It "Devrait détecter correctement un accès partiel" {
            $result = Test-PathPermissions -Path $readOnlyFile -TestRead -TestWrite -Detailed
            $result.ReadAccess | Should -Be $true
            $result.WriteAccess | Should -Be $false
            $result.AllAccess | Should -Be $false
        }
    }
}

Describe "Get-UnauthorizedAccessDetails" {
    It "Devrait détecter correctement une UnauthorizedAccessException" {
        $exception = [System.UnauthorizedAccessException]::new("Access to the path 'C:\Windows\System32\config\SAM' is denied.")
        $result = Get-UnauthorizedAccessDetails -Exception $exception -Path "C:\Windows\System32\config\SAM"
        $result.IsUnauthorizedAccess | Should -Be $true
        $result.Path | Should -Be "C:\Windows\System32\config\SAM"
    }

    It "Devrait extraire le chemin du message d'erreur si non fourni" {
        $exception = [System.UnauthorizedAccessException]::new("Access to the path 'C:\Windows\System32\config\SAM' is denied.")
        $result = Get-UnauthorizedAccessDetails -Exception $exception
        $result.Path | Should -Be "C:\Windows\System32\config\SAM"
    }

    It "Devrait rejeter les exceptions qui ne sont pas des UnauthorizedAccessException" {
        $exception = [System.IO.FileNotFoundException]::new("File not found", "C:\test.txt")
        $result = Get-UnauthorizedAccessDetails -Exception $exception
        $result.IsUnauthorizedAccess | Should -Be $false
    }

    It "Devrait fournir des solutions possibles" {
        $exception = [System.UnauthorizedAccessException]::new("Access to the path 'C:\Windows\System32\config\SAM' is denied.")
        $result = Get-UnauthorizedAccessDetails -Exception $exception
        $result.PossibleSolutions | Should -Not -BeNullOrEmpty
    }
}

Describe "Debug-UnauthorizedAccessException" {
    BeforeAll {
        # Créer un fichier temporaire pour les tests
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value "Test content"

        # Créer un fichier en lecture seule
        $readOnlyFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $readOnlyFile -Value "Read-only content"
        Set-ItemProperty -Path $readOnlyFile -Name IsReadOnly -Value $true
    }

    AfterAll {
        # Nettoyer les fichiers temporaires
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $readOnlyFile -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
        Remove-Item -Path $readOnlyFile -Force -ErrorAction SilentlyContinue
    }

    It "Devrait retourner un succès pour une opération réussie" {
        $result = Debug-UnauthorizedAccessException -ScriptBlock { Get-Content -Path $tempFile }
        $result.Success | Should -Be $true
        $result.Result | Should -Not -BeNullOrEmpty
        $result.Error | Should -BeNullOrEmpty
    }

    It "Devrait capturer une erreur d'accès non autorisé" {
        $result = Debug-UnauthorizedAccessException -ScriptBlock { Set-Content -Path $readOnlyFile -Value "New content" }
        $result.Success | Should -Be $false
        $result.Error | Should -Not -BeNullOrEmpty
        $result.AccessDetails | Should -Not -BeNullOrEmpty
    }

    It "Devrait extraire le chemin du message d'erreur" {
        $result = Debug-UnauthorizedAccessException -ScriptBlock { Set-Content -Path $readOnlyFile -Value "New content" }
        $result.AccessDetails.Path | Should -Be $readOnlyFile
    }

    It "Devrait analyser les permissions si demandé" {
        $result = Debug-UnauthorizedAccessException -ScriptBlock { Set-Content -Path $readOnlyFile -Value "New content" } -AnalyzePermissions
        $result.PermissionsAnalysis | Should -Not -BeNullOrEmpty
        $result.PermissionsAnalysis.IsReadOnly | Should -Be $true
    }

    It "Devrait utiliser le chemin fourni" {
        $result = Debug-UnauthorizedAccessException -ScriptBlock { Set-Content -Path $readOnlyFile -Value "New content" } -Path $readOnlyFile
        $result.AccessDetails.Path | Should -Be $readOnlyFile
    }
}

Describe "Test-AccessRequirements" {
    BeforeAll {
        # Créer un fichier temporaire pour les tests
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value "Test content"

        # Créer un fichier en lecture seule
        $readOnlyFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $readOnlyFile -Value "Read-only content"
        Set-ItemProperty -Path $readOnlyFile -Name IsReadOnly -Value $true

        # Créer un dossier temporaire pour les tests
        $tempFolder = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
        New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
    }

    AfterAll {
        # Nettoyer les fichiers temporaires
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $readOnlyFile -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
        Remove-Item -Path $readOnlyFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Devrait détecter correctement l'accès en lecture à un fichier" {
        $result = Test-AccessRequirements -Path $tempFile -RequiredAccess "Read" -Quiet
        $result.AccessGranted | Should -Be $true
        $result.AvailableAccess | Should -Contain "Read"
    }

    It "Devrait détecter correctement l'accès en écriture à un fichier" {
        $result = Test-AccessRequirements -Path $tempFile -RequiredAccess "Write" -Quiet
        $result.AccessGranted | Should -Be $true
        $result.AvailableAccess | Should -Contain "Write"
    }

    It "Devrait détecter correctement un fichier en lecture seule" {
        $result = Test-AccessRequirements -Path $readOnlyFile -RequiredAccess "Write" -Quiet
        $result.AccessGranted | Should -Be $false
        $result.MissingAccess | Should -Contain "Write"
    }

    It "Devrait détecter correctement un chemin inexistant" {
        $result = Test-AccessRequirements -Path "C:\CheMin_Qui_Nexiste_Pas_12345" -RequiredAccess "Read" -Quiet
        $result.Exists | Should -Be $false
        $result.AccessGranted | Should -Be $false
    }

    It "Devrait suggérer des solutions si demandé" {
        $result = Test-AccessRequirements -Path $readOnlyFile -RequiredAccess "Write" -SuggestSolutions -Quiet
        $result.Suggestions | Should -Not -BeNullOrEmpty
    }

    It "Devrait gérer plusieurs types d'accès" {
        $result = Test-AccessRequirements -Path $tempFile -RequiredAccess "Read", "Write" -Quiet
        $result.AccessGranted | Should -Be $true
        $result.AvailableAccess | Should -Contain "Read"
        $result.AvailableAccess | Should -Contain "Write"
    }
}

Describe "Invoke-WithAccessCheck" {
    BeforeAll {
        # Créer un fichier temporaire pour les tests
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value "Test content"

        # Créer un fichier en lecture seule
        $readOnlyFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $readOnlyFile -Value "Read-only content"
        Set-ItemProperty -Path $readOnlyFile -Name IsReadOnly -Value $true
    }

    AfterAll {
        # Nettoyer les fichiers temporaires
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $readOnlyFile -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
        Remove-Item -Path $readOnlyFile -Force -ErrorAction SilentlyContinue
    }

    It "Devrait exécuter le bloc de code si les permissions sont disponibles" {
        $result = Invoke-WithAccessCheck -Path $tempFile -RequiredAccess "Read" -ScriptBlock {
            return "Succès"
        }
        $result | Should -Be "Succès"
    }

    It "Devrait exécuter le bloc OnFailure si les permissions ne sont pas disponibles" {
        $result = Invoke-WithAccessCheck -Path $readOnlyFile -RequiredAccess "Write" -ScriptBlock {
            return "Succès"
        } -OnFailure {
            return "Échec"
        }
        $result | Should -Be "Échec"
    }

    It "Devrait gérer plusieurs types d'accès" {
        $result = Invoke-WithAccessCheck -Path $tempFile -RequiredAccess "Read", "Write" -ScriptBlock {
            return "Succès"
        }
        $result | Should -Be "Succès"
    }

    It "Devrait gérer un chemin inexistant" {
        $result = Invoke-WithAccessCheck -Path "C:\CheMin_Qui_Nexiste_Pas_12345" -RequiredAccess "Read" -ScriptBlock {
            return "Succès"
        } -OnFailure {
            return "Échec"
        }
        $result | Should -Be "Échec"
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Verbose
