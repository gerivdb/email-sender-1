# Tests pour les fonctions de mise en cache des résultats de sélection du noyau optimal
# Run with Pester: Invoke-Pester -Path ".\KernelSelectionCache.Tests.ps1"

# Importer les modules contenant les fonctions à tester
$scriptPath = Split-Path -Parent $PSScriptRoot
. "$scriptPath\KernelSelectionCache.ps1"
. "$scriptPath\KernelSelectionConfig.ps1"

# Fonction utilitaire pour générer des échantillons de distribution normale
function Get-NormalSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,
        
        [Parameter(Mandatory = $false)]
        [double]$Mean = 0,
        
        [Parameter(Mandatory = $false)]
        [double]$StdDev = 1
    )
    
    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        # Méthode Box-Muller pour générer des nombres aléatoires suivant une distribution normale
        $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
        $u2 = Get-Random -Minimum 0 -Maximum 1
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        $sample += $Mean + $StdDev * $z
    }
    
    return $sample
}

Describe "Tests pour Get-CacheKey" {
    Context "Tests de base" {
        It "Devrait générer une clé de cache pour les données" {
            $data = @(1, 2, 3, 4, 5)
            $cacheKey = Get-CacheKey -Data $data
            
            $cacheKey | Should -Not -BeNullOrEmpty
            $cacheKey | Should -BeOfType [string]
            $cacheKey.Length | Should -Be 64  # SHA256 hash length in hexadecimal
        }
        
        It "Devrait générer des clés de cache différentes pour des données différentes" {
            $data1 = @(1, 2, 3, 4, 5)
            $data2 = @(1, 2, 3, 4, 6)
            
            $cacheKey1 = Get-CacheKey -Data $data1
            $cacheKey2 = Get-CacheKey -Data $data2
            
            $cacheKey1 | Should -Not -Be $cacheKey2
        }
        
        It "Devrait générer des clés de cache différentes pour des paramètres supplémentaires différents" {
            $data = @(1, 2, 3, 4, 5)
            
            $cacheKey1 = Get-CacheKey -Data $data -AdditionalParams @{ KernelType = "Gaussian" }
            $cacheKey2 = Get-CacheKey -Data $data -AdditionalParams @{ KernelType = "Epanechnikov" }
            
            $cacheKey1 | Should -Not -Be $cacheKey2
        }
        
        It "Devrait générer des clés de cache identiques pour les mêmes données et paramètres" {
            $data = @(1, 2, 3, 4, 5)
            
            $cacheKey1 = Get-CacheKey -Data $data -AdditionalParams @{ KernelType = "Gaussian" }
            $cacheKey2 = Get-CacheKey -Data $data -AdditionalParams @{ KernelType = "Gaussian" }
            
            $cacheKey1 | Should -Be $cacheKey2
        }
    }
}

Describe "Tests pour Get-KernelSelectionCacheResult et Add-KernelSelectionCacheResult" {
    Context "Tests de base" {
        BeforeEach {
            # Sauvegarder la configuration actuelle
            $script:originalConfig = Get-KernelSelectionConfig
            
            # Activer la mise en cache
            $config = Get-KernelSelectionConfig
            $config.Cache.Enabled = $true
            $config.Cache.MaxCacheSize = 100
            $config.Cache.ExpirationTime = 3600
            Set-KernelSelectionConfig -Config $config
            
            # Réinitialiser le cache
            $script:KernelSelectionCache.Characteristics.Clear()
            $script:KernelSelectionCache.CrossValidation.Clear()
            $script:KernelSelectionCache.Stats.Hits = 0
            $script:KernelSelectionCache.Stats.Misses = 0
            $script:KernelSelectionCache.Stats.Evictions = 0
            $script:KernelSelectionCache.Stats.LastCleanup = [DateTime]::Now
        }
        
        AfterEach {
            # Restaurer la configuration originale
            Set-KernelSelectionConfig -Config $script:originalConfig
        }
        
        It "Devrait retourner null si le résultat n'est pas dans le cache" {
            $data = @(1, 2, 3, 4, 5)
            
            $result = Get-KernelSelectionCacheResult -Data $data
            
            $result | Should -BeNullOrEmpty
        }
        
        It "Devrait ajouter et récupérer un résultat du cache" {
            $data = @(1, 2, 3, 4, 5)
            
            Add-KernelSelectionCacheResult -Data $data -Result "Gaussian"
            $result = Get-KernelSelectionCacheResult -Data $data
            
            $result | Should -Be "Gaussian"
        }
        
        It "Devrait ajouter et récupérer un résultat du cache avec des paramètres supplémentaires" {
            $data = @(1, 2, 3, 4, 5)
            
            Add-KernelSelectionCacheResult -Data $data -Result "Gaussian" -AdditionalParams @{ KernelType = "Gaussian" }
            $result = Get-KernelSelectionCacheResult -Data $data -AdditionalParams @{ KernelType = "Gaussian" }
            
            $result | Should -Be "Gaussian"
        }
        
        It "Devrait ajouter et récupérer un résultat du cache pour différentes méthodes de sélection" {
            $data = @(1, 2, 3, 4, 5)
            
            Add-KernelSelectionCacheResult -Data $data -Result "Gaussian" -SelectionMethod "Characteristics"
            Add-KernelSelectionCacheResult -Data $data -Result "Epanechnikov" -SelectionMethod "CrossValidation"
            
            $result1 = Get-KernelSelectionCacheResult -Data $data -SelectionMethod "Characteristics"
            $result2 = Get-KernelSelectionCacheResult -Data $data -SelectionMethod "CrossValidation"
            
            $result1 | Should -Be "Gaussian"
            $result2 | Should -Be "Epanechnikov"
        }
        
        It "Devrait incrémenter le compteur de hits lors de la récupération d'un résultat du cache" {
            $data = @(1, 2, 3, 4, 5)
            
            Add-KernelSelectionCacheResult -Data $data -Result "Gaussian"
            $result = Get-KernelSelectionCacheResult -Data $data
            
            $stats = Get-KernelSelectionCacheStats
            $stats.Hits | Should -Be 1
        }
        
        It "Devrait incrémenter le compteur de misses lors de la récupération d'un résultat non présent dans le cache" {
            $data = @(1, 2, 3, 4, 5)
            
            $result = Get-KernelSelectionCacheResult -Data $data
            
            $stats = Get-KernelSelectionCacheStats
            $stats.Misses | Should -Be 1
        }
        
        It "Devrait nettoyer le cache lorsque la taille maximale est atteinte" {
            $config = Get-KernelSelectionConfig
            $config.Cache.MaxCacheSize = 2
            Set-KernelSelectionConfig -Config $config
            
            $data1 = @(1, 2, 3, 4, 5)
            $data2 = @(2, 3, 4, 5, 6)
            $data3 = @(3, 4, 5, 6, 7)
            
            Add-KernelSelectionCacheResult -Data $data1 -Result "Gaussian"
            Add-KernelSelectionCacheResult -Data $data2 -Result "Epanechnikov"
            Add-KernelSelectionCacheResult -Data $data3 -Result "Triangular"
            
            $result1 = Get-KernelSelectionCacheResult -Data $data1
            $result2 = Get-KernelSelectionCacheResult -Data $data2
            $result3 = Get-KernelSelectionCacheResult -Data $data3
            
            $result1 | Should -BeNullOrEmpty
            $result2 | Should -Be "Epanechnikov"
            $result3 | Should -Be "Triangular"
            
            $stats = Get-KernelSelectionCacheStats
            $stats.Evictions | Should -Be 1
        }
    }
}

Describe "Tests pour Clear-KernelSelectionCache" {
    Context "Tests de base" {
        BeforeEach {
            # Sauvegarder la configuration actuelle
            $script:originalConfig = Get-KernelSelectionConfig
            
            # Activer la mise en cache
            $config = Get-KernelSelectionConfig
            $config.Cache.Enabled = $true
            $config.Cache.MaxCacheSize = 100
            $config.Cache.ExpirationTime = 1  # 1 seconde pour faciliter les tests d'expiration
            Set-KernelSelectionConfig -Config $config
            
            # Réinitialiser le cache
            $script:KernelSelectionCache.Characteristics.Clear()
            $script:KernelSelectionCache.CrossValidation.Clear()
            $script:KernelSelectionCache.Stats.Hits = 0
            $script:KernelSelectionCache.Stats.Misses = 0
            $script:KernelSelectionCache.Stats.Evictions = 0
            $script:KernelSelectionCache.Stats.LastCleanup = [DateTime]::Now
        }
        
        AfterEach {
            # Restaurer la configuration originale
            Set-KernelSelectionConfig -Config $script:originalConfig
        }
        
        It "Devrait nettoyer le cache en supprimant les entrées expirées" {
            $data = @(1, 2, 3, 4, 5)
            
            Add-KernelSelectionCacheResult -Data $data -Result "Gaussian"
            
            # Attendre que l'entrée expire
            Start-Sleep -Seconds 2
            
            Clear-KernelSelectionCache
            
            $result = Get-KernelSelectionCacheResult -Data $data
            
            $result | Should -BeNullOrEmpty
            
            $stats = Get-KernelSelectionCacheStats
            $stats.Evictions | Should -Be 1
        }
    }
}

Describe "Tests pour Get-KernelSelectionCacheStats" {
    Context "Tests de base" {
        BeforeEach {
            # Sauvegarder la configuration actuelle
            $script:originalConfig = Get-KernelSelectionConfig
            
            # Activer la mise en cache
            $config = Get-KernelSelectionConfig
            $config.Cache.Enabled = $true
            $config.Cache.MaxCacheSize = 100
            $config.Cache.ExpirationTime = 3600
            Set-KernelSelectionConfig -Config $config
            
            # Réinitialiser le cache
            $script:KernelSelectionCache.Characteristics.Clear()
            $script:KernelSelectionCache.CrossValidation.Clear()
            $script:KernelSelectionCache.Stats.Hits = 0
            $script:KernelSelectionCache.Stats.Misses = 0
            $script:KernelSelectionCache.Stats.Evictions = 0
            $script:KernelSelectionCache.Stats.LastCleanup = [DateTime]::Now
        }
        
        AfterEach {
            # Restaurer la configuration originale
            Set-KernelSelectionConfig -Config $script:originalConfig
        }
        
        It "Devrait retourner les statistiques du cache" {
            $data1 = @(1, 2, 3, 4, 5)
            $data2 = @(2, 3, 4, 5, 6)
            
            Add-KernelSelectionCacheResult -Data $data1 -Result "Gaussian" -SelectionMethod "Characteristics"
            Add-KernelSelectionCacheResult -Data $data2 -Result "Epanechnikov" -SelectionMethod "CrossValidation"
            
            $result1 = Get-KernelSelectionCacheResult -Data $data1 -SelectionMethod "Characteristics"
            $result2 = Get-KernelSelectionCacheResult -Data $data2 -SelectionMethod "CrossValidation"
            $result3 = Get-KernelSelectionCacheResult -Data @(3, 4, 5, 6, 7) -SelectionMethod "Characteristics"
            
            $stats = Get-KernelSelectionCacheStats
            
            $stats.Hits | Should -Be 2
            $stats.Misses | Should -Be 1
            $stats.CharacteristicsCount | Should -Be 1
            $stats.CrossValidationCount | Should -Be 1
            $stats.TotalCount | Should -Be 2
            $stats.HitRate | Should -Be 0.6666666666666666
        }
    }
}
