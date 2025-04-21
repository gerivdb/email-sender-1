Describe "Structure des dossiers n8n-unified" {
    BeforeAll {
        $rootPath = Join-Path -Path $PSScriptRoot -ChildPath ".."
        $rootPath = Resolve-Path $rootPath
    }

    Context "Dossiers principaux" {
        It "Le dossier racine existe" {
            Test-Path -Path $rootPath | Should -Be $true
        }

        It "Le dossier config existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "config") | Should -Be $true
        }

        It "Le dossier data existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "data") | Should -Be $true
        }

        It "Le dossier docker existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "docker") | Should -Be $true
        }

        It "Le dossier scripts existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "scripts") | Should -Be $true
        }

        It "Le dossier integrations existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "integrations") | Should -Be $true
        }

        It "Le dossier docs existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "docs") | Should -Be $true
        }

        It "Le dossier tests existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "tests") | Should -Be $true
        }
    }

    Context "Sous-dossiers" {
        It "Le dossier data/credentials existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "data\credentials") | Should -Be $true
        }

        It "Le dossier data/workflows existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "data\workflows") | Should -Be $true
        }

        It "Le dossier integrations/augment existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "integrations\augment") | Should -Be $true
        }

        It "Le dossier integrations/ide existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "integrations\ide") | Should -Be $true
        }

        It "Le dossier integrations/mcp existe" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "integrations\mcp") | Should -Be $true
        }
    }
}
