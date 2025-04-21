Describe "Redirections n8n-unified" {
    BeforeAll {
        $rootPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\"
        $rootPath = Resolve-Path $rootPath
    }

    Context "Scripts de redirection" {
        It "Le script start-n8n.cmd existe dans le dossier racine" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "start-n8n.cmd") | Should -Be $true
        }

        It "Le script stop-n8n.cmd existe dans le dossier racine" {
            Test-Path -Path (Join-Path -Path $rootPath -ChildPath "stop-n8n.cmd") | Should -Be $true
        }
    }

    Context "Contenu des scripts de redirection" {
        It "Le script start-n8n.cmd redirige vers start-n8n-docker.cmd" {
            $content = Get-Content -Path (Join-Path -Path $rootPath -ChildPath "start-n8n.cmd") -Raw
            $content | Should -Match "n8n-unified\\scripts\\start-n8n-docker.cmd"
        }

        It "Le script stop-n8n.cmd redirige vers stop-n8n-docker.cmd" {
            $content = Get-Content -Path (Join-Path -Path $rootPath -ChildPath "stop-n8n.cmd") -Raw
            $content | Should -Match "n8n-unified\\scripts\\stop-n8n-docker.cmd"
        }
    }
}
