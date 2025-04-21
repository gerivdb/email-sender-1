Describe "Système d'intégration n8n unifié" {
    BeforeAll {
        # Chemin vers les scripts
        $rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified"
        $startScript = Join-Path -Path $rootPath -ChildPath "start-n8n-unified.ps1"
        $stopScript = Join-Path -Path $rootPath -ChildPath "stop-n8n-unified.ps1"
        $configFile = Join-Path -Path $rootPath -ChildPath "config\n8n-unified-config.json"
        $logFile = Join-Path -Path $rootPath -ChildPath "logs\n8n-unified.log"

        # Vérifier si les scripts existent
        $startScriptExists = Test-Path -Path $startScript
        $stopScriptExists = Test-Path -Path $stopScript
    }

    Context "Vérification des fichiers" {
        It "Le script de démarrage unifié devrait exister" {
            $startScriptExists | Should -Be $true
        }

        It "Le script d'arrêt unifié devrait exister" {
            $stopScriptExists | Should -Be $true
        }
    }

    Context "Vérification du contenu des scripts" {
        It "Le script de démarrage devrait contenir la fonction Start-N8nUnified" {
            $startScriptContent = Get-Content -Path $startScript -Raw
            $startScriptContent | Should -Match "function Start-N8nUnified"
        }

        It "Le script de démarrage devrait contenir la fonction Start-N8n" {
            $startScriptContent = Get-Content -Path $startScript -Raw
            $startScriptContent | Should -Match "function Start-N8n"
        }

        It "Le script de démarrage devrait contenir la fonction Start-IdeIntegration" {
            $startScriptContent = Get-Content -Path $startScript -Raw
            $startScriptContent | Should -Match "function Start-IdeIntegration"
        }

        It "Le script de démarrage devrait contenir la fonction Start-McpIntegration" {
            $startScriptContent = Get-Content -Path $startScript -Raw
            $startScriptContent | Should -Match "function Start-McpIntegration"
        }

        It "Le script d'arrêt devrait contenir la fonction Stop-N8nUnified" {
            $stopScriptContent = Get-Content -Path $stopScript -Raw
            $stopScriptContent | Should -Match "function Stop-N8nUnified"
        }

        It "Le script d'arrêt devrait contenir la fonction Stop-N8n" {
            $stopScriptContent = Get-Content -Path $stopScript -Raw
            $stopScriptContent | Should -Match "function Stop-N8n"
        }

        It "Le script d'arrêt devrait contenir la fonction Stop-McpIntegration" {
            $stopScriptContent = Get-Content -Path $stopScript -Raw
            $stopScriptContent | Should -Match "function Stop-McpIntegration"
        }
    }
}
