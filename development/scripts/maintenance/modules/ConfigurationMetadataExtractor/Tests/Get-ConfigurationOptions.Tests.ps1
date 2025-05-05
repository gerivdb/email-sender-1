BeforeAll {
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\ConfigurationMetadataExtractor.psm1'
    Import-Module $modulePath -Force
}

Describe 'Get-ConfigurationOptions' {
    Context 'Extraction des options Ã  partir du contenu JSON' {
        It 'Extrait correctement les options en mode hiÃ©rarchique' {
            # DÃ©finir le contenu JSON directement dans le test
            $jsonContent = @'
{
    "server": {
        "host": "localhost",
        "port": 8080,
        "ssl": true,
        "timeout": 30
    },
    "database": {
        "connectionString": "Server=localhost;Database=mydb;User Id=user;Password=password;",
        "maxConnections": 100,
        "timeout": 60
    },
    "logging": {
        "level": "INFO",
        "file": "logs/app.log",
        "console": true
    },
    "features": ["auth", "admin", "reporting"]
}
'@

            $result = Get-ConfigurationOptions -Content $jsonContent -Format "JSON"

            $result | Should -Not -BeNullOrEmpty
            $result.server | Should -Not -BeNullOrEmpty
            $result.server.Type | Should -Be "Object"
            $result.server.Properties | Should -Not -BeNullOrEmpty
            $result.server.Properties.host | Should -Not -BeNullOrEmpty
            $result.server.Properties.host.Type | Should -Be "String"
            $result.server.Properties.port | Should -Not -BeNullOrEmpty
            $result.server.Properties.port.Type | Should -BeIn @("Int32", "Int64")
            $result.database | Should -Not -BeNullOrEmpty
            $result.database.Type | Should -Be "Object"
            $result.database.Properties | Should -Not -BeNullOrEmpty
            $result.database.Properties.connectionString | Should -Not -BeNullOrEmpty
            $result.database.Properties.connectionString.Type | Should -Be "String"
            $result.features | Should -Not -BeNullOrEmpty
            $result.features.Type | Should -Be "Array"
            $result.features.ElementType | Should -Be "String"
        }

        It 'Extrait correctement les options en mode plat' {
            # DÃ©finir le contenu JSON directement dans le test
            $jsonContent = @'
{
    "server": {
        "host": "localhost",
        "port": 8080,
        "ssl": true,
        "timeout": 30
    },
    "database": {
        "connectionString": "Server=localhost;Database=mydb;User Id=user;Password=password;",
        "maxConnections": 100,
        "timeout": 60
    },
    "logging": {
        "level": "INFO",
        "file": "logs/app.log",
        "console": true
    },
    "features": ["auth", "admin", "reporting"]
}
'@

            $result = Get-ConfigurationOptions -Content $jsonContent -Format "JSON" -Flatten

            $result | Should -Not -BeNullOrEmpty
            $result.'server.host' | Should -Not -BeNullOrEmpty
            $result.'server.host'.Type | Should -Be "String"
            $result.'server.port' | Should -Not -BeNullOrEmpty
            $result.'server.port'.Type | Should -BeIn @("Int32", "Int64")
            $result.'database.connectionString' | Should -Not -BeNullOrEmpty
            $result.'database.connectionString'.Type | Should -Be "String"
            $result.'features' | Should -Not -BeNullOrEmpty
            $result.'features'.Type | Should -Be "Array"
            $result.'features'.ElementType | Should -Be "String"
        }

        It 'Inclut correctement les valeurs lorsque demandÃ©' {
            # DÃ©finir le contenu JSON directement dans le test
            $jsonContent = @'
{
    "server": {
        "host": "localhost",
        "port": 8080,
        "ssl": true,
        "timeout": 30
    },
    "database": {
        "connectionString": "Server=localhost;Database=mydb;User Id=user;Password=password;",
        "maxConnections": 100,
        "timeout": 60
    },
    "logging": {
        "level": "INFO",
        "file": "logs/app.log",
        "console": true
    },
    "features": ["auth", "admin", "reporting"]
}
'@

            $result = Get-ConfigurationOptions -Content $jsonContent -Format "JSON" -IncludeValues -Flatten

            $result | Should -Not -BeNullOrEmpty
            $result.'server.host' | Should -Not -BeNullOrEmpty
            $result.'server.host'.Value | Should -Be "localhost"
            $result.'server.port' | Should -Not -BeNullOrEmpty
            $result.'server.port'.Value | Should -Be 8080
            $result.'database.connectionString' | Should -Not -BeNullOrEmpty
            $result.'database.connectionString'.Value | Should -Be "Server=localhost;Database=mydb;User Id=user;Password=password;"
            $result.'features' | Should -Not -BeNullOrEmpty
            $result.'features'.Value | Should -Be @("auth", "admin", "reporting")
        }
    }

    Context 'Extraction des options Ã  partir du contenu YAML' {
        It 'Extrait correctement les options en mode hiÃ©rarchique' {
            # DÃ©finir le contenu YAML directement dans le test
            $yamlContent = @'
server:
  host: localhost
  port: 8080
  ssl: true
  timeout: 30
database:
  connectionString: Server=localhost;Database=mydb;User Id=user;Password=password;
  maxConnections: 100
  timeout: 60
logging:
  level: INFO
  file: logs/app.log
  console: true
features:
  - auth
  - admin
  - reporting
'@

            # Ignorer ce test si le module PowerShell-Yaml n'est pas disponible
            if (-not (Get-Module -ListAvailable -Name 'powershell-yaml')) {
                Set-ItResult -Skipped -Because "Le module PowerShell-Yaml n'est pas disponible"
                return
            }

            $result = Get-ConfigurationOptions -Content $yamlContent -Format "YAML"

            $result | Should -Not -BeNullOrEmpty
            $result.server | Should -Not -BeNullOrEmpty
            $result.server.Type | Should -Be "Object"
            $result.server.Properties | Should -Not -BeNullOrEmpty
            $result.server.Properties.host | Should -Not -BeNullOrEmpty
            $result.server.Properties.host.Type | Should -Be "String"
            $result.server.Properties.port | Should -Not -BeNullOrEmpty
            $result.server.Properties.port.Type | Should -BeIn @("Int32", "Int64")
        }
    }

    Context 'Gestion des erreurs' {
        It 'GÃ©nÃ¨re une erreur pour un contenu JSON invalide' {
            $invalidJson = '{invalid json}'
            $tempJsonPath = [System.IO.Path]::GetTempFileName() + ".json"
            Set-Content -Path $tempJsonPath -Value $invalidJson

            try {
                { Get-ConfigurationOptions -Path $tempJsonPath -Format "JSON" -ErrorAction Stop } | Should -Throw
            } finally {
                Remove-Item -Path $tempJsonPath -Force -ErrorAction SilentlyContinue
            }
        }

        It 'GÃ©nÃ¨re une erreur pour un format non pris en charge' {
            $content = 'key = value'
            $tempPath = [System.IO.Path]::GetTempFileName() + ".txt"
            Set-Content -Path $tempPath -Value $content

            try {
                { Get-ConfigurationOptions -Path $tempPath -Format "JSON" -ErrorAction Stop } | Should -Throw
            } finally {
                Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
