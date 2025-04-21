Describe "Documentation n8n-unified" {
    BeforeAll {
        $script:rootPath = Join-Path -Path $PSScriptRoot -ChildPath ".."
        $script:rootPath = Resolve-Path $rootPath
    }

    Context "Fichier README.md" {
        BeforeAll {
            $script:readmePath = Join-Path -Path $rootPath -ChildPath "README.md"
        }

        It "Le fichier README.md existe" {
            Test-Path -Path $readmePath | Should -Be $true
        }

        It "Le fichier README.md contient une description de la structure" {
            $content = Get-Content -Path $readmePath -Raw
            $content | Should -Match "Structure du projet"
        }

        It "Le fichier README.md contient des instructions d'utilisation" {
            $content = Get-Content -Path $readmePath -Raw
            $content | Should -Match "Utilisation"
        }

        It "Le fichier README.md mentionne les intégrations" {
            $content = Get-Content -Path $readmePath -Raw
            $content | Should -Match "Intégrations"
        }
    }
}
