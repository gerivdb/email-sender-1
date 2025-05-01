BeforeAll {
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\ConfigurationMetadataExtractor.psm1'
    Import-Module $modulePath -Force
}

Describe 'Get-ConfigurationFormat' {
    Context 'Détection du format à partir du contenu' {
        It 'Détecte correctement le format JSON' {
            $jsonContent = '{"key": "value"}'
            $result = Get-ConfigurationFormat -Content $jsonContent
            $result | Should -Be 'JSON'
        }
        
        It 'Détecte correctement le format YAML' {
            $yamlContent = "key: value`notherKey: otherValue"
            $result = Get-ConfigurationFormat -Content $yamlContent
            $result | Should -Be 'YAML'
        }
        
        It 'Détecte correctement le format XML' {
            $xmlContent = '<root><key>value</key></root>'
            $result = Get-ConfigurationFormat -Content $xmlContent
            $result | Should -Be 'XML'
        }
        
        It 'Détecte correctement le format INI' {
            $iniContent = "[Section]`nkey=value"
            $result = Get-ConfigurationFormat -Content $iniContent
            $result | Should -Be 'INI'
        }
        
        It 'Détecte correctement le format PSD1' {
            $psd1Content = '@{ key = "value" }'
            $result = Get-ConfigurationFormat -Content $psd1Content
            $result | Should -Be 'PSD1'
        }
        
        It 'Retourne UNKNOWN pour un format non reconnu' {
            $unknownContent = 'This is not a valid configuration format'
            $result = Get-ConfigurationFormat -Content $unknownContent
            $result | Should -Be 'UNKNOWN'
        }
    }
    
    Context 'Détection du format à partir du chemin' {
        BeforeAll {
            # Créer des fichiers temporaires pour les tests
            $tempFolder = [System.IO.Path]::GetTempPath()
            $jsonPath = Join-Path -Path $tempFolder -ChildPath 'test.json'
            $yamlPath = Join-Path -Path $tempFolder -ChildPath 'test.yaml'
            $xmlPath = Join-Path -Path $tempFolder -ChildPath 'test.xml'
            $iniPath = Join-Path -Path $tempFolder -ChildPath 'test.ini'
            $psd1Path = Join-Path -Path $tempFolder -ChildPath 'test.psd1'
            
            '{"key": "value"}' | Set-Content -Path $jsonPath
            "key: value`notherKey: otherValue" | Set-Content -Path $yamlPath
            '<root><key>value</key></root>' | Set-Content -Path $xmlPath
            "[Section]`nkey=value" | Set-Content -Path $iniPath
            '@{ key = "value" }' | Set-Content -Path $psd1Path
        }
        
        AfterAll {
            # Supprimer les fichiers temporaires
            Remove-Item -Path $jsonPath -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $yamlPath -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $xmlPath -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $iniPath -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $psd1Path -Force -ErrorAction SilentlyContinue
        }
        
        It 'Détecte correctement le format JSON à partir du chemin' {
            $result = Get-ConfigurationFormat -Path $jsonPath
            $result | Should -Be 'JSON'
        }
        
        It 'Détecte correctement le format YAML à partir du chemin' {
            $result = Get-ConfigurationFormat -Path $yamlPath
            $result | Should -Be 'YAML'
        }
        
        It 'Détecte correctement le format XML à partir du chemin' {
            $result = Get-ConfigurationFormat -Path $xmlPath
            $result | Should -Be 'XML'
        }
        
        It 'Détecte correctement le format INI à partir du chemin' {
            $result = Get-ConfigurationFormat -Path $iniPath
            $result | Should -Be 'INI'
        }
        
        It 'Détecte correctement le format PSD1 à partir du chemin' {
            $result = Get-ConfigurationFormat -Path $psd1Path
            $result | Should -Be 'PSD1'
        }
        
        It 'Génère une erreur pour un chemin inexistant' {
            { Get-ConfigurationFormat -Path 'NonExistentPath' -ErrorAction Stop } | Should -Throw
        }
    }
}
