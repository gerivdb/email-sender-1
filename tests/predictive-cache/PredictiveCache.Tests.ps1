#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module PredictiveCache.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module PredictiveCache,
    vérifiant le fonctionnement du cache prédictif.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-11
#>

BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PredictiveCache.psm1"
    Import-Module $modulePath -Force
    
    # Initialiser le module avec un dossier de cache temporaire
    $tempCachePath = Join-Path -Path $TestDrive -ChildPath "cache"
    $tempModelPath = Join-Path -Path $TestDrive -ChildPath "models"
    $tempLogsPath = Join-Path -Path $TestDrive -ChildPath "logs"
    
    Initialize-PredictiveCache -Enabled $true -CachePath $tempCachePath -ModelPath $tempModelPath -MaxCacheSize 10MB -DefaultTTL 60
}

Describe "Set-PredictiveCache and Get-PredictiveCache" {
    Context "Lorsqu'on met en cache et récupère des valeurs" {
        It "Devrait récupérer la même valeur qui a été mise en cache" {
            $key = "test-key-$(Get-Random)"
            $value = "test-value-$(Get-Random)"
            
            Set-PredictiveCache -Key $key -Value $value
            $result = Get-PredictiveCache -Key $key
            
            $result | Should -Be $value
        }
        
        It "Devrait retourner $null pour une clé inexistante" {
            $key = "non-existent-key-$(Get-Random)"
            $result = Get-PredictiveCache -Key $key
            
            $result | Should -Be $null
        }
        
        It "Devrait respecter le TTL spécifié" {
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
    Context "Lorsqu'on supprime des entrées du cache" {
        It "Devrait supprimer une entrée existante" {
            $key = "remove-test-key-$(Get-Random)"
            $value = "remove-test-value-$(Get-Random)"
            
            Set-PredictiveCache -Key $key -Value $value
            $result1 = Get-PredictiveCache -Key $key
            $result1 | Should -Be $value
            
            Remove-PredictiveCache -Key $key
            $result2 = Get-PredictiveCache -Key $key
            $result2 | Should -Be $null
        }
        
        It "Devrait retourner $false pour une clé inexistante" {
            $key = "non-existent-key-$(Get-Random)"
            $result = Remove-PredictiveCache -Key $key
            
            $result | Should -Be $false
        }
        
        It "Devrait invalider les entrées liées lorsque demandé" {
            $key1 = "related-key1-$(Get-Random)"
            $key2 = "related-key2-$(Get-Random)"
            $value1 = "related-value1-$(Get-Random)"
            $value2 = "related-value2-$(Get-Random)"
            
            # Mettre en cache les valeurs
            Set-PredictiveCache -Key $key1 -Value $value1
            Set-PredictiveCache -Key $key2 -Value $value2
            
            # Enregistrer une séquence d'accès
            Register-CacheAccess -Key $key1 -WorkflowId "test-workflow" -NodeId "test-node"
            Register-CacheAccess -Key $key2 -WorkflowId "test-workflow" -NodeId "test-node"
            
            # Supprimer la première entrée et invalider les entrées liées
            Remove-PredictiveCache -Key $key1 -InvalidateRelated
            
            # Vérifier que les deux entrées ont été supprimées
            $result1 = Get-PredictiveCache -Key $key1
            $result2 = Get-PredictiveCache -Key $key2
            
            $result1 | Should -Be $null
            $result2 | Should -Be $null
        }
    }
}

Describe "Register-CacheAccess and Get-PredictedCacheKeys" {
    Context "Lorsqu'on enregistre des accès au cache et prédit les prochains accès" {
        It "Devrait prédire correctement les prochains accès" {
            # Créer une séquence d'accès
            $key1 = "seq-key1-$(Get-Random)"
            $key2 = "seq-key2-$(Get-Random)"
            $key3 = "seq-key3-$(Get-Random)"
            
            # Enregistrer plusieurs fois la même séquence d'accès
            for ($i = 0; $i -lt 5; $i++) {
                Register-CacheAccess -Key $key1 -WorkflowId "test-workflow" -NodeId "test-node"
                Register-CacheAccess -Key $key2 -WorkflowId "test-workflow" -NodeId "test-node"
                Register-CacheAccess -Key $key3 -WorkflowId "test-workflow" -NodeId "test-node"
            }
            
            # Obtenir les prédictions pour la première clé
            $predictions = Get-PredictedCacheKeys -Key $key1 -WorkflowId "test-workflow" -NodeId "test-node"
            
            # Vérifier que la deuxième clé est prédite
            $predictions.Count | Should -BeGreaterThan 0
            $predictions[0].Key | Should -Be $key2
        }
        
        It "Devrait prendre en compte le contexte (workflow et nœud)" {
            $key = "context-key-$(Get-Random)"
            $workflow1 = "workflow1-$(Get-Random)"
            $workflow2 = "workflow2-$(Get-Random)"
            $node1 = "node1-$(Get-Random)"
            $node2 = "node2-$(Get-Random)"
            
            # Enregistrer des accès dans différents contextes
            Register-CacheAccess -Key $key -WorkflowId $workflow1 -NodeId $node1
            Register-CacheAccess -Key "next1" -WorkflowId $workflow1 -NodeId $node1
            
            Register-CacheAccess -Key $key -WorkflowId $workflow2 -NodeId $node2
            Register-CacheAccess -Key "next2" -WorkflowId $workflow2 -NodeId $node2
            
            # Obtenir les prédictions pour chaque contexte
            $predictions1 = Get-PredictedCacheKeys -Key $key -WorkflowId $workflow1 -NodeId $node1
            $predictions2 = Get-PredictedCacheKeys -Key $key -WorkflowId $workflow2 -NodeId $node2
            
            # Vérifier que les prédictions sont spécifiques au contexte
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
        It "Devrait supprimer les entrées les plus anciennes lorsque la taille maximale est dépassée" {
            # Réinitialiser le cache avec une taille maximale très petite
            Initialize-PredictiveCache -Enabled $true -CachePath $tempCachePath -ModelPath $tempModelPath -MaxCacheSize 5KB -DefaultTTL 3600
            
            # Mettre en cache plusieurs entrées pour dépasser la taille maximale
            for ($i = 0; $i -lt 10; $i++) {
                $key = "size-test-key-$i"
                $value = "A" * 1KB  # Valeur d'environ 1 KB
                Set-PredictiveCache -Key $key -Value $value
                
                # Ajouter un délai pour s'assurer que les timestamps sont différents
                Start-Sleep -Milliseconds 100
            }
            
            # Vérifier que certaines entrées ont été supprimées
            $entriesExist = 0
            for ($i = 0; $i -lt 10; $i++) {
                $key = "size-test-key-$i"
                $value = Get-PredictiveCache -Key $key
                if ($value -ne $null) {
                    $entriesExist++
                }
            }
            
            # Il devrait y avoir moins de 10 entrées (certaines ont été supprimées)
            $entriesExist | Should -BeLessThan 10
        }
    }
}

Describe "Register-N8nCacheHook" {
    Context "Lorsqu'on configure l'intégration avec n8n" {
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
