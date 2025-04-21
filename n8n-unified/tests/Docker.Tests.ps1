Describe "Configuration Docker n8n-unified" {
    BeforeAll {
        $script:rootPath = Join-Path -Path $PSScriptRoot -ChildPath ".."
        $script:rootPath = Resolve-Path $rootPath
        $script:dockerPath = Join-Path -Path $rootPath -ChildPath "docker"
    }

    Context "Fichiers Docker" {
        It "Le fichier docker-compose.yml existe" {
            Test-Path -Path (Join-Path -Path $dockerPath -ChildPath "docker-compose.yml") | Should -Be $true
        }

        It "Le fichier .env existe" {
            Test-Path -Path (Join-Path -Path $dockerPath -ChildPath ".env") | Should -Be $true
        }
    }

    Context "Contenu du fichier docker-compose.yml" {
        BeforeAll {
            $dockerComposeFile = Join-Path -Path $dockerPath -ChildPath "docker-compose.yml"
            $script:dockerComposeContent = Get-Content -Path $dockerComposeFile -Raw
        }

        It "Le fichier docker-compose.yml contient le service n8n" {
            $dockerComposeContent | Should -Match "services:\s+n8n:"
        }

        It "Le fichier docker-compose.yml contient le port 5678" {
            $dockerComposeContent | Should -Match "ports:\s+- .*5678.*"
        }

        It "Le fichier docker-compose.yml contient le volume pour les données" {
            $dockerComposeContent | Should -Match "volumes:\s+- ../data:/home/node/\.n8n"
        }

        It "Le fichier docker-compose.yml contient la configuration de healthcheck" {
            $dockerComposeContent | Should -Match "healthcheck:"
        }
    }

    Context "Contenu du fichier .env" {
        BeforeAll {
            $envFile = Join-Path -Path $dockerPath -ChildPath ".env"
            $script:envContent = Get-Content -Path $envFile -Raw
        }

        It "Le fichier .env contient N8N_BASIC_AUTH_ACTIVE=false" {
            $envContent | Should -Match "N8N_BASIC_AUTH_ACTIVE=false"
        }

        It "Le fichier .env contient N8N_USER_MANAGEMENT_DISABLED=true" {
            $envContent | Should -Match "N8N_USER_MANAGEMENT_DISABLED=true"
        }

        It "Le fichier .env contient N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true" {
            $envContent | Should -Match "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
        }

        It "Le fichier .env contient N8N_ENCRYPTION_KEY" {
            $envContent | Should -Match "N8N_ENCRYPTION_KEY=.*"
        }
    }
}
