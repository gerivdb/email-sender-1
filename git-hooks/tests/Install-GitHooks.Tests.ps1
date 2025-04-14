#Requires -Modules Pester
<#
.SYNOPSIS
    Tests unitaires pour le script Install-GitHooks.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Install-GitHooks.ps1
    qui est utilisé pour installer les hooks Git.
.NOTES
    Auteur: Augment Code
    Date: 14/04/2025
#>

# Chemin vers le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Install-GitHooks.ps1"

# Vérifier que le fichier existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script non trouvé: $scriptPath"
}

# Créer une fonction mock pour git
function git {
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        $Arguments
    )
    
    # Simuler la commande git rev-parse --show-toplevel
    if ($Arguments -contains "rev-parse" -and $Arguments -contains "--show-toplevel") {
        return (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent)
    }
}

Describe "Install-GitHooks" {
    BeforeAll {
        # Créer un mock pour Out-File
        Mock Out-File { }
        
        # Créer un mock pour Write-Host
        Mock Write-Host { }
        
        # Créer un mock pour Write-Warning
        Mock Write-Warning { }
        
        # Créer un mock pour Write-Error
        Mock Write-Error { }
        
        # Créer un mock pour Remove-Item
        Mock Remove-Item { }
        
        # Créer un mock pour Test-Path
        Mock Test-Path { return $true }
        
        # Créer un mock pour Join-Path
        Mock Join-Path { return "$($args[0])\$($args[1])" }
        
        # Créer un mock pour ShouldProcess
        Mock ShouldProcess { return $true }
    }
    
    Context "Installation des hooks" {
        It "Devrait installer les hooks Git" {
            # Définir les paramètres
            $params = @{
                Force = $true
            }
            
            # Exécuter le script
            $result = & $scriptPath @params
            
            # Vérifier que la fonction Out-File a été appelée
            Should -Invoke Out-File -Times 1 -Exactly
            
            # Vérifier que la fonction Write-Host a été appelée avec le message "Hook installé"
            Should -Invoke Write-Host -ParameterFilter { $Object -like "*Hook installé*" } -Times 1 -Exactly
            
            # Vérifier que la fonction Write-Host a été appelée avec le message "Installation des hooks Git terminée"
            Should -Invoke Write-Host -ParameterFilter { $Object -like "*Installation des hooks Git terminée*" } -Times 1 -Exactly
        }
    }
    
    Context "Gestion des hooks existants" {
        It "Devrait remplacer les hooks existants avec -Force" {
            # Définir les paramètres
            $params = @{
                Force = $true
            }
            
            # Exécuter le script
            $result = & $scriptPath @params
            
            # Vérifier que la fonction Remove-Item a été appelée
            Should -Invoke Remove-Item -Times 1 -Exactly
        }
        
        It "Ne devrait pas remplacer les hooks existants sans -Force" {
            # Définir les paramètres
            $params = @{
                Force = $false
            }
            
            # Exécuter le script
            $result = & $scriptPath @params
            
            # Vérifier que la fonction Write-Warning a été appelée
            Should -Invoke Write-Warning -Times 1 -Exactly
            
            # Vérifier que la fonction Remove-Item n'a pas été appelée
            Should -Not -Invoke Remove-Item
        }
    }
    
    Context "Gestion des erreurs" {
        It "Devrait gérer les erreurs lorsque le répertoire des hooks n'existe pas" {
            # Créer un mock pour Test-Path qui retourne false pour le répertoire des hooks
            Mock Test-Path { 
                if ($Path -like "*.git\hooks") {
                    return $false
                } else {
                    return $true
                }
            }
            
            # Définir les paramètres
            $params = @{
                Force = $true
            }
            
            # Exécuter le script
            $result = & $scriptPath @params
            
            # Vérifier que la fonction Write-Error a été appelée
            Should -Invoke Write-Error -Times 1 -Exactly
        }
        
        It "Devrait gérer les erreurs lorsque le répertoire source n'existe pas" {
            # Créer un mock pour Test-Path qui retourne false pour le répertoire source
            Mock Test-Path { 
                if ($Path -like "*git-hooks") {
                    return $false
                } else {
                    return $true
                }
            }
            
            # Définir les paramètres
            $params = @{
                Force = $true
            }
            
            # Exécuter le script
            $result = & $scriptPath @params
            
            # Vérifier que la fonction Write-Error a été appelée
            Should -Invoke Write-Error -Times 1 -Exactly
        }
    }
}
