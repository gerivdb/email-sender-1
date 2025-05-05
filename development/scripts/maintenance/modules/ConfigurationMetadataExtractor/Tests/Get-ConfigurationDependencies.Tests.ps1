BeforeAll {
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\ConfigurationMetadataExtractor.psm1'
    Import-Module $modulePath -Force
}

Describe 'Get-ConfigurationDependencies' {
    Context 'Extraction des dÃ©pendances explicites' {
        It 'Extrait correctement les dÃ©pendances explicites' {
            # DÃ©finir le contenu JSON directement dans le test
            $jsonContent = @'
{
    "server": {
        "host": "localhost",
        "port": 8080,
        "ssl": true,
        "dependsOn": ["database", "logging"]
    },
    "database": {
        "connectionString": "Server=localhost;Database=mydb;User Id=user;Password=password;",
        "maxConnections": 100,
        "timeout": 60,
        "depends_on": "storage"
    },
    "logging": {
        "level": "INFO",
        "file": "logs/app.log",
        "console": true
    },
    "storage": {
        "path": "/data",
        "type": "local"
    },
    "configPath": "config/external.json"
}
'@

            $result = Get-ConfigurationDependencies -Content $jsonContent -Format "JSON" -DetectionMode "Explicit"

            $result | Should -Not -BeNullOrEmpty
            $result.InternalDependencies | Should -Not -BeNullOrEmpty
            $result.InternalDependencies.'server' | Should -Contain 'database'
            $result.InternalDependencies.'server' | Should -Contain 'logging'
            $result.InternalDependencies.'database' | Should -Contain 'storage'
            $result.ReferencedPaths | Should -Not -BeNullOrEmpty
            $result.ReferencedPaths.'configPath' | Should -Be 'config/external.json'
        }
    }

    Context 'Extraction des dÃ©pendances implicites' {
        It 'Extrait correctement les dÃ©pendances implicites' {
            # DÃ©finir le contenu JSON directement dans le test
            $jsonContent = @'
{
    "server": {
        "host": "${database.host}",
        "port": 8080,
        "logFile": "$(logging.file)"
    },
    "database": {
        "host": "localhost",
        "connectionString": "Server=${database.host};Database=mydb;User Id=%user%;Password=%password%;",
        "maxConnections": 100
    },
    "logging": {
        "level": "INFO",
        "file": "logs/app.log"
    },
    "user": "admin",
    "password": "secret"
}
'@

            $result = Get-ConfigurationDependencies -Content $jsonContent -Format "JSON" -DetectionMode "Implicit"

            $result | Should -Not -BeNullOrEmpty
            $result.InternalDependencies | Should -Not -BeNullOrEmpty
            $result.InternalDependencies.'server.host' | Should -Contain 'database.host'
            $result.InternalDependencies.'server.logFile' | Should -Contain 'logging.file'
            $result.InternalDependencies.'database.connectionString' | Should -Contain 'database.host'
            $result.InternalDependencies.'database.connectionString' | Should -Contain 'user'
            $result.InternalDependencies.'database.connectionString' | Should -Contain 'password'
        }
    }

    Context 'DÃ©tection des dÃ©pendances circulaires' {
        It 'DÃ©tecte correctement les dÃ©pendances circulaires' {
            # DÃ©finir le contenu JSON directement dans le test
            $jsonContent = @'
{
    "component1": {
        "dependsOn": ["component2"]
    },
    "component2": {
        "dependsOn": ["component3"]
    },
    "component3": {
        "dependsOn": ["component1"]
    }
}
'@

            $result = Get-ConfigurationDependencies -Content $jsonContent -Format "JSON"

            $result | Should -Not -BeNullOrEmpty
            $result.CircularDependencies | Should -Not -BeNullOrEmpty
            $result.CircularDependencies.Count | Should -BeGreaterThan 0

            # VÃ©rifier qu'au moins un cycle contient les trois composants
            $foundCycle = $false
            foreach ($cycle in $result.CircularDependencies) {
                if (($cycle -contains 'component1') -and ($cycle -contains 'component2') -and ($cycle -contains 'component3')) {
                    $foundCycle = $true
                    break
                }
            }

            $foundCycle | Should -Be $true
        }
    }

    Context 'Gestion des erreurs' {
        It 'GÃ©nÃ¨re une erreur pour un contenu JSON invalide' {
            $invalidJson = '{invalid json}'
            $tempJsonPath = [System.IO.Path]::GetTempFileName() + ".json"
            Set-Content -Path $tempJsonPath -Value $invalidJson

            try {
                { Get-ConfigurationDependencies -Path $tempJsonPath -Format "JSON" -ErrorAction Stop } | Should -Throw
            } finally {
                Remove-Item -Path $tempJsonPath -Force -ErrorAction SilentlyContinue
            }
        }

        It 'GÃ©nÃ¨re une erreur pour un format non pris en charge' {
            $content = 'key = value'
            $tempPath = [System.IO.Path]::GetTempFileName() + ".txt"
            Set-Content -Path $tempPath -Value $content

            try {
                { Get-ConfigurationDependencies -Path $tempPath -Format "JSON" -ErrorAction Stop } | Should -Throw
            } finally {
                Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
