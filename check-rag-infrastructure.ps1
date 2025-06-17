# Script pour tester l'infrastructure du RAG Server
$outputFile = Join-Path $PSScriptRoot "rag-server-check-results.txt"

# Fonction pour écrire à la fois dans le terminal et dans un fichier
function Write-Log {
   param(
      [string]$message,
      [string]$color = "White"
   )
    
   Write-Host $message -ForegroundColor $color
   Add-Content -Path $outputFile -Value $message
}

# Nettoyer le fichier de sortie
if (Test-Path $outputFile) {
   Remove-Item $outputFile -Force
}

Write-Log "=== VÉRIFICATION DE L'INFRASTRUCTURE RAG SERVER ===" "Cyan"
Write-Log "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Cyan"
Write-Log "--------------------------------------------" "Cyan"

# 1. Vérifier l'état des conteneurs Docker
Write-Log "1. État des conteneurs Docker" "Yellow"
try {
   $containersOutput = docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" 
   Write-Log $containersOutput "White"
    
   $ragServerContainer = docker ps -a --format "{{.Names}}" | Where-Object { $_ -like "*rag_server*" }
   if ($ragServerContainer) {
      $ragServerStatus = docker inspect --format "{{.State.Status}}" $ragServerContainer
      Write-Log "RAG Server Status: $ragServerStatus" "Green"
        
      if ($ragServerStatus -eq "running") {
         $healthStatus = docker inspect --format "{{.State.Health.Status}}" $ragServerContainer 2>$null
         if ($healthStatus) {
            Write-Log "RAG Server Health: $healthStatus" "Green"
         }
      }
   }
   else {
      Write-Log "Conteneur RAG Server non trouvé!" "Red"
   }
}
catch {
   Write-Log "Erreur lors de la vérification des conteneurs: $_" "Red"
}

Write-Log "--------------------------------------------" "Cyan"

# 2. Vérifier les dépendances dans le docker-compose
Write-Log "2. Analyse des dépendances dans docker-compose.yml" "Yellow"
try {
   $dockerComposePath = Join-Path $PSScriptRoot "docker-compose.yml"
   if (Test-Path $dockerComposePath) {
      $dockerComposeContent = Get-Content $dockerComposePath -Raw
        
      if ($dockerComposeContent -match "rag_server:(.*?)depends_on:(.*?)(\w+):(.*?)condition: service_healthy") {
         Write-Log "RAG Server dépend de services avec condition 'service_healthy'" "Yellow"
            
         # Extraire toutes les dépendances
         $matches = [regex]::Matches($dockerComposeContent, "rag_server:.*?depends_on:(.*?)(?=\w+:)")
         if ($matches.Count -gt 0) {
            foreach ($match in $matches) {
               Write-Log "Dépendances trouvées: $($match.Value)" "White"
            }
         }
      }
   }
   else {
      Write-Log "Fichier docker-compose.yml non trouvé" "Red"
   }
}
catch {
   Write-Log "Erreur lors de l'analyse du docker-compose: $_" "Red"
}

Write-Log "--------------------------------------------" "Cyan"

# 3. Vérifier si le serveur RAG est accessible
Write-Log "3. Test d'accessibilité du serveur RAG" "Yellow"

function Test-Endpoint {
   param(
      [string]$endpoint,
      [string]$description
   )
    
   try {
      $response = Invoke-WebRequest -Uri $endpoint -UseBasicParsing -TimeoutSec 5
      Write-Log "$description - Status: $($response.StatusCode) $($response.StatusDescription)" "Green"
      return $true
   }
   catch {
      Write-Log "$description - Erreur: $($_.Exception.Message)" "Red"
      return $false
   }
}

$healthEndpoint = "http://localhost:8080/health"
$monitoringEndpoint = "http://localhost:8080/api/v1/monitoring/status"
$infrastructureEndpoint = "http://localhost:8080/api/v1/infrastructure/status"

$healthOk = Test-Endpoint -endpoint $healthEndpoint -description "Health Endpoint"
$monitoringOk = Test-Endpoint -endpoint $monitoringEndpoint -description "Monitoring Endpoint"
$infrastructureOk = Test-Endpoint -endpoint $infrastructureEndpoint -description "Infrastructure Endpoint"

Write-Log "--------------------------------------------" "Cyan"

# 4. Vérifier les logs du conteneur
Write-Log "4. Logs du conteneur RAG Server" "Yellow"
try {
   if ($ragServerContainer) {
      $logs = docker logs --tail 20 $ragServerContainer 2>&1
      Write-Log "Dernières lignes des logs:" "White"
      foreach ($line in $logs) {
         Write-Log $line "White"
      }
   }
}
catch {
   Write-Log "Erreur lors de la récupération des logs: $_" "Red"
}

Write-Log "--------------------------------------------" "Cyan"

# 5. Vérifier l'état de Qdrant et qdrant_proxy
Write-Log "5. Vérification des services Qdrant" "Yellow"
try {
   $qdrantContainer = docker ps -a --format "{{.Names}}" | Where-Object { $_ -like "*qdrant-1*" }
   $qdrantProxyContainer = docker ps -a --format "{{.Names}}" | Where-Object { $_ -like "*qdrant_proxy*" }
    
   if ($qdrantContainer) {
      $status = docker inspect --format "{{.State.Status}}" $qdrantContainer
      Write-Log "Qdrant Status: $status" "White"
   }
    
   if ($qdrantProxyContainer) {
      $status = docker inspect --format "{{.State.Status}}" $qdrantProxyContainer
      $health = docker inspect --format "{{.State.Health.Status}}" $qdrantProxyContainer 2>$null
      Write-Log "Qdrant Proxy Status: $status, Health: $health" "White"
        
      # Tester l'accessibilité du proxy
      Test-Endpoint -endpoint "http://localhost:6333/health" -description "Qdrant Proxy Health Endpoint"
      Test-Endpoint -endpoint "http://localhost:6333" -description "Qdrant Proxy Root Endpoint"
   }
}
catch {
   Write-Log "Erreur lors de la vérification des services Qdrant: $_" "Red"
}

Write-Log "--------------------------------------------" "Cyan"
Write-Log "Résultats enregistrés dans le fichier: $outputFile" "Cyan"
