<#
.SYNOPSIS
    Tests pour la fonction Inspect-Variable.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Inspect-Variable.
    Il vérifie que la fonction fonctionne correctement avec différents types de données
    et différentes options.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Scope CurrentUser -Force
}

# Importer le module Pester
Import-Module -Name Pester

# Chemin vers la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Inspect-Variable.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Inspect-Variable.ps1 est introuvable à l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath

# Démarrer les tests
Describe "Tests pour Inspect-Variable" {
    Context "Tests de base" {
        It "Devrait retourner des informations sur une chaîne" {
            $result = Inspect-Variable -InputObject "Test" -Format "Object"
            $result.Type | Should -Be "System.String"
            $result.Value | Should -Be "Test"
            $result.Size | Should -Be 8 # 4 caractères * 2 bytes par caractère
        }

        It "Devrait retourner des informations sur un entier" {
            $result = Inspect-Variable -InputObject 42 -Format "Object"
            $result.Type | Should -Be "System.Int32"
            $result.Value | Should -Be 42
        }

        It "Devrait retourner des informations sur un booléen" {
            $result = Inspect-Variable -InputObject $true -Format "Object"
            $result.Type | Should -Be "System.Boolean"
            $result.Value | Should -Be $true
        }

        It "Devrait retourner des informations sur une valeur null" {
            $result = Inspect-Variable -InputObject $null -Format "Object"
            $result.Type | Should -Be "null"
            $result.Value | Should -Be $null
        }
    }

    Context "Tests avec des collections" {
        It "Devrait retourner des informations sur un tableau" {
            $array = @(1, 2, 3, 4, 5)
            $result = Inspect-Variable -InputObject $array -Format "Object"
            $result.Type | Should -Match "System.Object\[\]"
            $result.Count | Should -Be 5
            $result.Items.Count | Should -Be 5
            $result.Items[0].Value | Should -Be 1
        }

        It "Devrait limiter le nombre d'éléments affichés" {
            $array = 1..20
            $result = Inspect-Variable -InputObject $array -Format "Object" -MaxArrayItems 5
            $result.Items.Count | Should -Be 5
            $result.HasMore | Should -Be $true
            $result.TotalItems | Should -Be 20
        }

        It "Devrait retourner des informations sur un hashtable" {
            $hash = @{
                Key1 = "Value1"
                Key2 = 42
                Key3 = $true
            }
            $result = Inspect-Variable -InputObject $hash -Format "Object"
            $result.Type | Should -Match "System.Collections.Hashtable"
            $result.Count | Should -Be 3
            $result.Properties.Keys.Count | Should -Be 3
            $result.Properties["Key1"].Value | Should -Be "Value1"
            $result.Properties["Key2"].Value | Should -Be 42
            $result.Properties["Key3"].Value | Should -Be $true
        }
    }

    Context "Tests avec des objets complexes" {
        It "Devrait retourner des informations sur un PSCustomObject" {
            $obj = [PSCustomObject]@{
                Name   = "Test"
                Value  = 42
                Nested = [PSCustomObject]@{
                    Property = "NestedValue"
                }
            }
            $result = Inspect-Variable -InputObject $obj -Format "Object"
            $result.Type | Should -Match "PSCustomObject"
            $result.Properties.Keys.Count | Should -Be 3
            $result.Properties["Name"].Value | Should -Be "Test"
            $result.Properties["Value"].Value | Should -Be 42
            $result.Properties["Nested"].Type | Should -Match "PSCustomObject"
        }

        It "Devrait respecter la profondeur maximale" {
            $obj = [PSCustomObject]@{
                Level1 = [PSCustomObject]@{
                    Level2 = [PSCustomObject]@{
                        Level3 = [PSCustomObject]@{
                            Level4 = [PSCustomObject]@{
                                Level5 = "Too Deep"
                            }
                        }
                    }
                }
            }
            $result = Inspect-Variable -InputObject $obj -Format "Object" -MaxDepth 3
            $result.Properties["Level1"].Properties["Level2"].Properties["Level3"].Value | Should -Be "Maximum depth reached"
        }
    }

    Context "Tests de format de sortie" {
        It "Devrait retourner une chaîne formatée en mode Text" {
            $result = Inspect-Variable -InputObject "Test" -Format "Text"
            $result | Should -BeOfType [string]
            $result | Should -Match "\[Type\] System.String"
            $result | Should -Match "\[Value\] Test"
        }

        It "Devrait retourner un objet en mode Object" {
            $result = Inspect-Variable -InputObject "Test" -Format "Object"
            $result | Should -BeOfType [PSCustomObject]
            $result.Type | Should -Be "System.String"
            $result.Value | Should -Be "Test"
        }

        It "Devrait retourner une chaîne JSON en mode JSON" {
            $result = Inspect-Variable -InputObject "Test" -Format "JSON"
            $result | Should -BeOfType [string]
            $result | Should -Match '"Type":\s*"System.String"'
            $result | Should -Match '"Value":\s*"Test"'
        }
    }

    Context "Tests de niveau de détail" {
        It "Devrait limiter les informations en mode Basic" {
            $obj = [PSCustomObject]@{
                Name   = "Test"
                Nested = [PSCustomObject]@{
                    Property = "Value"
                }
            }
            $result = Inspect-Variable -InputObject $obj -Format "Object" -DetailLevel "Basic"
            $result.Properties | Should -BeNullOrEmpty
        }

        It "Devrait inclure plus d'informations en mode Detailed" {
            $obj = [PSCustomObject]@{
                Name   = "Test"
                Nested = [PSCustomObject]@{
                    Property = "Value"
                }
            }
            $result = Inspect-Variable -InputObject $obj -Format "Object" -DetailLevel "Detailed"
            $result.Properties["Nested"].Properties["Property"].Value | Should -Be "Value"
        }
    }

    Context "Tests de filtrage des propriétés" {
        It "Devrait filtrer les propriétés par nom avec une expression régulière" {
            $obj = [PSCustomObject]@{
                Name          = "Test"
                Value         = 42
                Description   = "Description de test"
                InternalValue = 100
            }
            $result = Inspect-Variable -InputObject $obj -Format "Object" -PropertyFilter "^[NV]"
            $result.Properties.Keys | Should -Contain "Name"
            $result.Properties.Keys | Should -Contain "Value"
            $result.Properties.Keys | Should -Not -Contain "Description"
            $result.Properties.Keys | Should -Not -Contain "InternalValue"
        }

        It "Devrait filtrer les propriétés par type avec une expression régulière" {
            $obj = [PSCustomObject]@{
                Name  = "Test"
                Value = 42
                Flag  = $true
                Date  = Get-Date
            }
            $result = Inspect-Variable -InputObject $obj -Format "Object" -TypeFilter "Int|Boolean"
            $result.Properties.Keys | Should -Not -Contain "Name"
            $result.Properties.Keys | Should -Contain "Value"
            $result.Properties.Keys | Should -Contain "Flag"
            $result.Properties.Keys | Should -Not -Contain "Date"
        }

        It "Devrait inclure les propriétés internes avec IncludeInternalProperties" {
            $obj = [PSCustomObject]@{
                Name           = "Test"
                _InternalValue = "Secret"
            }
            $result = Inspect-Variable -InputObject $obj -Format "Object" -IncludeInternalProperties
            $result.Properties.Keys | Should -Contain "Name"
            $result.Properties.Keys | Should -Contain "_InternalValue"
        }

        It "Ne devrait pas inclure les propriétés internes par défaut" {
            $obj = [PSCustomObject]@{
                Name           = "Test"
                _InternalValue = "Secret"
            }
            $result = Inspect-Variable -InputObject $obj -Format "Object"
            $result.Properties.Keys | Should -Contain "Name"
            $result.Properties.Keys | Should -Not -Contain "_InternalValue"
        }
    }

    Context "Tests de détection des références circulaires" {
        It "Devrait détecter une référence circulaire simple" {
            $parent = [PSCustomObject]@{
                Name = "Parent"
            }
            $child = [PSCustomObject]@{
                Name   = "Child"
                Parent = $parent
            }
            $parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

            $result = Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Mark"
            $result.Properties["Child"].Properties["Parent"].IsCircularReference | Should -Be $true
        }

        It "Devrait ignorer les références circulaires avec CircularReferenceHandling=Ignore" {
            $parent = [PSCustomObject]@{
                Name = "Parent"
            }
            $child = [PSCustomObject]@{
                Name   = "Child"
                Parent = $parent
            }
            $parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

            $result = Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Ignore"
            $result.Properties["Child"].Properties["Parent"].IsCircularReference | Should -BeNullOrEmpty
        }

        It "Devrait lever une exception avec CircularReferenceHandling=Throw" {
            $parent = [PSCustomObject]@{
                Name = "Parent"
            }
            $child = [PSCustomObject]@{
                Name   = "Child"
                Parent = $parent
            }
            $parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

            { Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Throw" } | Should -Throw
        }

        It "Devrait désactiver la détection des références circulaires avec DetectCircularReferences=`$false" {
            $parent = [PSCustomObject]@{
                Name = "Parent"
            }
            $child = [PSCustomObject]@{
                Name   = "Child"
                Parent = $parent
            }
            $parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

            $result = Inspect-Variable -InputObject $parent -Format "Object" -DetectCircularReferences $false
            $result.Properties["Child"].Properties["Parent"].IsCircularReference | Should -BeNullOrEmpty
        }
    }
}
