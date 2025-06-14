#!/usr/bin/env pwsh

# Phase 7.1.1 - Script de vérification de santé des services
# Health checks complets pour validation du déploiement

param(
    [string]$Environment = "staging",
    [string]$BaseUrl = "http://localhost:8080",
    [int]$TimeoutSeconds = 30,
    [switch]$Detailed,
    [switch]$ContinuousMonitoring
)

# Configuration des couleurs
$ErrorColor = "Red"
$SuccessColor = "Green"
$WarningColor = "Yellow"
$InfoColor = "Cyan"

Write-Host "🔍 Health Check EMAIL_SENDER_1 - $Environment" -ForegroundColor $InfoColor
Write-Host "Base URL: $BaseUrl" -ForegroundColor Gray
Write-Host "Timeout: $TimeoutSeconds secondes" -ForegroundColor Gray
Write-Host "=" * 50 -ForegroundColor Gray

# Fonction utilitaire pour les tests HTTP
function Test-Endpoint {
    param(
        [string]$Url,
        [string]$Name,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [string]$Body = $null,
        [int]$ExpectedStatus = 200
    )
    
    try {
        $startTime = Get-Date
        
        $requestParams = @{
            Uri = $Url
            Method = $Method
            TimeoutSec = $TimeoutSeconds
            Headers = $Headers
        }
        
        if ($Body) {
            $requestParams.Body = $Body
            $requestParams.ContentType = "application/json"
        }
        
        $response = Invoke-RestMethod @requestParams
        $endTime = Get-Date
        $responseTime = ($endTime - $startTime).TotalMilliseconds
        
        Write-Host "✅ $Name" -ForegroundColor $SuccessColor -NoNewline
        Write-Host " (${responseTime}ms)" -ForegroundColor Gray
        
        if ($Detailed -and $response) {
            Write-Host "   Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
        }
        
        return @{
            Success = $true
            ResponseTime = $responseTime
            Response = $response
        }
    }
    catch {
        Write-Host "❌ $Name" -ForegroundColor $ErrorColor -NoNewline
        Write-Host " - $($_.Exception.Message)" -ForegroundColor Gray
        
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Fonction de monitoring continu
function Start-ContinuousMonitoring {
    param([scriptblock]$HealthCheckScript)
    
    Write-Host "`n🔄 Mode monitoring continu activé. Ctrl+C pour arrêter." -ForegroundColor $InfoColor
    
    while ($true) {
        Clear-Host
        Write-Host "🕒 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Health Check en cours..." -ForegroundColor $InfoColor
        
        & $HealthCheckScript
        
        Write-Host "`n⏳ Prochaine vérification dans 30 secondes..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
    }
}

# Script principal de health check
$healthCheckScript = {
    $overallHealth = $true
    $results = @()
    
    # 1. Test du service principal
    Write-Host "`n🏥 Tests de santé du service principal" -ForegroundColor $InfoColor
    
    $healthResult = Test-Endpoint -Url "$BaseUrl/health" -Name "Service Principal Health"
    $results += $healthResult
    if (-not $healthResult.Success) { $overallHealth = $false }
    
    $readinessResult = Test-Endpoint -Url "$BaseUrl/ready" -Name "Service Readiness"
    $results += $readinessResult
    if (-not $readinessResult.Success) { $overallHealth = $false }
    
    # 2. Tests de l'API Gateway
    Write-Host "`n🌐 Tests de l'API Gateway" -ForegroundColor $InfoColor
    
    $statusResult = Test-Endpoint -Url "$BaseUrl/api/v1/status" -Name "API Status"
    $results += $statusResult
    if (-not $statusResult.Success) { $overallHealth = $false }
    
    $managersResult = Test-Endpoint -Url "$BaseUrl/api/v1/managers/status" -Name "Managers Status"
    $results += $managersResult
    if (-not $managersResult.Success) { $overallHealth = $false }
    
    # 3. Tests de la vectorisation
    Write-Host "`n🧮 Tests du service de vectorisation" -ForegroundColor $InfoColor
    
    $vectorHealthResult = Test-Endpoint -Url "$BaseUrl/api/v1/vectors/health" -Name "Vector Service Health"
    $results += $vectorHealthResult
    if (-not $vectorHealthResult.Success) { $overallHealth = $false }
    
    # Test de recherche vectorielle simple
    $searchBody = @{
        query = "test search"
        limit = 1
    } | ConvertTo-Json
    
    $searchResult = Test-Endpoint -Url "$BaseUrl/api/v1/vectors/search" -Name "Vector Search" -Method "POST" -Body $searchBody
    $results += $searchResult
    if (-not $searchResult.Success) { $overallHealth = $false }
    
    # 4. Tests de connectivité Qdrant
    Write-Host "`n🗄️  Tests de connectivité Qdrant" -ForegroundColor $InfoColor
    
    try {
        $qdrantCollections = Invoke-RestMethod -Uri "http://localhost:6333/collections" -Method GET -TimeoutSec 5
        Write-Host "✅ Qdrant Collections" -ForegroundColor $SuccessColor -NoNewline
        Write-Host " ($($qdrantCollections.result.collections.Count) collections)" -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ Qdrant Collections" -ForegroundColor $ErrorColor -NoNewline
        Write-Host " - $($_.Exception.Message)" -ForegroundColor Gray
        $overallHealth = $false
    }
    
    # 5. Tests de performance rapides
    Write-Host "`n⚡ Tests de performance rapides" -ForegroundColor $InfoColor
    
    # Mesurer le temps de réponse moyen sur 5 requêtes
    $responseTimes = @()
    for ($i = 1; $i -le 5; $i++) {
        $perfResult = Test-Endpoint -Url "$BaseUrl/api/v1/status" -Name "Performance Test $i"
        if ($perfResult.Success) {
            $responseTimes += $perfResult.ResponseTime
        }
    }
    
    if ($responseTimes.Count -gt 0) {
        $avgResponseTime = ($responseTimes | Measure-Object -Average).Average
        Write-Host "📊 Temps de réponse moyen: ${avgResponseTime}ms" -ForegroundColor $InfoColor
        
        if ($avgResponseTime -gt 500) {
            Write-Host "⚠️  Performances dégradées (>500ms)" -ForegroundColor $WarningColor
        }
    }
    
    # 6. Tests des métriques
    Write-Host "`n📈 Tests des métriques" -ForegroundColor $InfoColor
    
    $metricsResult = Test-Endpoint -Url "$BaseUrl/metrics" -Name "Prometheus Metrics"
    $results += $metricsResult
    
    # 7. Résumé final
    Write-Host "`n📋 Résumé du Health Check" -ForegroundColor $InfoColor
    Write-Host "=" * 30 -ForegroundColor Gray
    
    $successCount = ($results | Where-Object { $_.Success }).Count
    $totalCount = $results.Count
    
    Write-Host "Tests réussis: $successCount/$totalCount" -ForegroundColor $InfoColor
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    
    if ($overallHealth) {
        Write-Host "`n🎉 Tous les services sont opérationnels!" -ForegroundColor $SuccessColor
        return 0
    }
    else {
        Write-Host "`n⚠️  Certains services présentent des problèmes" -ForegroundColor $WarningColor
        return 1
    }
}

# Exécution
try {
    if ($ContinuousMonitoring) {
        Start-ContinuousMonitoring -HealthCheckScript $healthCheckScript
    }
    else {
        $exitCode = & $healthCheckScript
        exit $exitCode
    }
}
catch {
    Write-Host "`n❌ Erreur lors du health check: $($_.Exception.Message)" -ForegroundColor $ErrorColor
    exit 1
}
