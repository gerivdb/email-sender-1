#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module PredictiveCache.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module PredictiveCache,
    vÃ©rifiant le fonctionnement du cache prÃ©dictif.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-05-11
#>

BeforeAll {
    # Importer le module Ã  tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PredictiveCache.psm1"
    Import-Module $modulePath -Force
    
    # Initialiser le module avec un dossier de cache temporaire
    $tempCachePath = Join-Path -Path $TestDrive -ChildPath "cache"
    $tempModelPath = Join-Path -Path $TestDrive -ChildPath "models"
    $tempLogsPath = Join-Path -Path $TestDrive -ChildPath "logs"
    
    Initialize-PredictiveCache -Enabled $true -CachePath $tempCachePath -ModelPath $tempModelPath -MaxCacheSize 10MB -DefaultTTL 60
}

Describe "Set-PredictiveCache and Get-PredictiveCache" {
    Context "Lorsqu'on met en cache et rÃ©cupÃ¨re des valeurs" {
        It "Devrait rÃ©cupÃ©rer la mÃªme valeur qui a Ã©tÃ© mise en cache" {
            $key = "test-key-$(Get-Random)"
            $value = "test-value-$(Get-Random)"
            
            Set-PredictiveCache -Key $key -Value $value
            $result = Get-PredictiveCache -Key $key
            
            $result | Should -Be $value
        }
        
        It "Devrait retourner $null pour une clÃ© inexistante" {
            $key = "non-existent-key-$(Get-Random)"
            $result = Get-PredictiveCache -Key $key
            
            $result | Should -Be $null
        }
        
        It "Devrait respecter le TTL spÃ©cifiÃ©" {
            $key = "ttl-test-key-$(Get-Random)"
            $value = "ttl-test-value-$(Get-Random)"
            
            Set-PredictiveCache -Key $key -Value $value -TTL 1
            
            # Attendre que le cache expire
            Start-Sleep -Seconds 2
            
            $result = Get-PredictiveCache -Key $key
            $result | Should -Be $null
        }
        
        It "Devrait mettre en cache des objets complexes" {
            $key = "complex-key-$(Get-Random)"
            $value = @{
                name = "Test Object"
                properties = @{
                    prop1 = "Value 1"
                    prop2 = 123
                    prop3 = $true
                }
                items = @(1, 2, 3, 4, 5)
            }
            
            Set-PredictiveCache -Key $key -Value $value
            $result = Get-PredictiveCache -Key $key
            
            $result.name | Should -Be "Test Object"
            $result.properties.prop1 | Should -Be "Value 1"
            $result.properties.prop2 | Should -Be 123
            $result.properties.prop3 | Should -Be $true
            $result.items.Count | Should -Be 5
            $result.items[0] | Should -Be 1
            $result.items[4] | Should -Be 5
        }
    }
}

Describe "Remove-PredictiveCache" {
    Context "Lorsqu'on supprime des entrÃ©es du cache" {
        It "Devrait supprimer une entrÃ©e existante" {
            $key = "remove-test-key-$(Get-Random)"
            $value = "remove-test-value-$(Get-Random)"
            
            Set-PredictiveCache -Key $key -Value $value
            $result1 = Get-PredictiveCache -Key $key
            $result1 | Should -Be $value
            
            Remove-PredictiveCache -Key $key
            $result2 = Get-PredictiveCache -Key $key
            $result2 | Should -Be $null
        }
        
        It "Devrait retourner $false pour une clÃ© inexistante" {
            $key = "non-existent-key-$(Get-Random)"
            $result = Remove-PredictiveCache -Key $key
            
            $result | Should -Be $false
        }
        
        It "Devrait invalider les entrÃ©es liÃ©es lorsque demandÃ©" {
            $key1 = "related-key1-$(Get-Random)"
            $key2 = "related-key2-$(Get-Random)"
            $value1 = "related-value1-$(Get-Random)"
            $value2 = "related-value2-$(Get-Random)"
            
            # Mettre en cache les valeurs
            Set-PredictiveCache -Key $key1 -Value $value1
            Set-PredictiveCache -Key $key2 -Value $value2
            
            # Enregistrer une sÃ©quence d'accÃ¨s
            Register-CacheAccess -Key $key1 -WorkflowId "test-workflow" -NodeId "test-node"
            Register-CacheAccess -Key $key2 -WorkflowId "test-workflow" -NodeId "test-node"
            
            # Supprimer la premiÃ¨re entrÃ©e et invalider les entrÃ©es liÃ©es
            Remove-PredictiveCache -Key $key1 -InvalidateRelated
            
            # VÃ©rifier que les deux entrÃ©es ont Ã©tÃ© supprimÃ©es
            $result1 = Get-PredictiveCache -Key $key1
            $result2 = Get-PredictiveCache -Key $key2
            
            $result1 | Should -Be $null
            $result2 | Should -Be $null
        }
    }
}

Describe "Register-CacheAccess and Get-PredictedCacheKeys" {
    Context "Lorsqu'on enregistre des accÃ¨s au cache et prÃ©dit les prochains accÃ¨s" {
        It "Devrait prÃ©dire correctement les prochains accÃ¨s" {
            # CrÃ©er une sÃ©quence d'accÃ¨s
            $key1 = "seq-key1-$(Get-Random)"
            $key2 = "seq-key2-$(Get-Random)"
            $key3 = "seq-key3-$(Get-Random)"
            
            # Enregistrer plusieurs fois la mÃªme sÃ©quence d'accÃ¨s
            for ($i = 0; $i -lt 5; $i++) {
                Register-CacheAccess -Key $key1 -WorkflowId "test-workflow" -NodeId "test-node"
                Register-CacheAccess -Key $key2 -WorkflowId "test-workflow" -NodeId "test-node"
                Register-CacheAccess -Key $key3 -WorkflowId "test-workflow" -NodeId "test-node"
            }
            
            # Obtenir les prÃ©dictions pour la premiÃ¨re clÃ©
            $predictions = Get-PredictedCacheKeys -Key $key1 -WorkflowId "test-workflow" -NodeId "test-node"
            
            # VÃ©rifier que la deuxiÃ¨me clÃ© est prÃ©dite
            $predictions.Count | Should -BeGreaterThan 0
            $predictions[0].Key | Should -Be $key2
        }
        
        It "Devrait prendre en compte le contexte (workflow et nÅ“ud)" {
            $key = "context-key-$(Get-Random)"
            $workflow1 = "workflow1-$(Get-Random)"
            $workflow2 = "workflow2-$(Get-Random)"
            $node1 = "node1-$(Get-Random)"
            $node2 = "node2-$(Get-Random)"
            
            # Enregistrer des accÃ¨s dans diffÃ©rents contextes
            Register-CacheAccess -Key $key -WorkflowId $workflow1 -NodeId $node1
            Register-CacheAccess -Key "next1" -WorkflowId $workflow1 -NodeId $node1
            
            Register-CacheAccess -Key $key -WorkflowId $workflow2 -NodeId $node2
            Register-CacheAccess -Key "next2" -WorkflowId $workflow2 -NodeId $node2
            
            # Obtenir les prÃ©dictions pour chaque contexte
            $predictions1 = Get-PredictedCacheKeys -Key $key -WorkflowId $workflow1 -NodeId $node1
            $predictions2 = Get-PredictedCacheKeys -Key $key -WorkflowId $workflow2 -NodeId $node2
            
            # VÃ©rifier que les prÃ©dictions sont spÃ©cifiques au contexte
            if ($predictions1.Count -gt 0) {
                $predictions1[0].Key | Should -Be "next1"
            }
            
            if ($predictions2.Count -gt 0) {
                $predictions2[0].Key | Should -Be "next2"
            }
        }
    }
}

Describe "Optimize-CacheSize" {
    Context "Lorsqu'on optimise la taille du cache" {
        It "Devrait supprimer les entrÃ©es les plus anciennes lorsque la taille maximale est dÃ©passÃ©e" {
            # RÃ©initialiser le cache avec une taille maximale trÃ¨s petite
            Initialize-PredictiveCache -Enabled $true -CachePath $tempCachePath -ModelPath $tempModelPath -MaxCacheSize 5KB -DefaultTTL 3600
            
            # Mettre en cache plusieurs entrÃ©es pour dÃ©passer la taille maximale
            for ($i = 0; $i -lt 10; $i++) {
                $key = "size-test-key-$i"
                $value = "A" * 1KB  # Valeur d'environ 1 KB
                Set-PredictiveCache -Key $key -Value $value
                
                # Ajouter un dÃ©lai pour s'assurer que les timestamps sont diffÃ©rents
                Start-Sleep -Milliseconds 100
            }
            
            # VÃ©rifier que certaines entrÃ©es ont Ã©tÃ© supprimÃ©es
            $entriesExist = 0
            for ($i = 0; $i -lt 10; $i++) {
                $key = "size-test-key-$i"
                $value = Get-PredictiveCache -Key $key
                if ($value -ne $null) {
                    $entriesExist++
                }
            }
            
            # Il devrait y avoir moins de 10 entrÃ©es (certaines ont Ã©tÃ© supprimÃ©es)
            $entriesExist | Should -BeLessThan 10
        }
    }
}

Describe "Register-N8nCacheHook" {
    Context "Lorsqu'on configure l'intÃ©gration avec n8n" {
        BeforeAll {
            # Mock pour Invoke-RestMethod
            Mock Invoke-RestMethod {
                return @{
                    status = "ok"
                    version = "1.0.0"
                }
            }
        }
        
        It "Devrait retourner $true lorsque n8n est disponible" {
            $result = Register-N8nCacheHook -N8nApiUrl "http://localhost:5678/api/v1"
            $result | Should -Be $true
        }
    }
}
