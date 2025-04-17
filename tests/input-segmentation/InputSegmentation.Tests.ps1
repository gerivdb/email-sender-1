#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module InputSegmentation.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module InputSegmentation,
    vérifiant la segmentation de différents types d'entrées.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-10
#>

BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\InputSegmentation.psm1"
    Import-Module $modulePath -Force
    
    # Initialiser le module
    Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5
}

Describe "Measure-InputSize" {
    Context "Lorsqu'on mesure la taille de différentes entrées" {
        It "Devrait mesurer correctement la taille d'une chaîne de texte" {
            $text = "A" * 5KB
            $size = Measure-InputSize -Input $text
            $size | Should -BeGreaterOrEqual 4.8  # Tenir compte de l'encodage
            $size | Should -BeLessThan 5.2
        }
        
        It "Devrait mesurer correctement la taille d'un objet JSON" {
            $json = @{
                items = @()
            }
            
            for ($i = 0; $i -lt 100; $i++) {
                $json.items += @{
                    id = $i
                    name = "Item $i"
                    value = "Value $i"
                }
            }
            
            $size = Measure-InputSize -Input $json
            $size | Should -BeGreaterThan 0
        }
        
        It "Devrait mesurer correctement la taille d'un fichier" {
            # Créer un fichier temporaire
            $tempFile = Join-Path -Path $TestDrive -ChildPath "test.txt"
            "A" * 5KB | Out-File -FilePath $tempFile -Encoding utf8
            
            $size = Measure-InputSize -Input $tempFile
            $size | Should -BeGreaterOrEqual 4.8  # Tenir compte de l'encodage
            $size | Should -BeLessThan 5.2
        }
    }
}

Describe "Split-TextInput" {
    Context "Lorsqu'on segmente du texte" {
        It "Devrait segmenter un texte volumineux en plusieurs parties" {
            $text = "A" * 12KB
            $segments = Split-TextInput -Text $text -ChunkSizeKB 5
            
            $segments.Count | Should -Be 3
            $segments[0].Length | Should -BeLessThan 6KB
        }
        
        It "Devrait préserver les sauts de ligne lorsque demandé" {
            $text = "Ligne 1`nLigne 2`nLigne 3" * 1KB
            $segments = Split-TextInput -Text $text -ChunkSizeKB 5 -PreserveLines
            
            # Vérifier que les segments se terminent par des sauts de ligne complets
            $segments | ForEach-Object {
                if ($_ -ne $segments[-1]) {  # Ignorer le dernier segment
                    $_.EndsWith("`n") | Should -Be $true
                }
            }
        }
        
        It "Ne devrait pas segmenter un texte plus petit que la taille maximale" {
            $text = "A" * 4KB
            $segments = Split-TextInput -Text $text -ChunkSizeKB 5
            
            $segments.Count | Should -Be 1
            $segments[0] | Should -Be $text
        }
    }
}

Describe "Split-JsonInput" {
    Context "Lorsqu'on segmente un objet JSON" {
        It "Devrait segmenter un objet JSON volumineux en plusieurs parties" {
            $json = @{
                items = @()
            }
            
            for ($i = 0; $i -lt 500; $i++) {
                $json.items += @{
                    id = $i
                    name = "Item $i"
                    description = "Description de l'item $i"
                    properties = @{
                        prop1 = "Valeur 1"
                        prop2 = "Valeur 2"
                    }
                }
            }
            
            $segments = Split-JsonInput -JsonObject $json -ChunkSizeKB 5
            
            $segments.Count | Should -BeGreaterThan 1
            $segments[0].items.Count | Should -BeLessThan $json.items.Count
        }
        
        It "Devrait préserver la structure de l'objet JSON dans chaque segment" {
            $json = @{
                metadata = @{
                    title = "Test"
                    description = "Description de test"
                }
                items = @()
            }
            
            for ($i = 0; $i -lt 500; $i++) {
                $json.items += @{
                    id = $i
                    name = "Item $i"
                }
            }
            
            $segments = Split-JsonInput -JsonObject $json -ChunkSizeKB 5
            
            # Vérifier que chaque segment contient les métadonnées
            $segments | ForEach-Object {
                $_.metadata.title | Should -Be "Test"
                $_.metadata.description | Should -Be "Description de test"
            }
        }
        
        It "Ne devrait pas segmenter un objet JSON plus petit que la taille maximale" {
            $json = @{
                items = @()
            }
            
            for ($i = 0; $i -lt 10; $i++) {
                $json.items += @{
                    id = $i
                    name = "Item $i"
                }
            }
            
            $segments = Split-JsonInput -JsonObject $json -ChunkSizeKB 5
            
            $segments.Count | Should -Be 1
            $segments[0].items.Count | Should -Be $json.items.Count
        }
    }
}

Describe "Split-FileInput" {
    Context "Lorsqu'on segmente un fichier" {
        BeforeAll {
            # Créer un fichier texte volumineux
            $tempTextFile = Join-Path -Path $TestDrive -ChildPath "large_text.txt"
            "A" * 12KB | Out-File -FilePath $tempTextFile -Encoding utf8
            
            # Créer un fichier JSON volumineux
            $tempJsonFile = Join-Path -Path $TestDrive -ChildPath "large_json.json"
            $json = @{
                items = @()
            }
            
            for ($i = 0; $i -lt 500; $i++) {
                $json.items += @{
                    id = $i
                    name = "Item $i"
                }
            }
            
            $json | ConvertTo-Json -Depth 10 | Out-File -FilePath $tempJsonFile -Encoding utf8
        }
        
        It "Devrait segmenter un fichier texte volumineux" {
            $segments = Split-FileInput -FilePath $tempTextFile -ChunkSizeKB 5
            
            $segments.Count | Should -BeGreaterThan 1
            $segments | ForEach-Object {
                $_.Length | Should -BeLessThan 6KB
            }
        }
        
        It "Devrait segmenter un fichier JSON volumineux" {
            $segments = Split-FileInput -FilePath $tempJsonFile -ChunkSizeKB 5
            
            $segments.Count | Should -BeGreaterThan 1
        }
        
        It "Devrait préserver les sauts de ligne lorsque demandé" {
            # Créer un fichier avec des sauts de ligne
            $tempLineFile = Join-Path -Path $TestDrive -ChildPath "lines.txt"
            "Ligne 1`nLigne 2`nLigne 3" * 1KB | Out-File -FilePath $tempLineFile -Encoding utf8
            
            $segments = Split-FileInput -FilePath $tempLineFile -ChunkSizeKB 5 -PreserveLines
            
            # Vérifier que les segments se terminent par des sauts de ligne complets
            $segments | ForEach-Object {
                if ($_ -ne $segments[-1]) {  # Ignorer le dernier segment
                    $_.EndsWith("`n") | Should -Be $true
                }
            }
        }
    }
}

Describe "Split-Input" {
    Context "Lorsqu'on utilise la fonction générique de segmentation" {
        It "Devrait segmenter correctement une chaîne de texte" {
            $text = "A" * 12KB
            $segments = Split-Input -Input $text -ChunkSizeKB 5
            
            $segments.Count | Should -BeGreaterThan 1
        }
        
        It "Devrait segmenter correctement un objet JSON" {
            $json = @{
                items = @()
            }
            
            for ($i = 0; $i -lt 500; $i++) {
                $json.items += @{
                    id = $i
                    name = "Item $i"
                }
            }
            
            $segments = Split-Input -Input $json -ChunkSizeKB 5
            
            $segments.Count | Should -BeGreaterThan 1
        }
        
        It "Devrait segmenter correctement un chemin de fichier" {
            # Créer un fichier temporaire
            $tempFile = Join-Path -Path $TestDrive -ChildPath "test.txt"
            "A" * 12KB | Out-File -FilePath $tempFile -Encoding utf8
            
            $segments = Split-Input -Input $tempFile -ChunkSizeKB 5
            
            $segments.Count | Should -BeGreaterThan 1
        }
    }
}

Describe "Save-SegmentationState and Get-SegmentationState" {
    Context "Lorsqu'on sauvegarde et récupère l'état de segmentation" {
        It "Devrait sauvegarder et récupérer correctement l'état" {
            $id = "test-id"
            $segments = @("Segment 1", "Segment 2", "Segment 3")
            $currentIndex = 1
            
            Save-SegmentationState -Id $id -Segments $segments -CurrentIndex $currentIndex
            $state = Get-SegmentationState -Id $id
            
            $state.Id | Should -Be $id
            $state.Segments.Count | Should -Be 3
            $state.CurrentIndex | Should -Be 1
            $state.TotalSegments | Should -Be 3
        }
        
        It "Devrait retourner $null pour un ID inexistant" {
            $state = Get-SegmentationState -Id "non-existent-id"
            $state | Should -Be $null
        }
    }
}

Describe "Invoke-WithSegmentation" {
    Context "Lorsqu'on exécute un script avec segmentation" {
        It "Devrait exécuter le script pour chaque segment" {
            $input = "A" * 12KB
            $scriptBlock = {
                param($segment)
                return "Processed: $($segment.Length) bytes"
            }
            
            $results = Invoke-WithSegmentation -Input $input -ScriptBlock $scriptBlock -Id "test-invoke" -ChunkSizeKB 5
            
            $results.Count | Should -BeGreaterThan 1
            $results[0] | Should -Match "Processed: \d+ bytes"
        }
    }
}
