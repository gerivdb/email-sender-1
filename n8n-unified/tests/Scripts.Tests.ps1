Describe "Scripts n8n-unified" {
    Context "Existence des scripts" {
        It "Le script start-n8n-docker.cmd existe" {
            Test-Path -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified\scripts\start-n8n-docker.cmd" | Should -Be $true
        }

        It "Le script stop-n8n-docker.cmd existe" {
            Test-Path -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified\scripts\stop-n8n-docker.cmd" | Should -Be $true
        }

        It "Le script backup-workflows.cmd existe" {
            Test-Path -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified\scripts\backup-workflows.cmd" | Should -Be $true
        }

        It "Le script restore-workflows.cmd existe" {
            Test-Path -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified\scripts\restore-workflows.cmd" | Should -Be $true
        }

        It "Le script verify-migration.cmd existe" {
            Test-Path -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified\scripts\verify-migration.cmd" | Should -Be $true
        }

        It "Le script create-symlinks.cmd existe" {
            Test-Path -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified\scripts\create-symlinks.cmd" | Should -Be $true
        }

        It "Le script cleanup-old-n8n.cmd existe" {
            Test-Path -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified\scripts\cleanup-old-n8n.cmd" | Should -Be $true
        }
    }

    Context "Contenu des scripts" {
        It "Le script start-n8n-docker.cmd contient la commande docker-compose up" {
            $content = Get-Content -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified\scripts\start-n8n-docker.cmd" -Raw
            $content | Should -Match "docker-compose up"
        }

        It "Le script stop-n8n-docker.cmd contient la commande docker-compose down" {
            $content = Get-Content -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified\scripts\stop-n8n-docker.cmd" -Raw
            $content | Should -Match "docker-compose down"
        }

        It "Le script backup-workflows.cmd contient la commande Compress-Archive" {
            $content = Get-Content -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified\scripts\backup-workflows.cmd" -Raw
            $content | Should -Match "Compress-Archive"
        }

        It "Le script restore-workflows.cmd contient la commande Expand-Archive" {
            $content = Get-Content -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified\scripts\restore-workflows.cmd" -Raw
            $content | Should -Match "Expand-Archive"
        }
    }
}
