#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires Pester très simples.

.DESCRIPTION
    Ce script contient des tests unitaires Pester très simples qui ne dépendent pas de l'importation du module.
#>

Describe "Tests très simples" {
    Context "Tests de base" {
        It "PowerShell fonctionne correctement" {
            $true | Should -Be $true
        }

        It "1 + 1 = 2" {
            1 + 1 | Should -Be 2
        }

        It "Les chaînes de caractères fonctionnent" {
            "Hello" + " " + "World" | Should -Be "Hello World"
        }

        It "Les tableaux fonctionnent" {
            @(1, 2, 3).Count | Should -Be 3
        }

        It "Les hashtables fonctionnent" {
            $hash = @{
                Key1 = "Value1"
                Key2 = "Value2"
            }
            $hash.Key1 | Should -Be "Value1"
        }

        It "Les conditions fonctionnent" {
            $condition = $true
            if ($condition) {
                $result = "True"
            } else {
                $result = "False"
            }
            $result | Should -Be "True"
        }

        It "Les boucles fonctionnent" {
            $sum = 0
            for ($i = 1; $i -le 10; $i++) {
                $sum += $i
            }
            $sum | Should -Be 55
        }

        It "Les fonctions fonctionnent" {
            function Add-Numbers($a, $b) {
                return $a + $b
            }
            Add-Numbers 2 3 | Should -Be 5
        }

        It "Les objets fonctionnent" {
            $obj = [PSCustomObject]@{
                Name = "Test"
                Value = 42
            }
            $obj.Name | Should -Be "Test"
            $obj.Value | Should -Be 42
        }

        It "Les fichiers système existent" {
            Test-Path -Path "C:\Windows\System32" | Should -Be $true
        }
    }
}
