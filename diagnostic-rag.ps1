# Script de diagnostic rapide
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logFile = "diagnostic-rag-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$message)
    $logMessage = "[$timestamp] $message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "=== DIAGNOSTIC RAG SERVER ==="

# 1. Vérification des conteneurs Docker
Write-Log "1. État des conteneurs Docker"
try {
    $containers = docker ps -a --format "{{.Names}}\t{{.Status}}" | Out-String
    Write-Log "Conteneurs: $containers"
} catch {
    Write-Log "Erreur Docker: $_"
}

# 2. Test de connectivité port 8080
Write-Log "2. Test port 8080"
try {
    $portTest = Test-NetConnection -ComputerName localhost -Port 8080 -InformationLevel Quiet
    Write-Log "Port 8080 accessible: $portTest"
} catch {
    Write-Log "Erreur test port: $_"
}

# 3. Test de connectivité port 6333 (Qdrant)
Write-Log "3. Test port 6333"
try {
    $qdrantTest = Test-NetConnection -ComputerName localhost -Port 6333 -InformationLevel Quiet
    Write-Log "Port 6333 accessible: $qdrantTest"
} catch {
    Write-Log "Erreur test Qdrant: $_"
}

# 4. Vérification des processus en écoute
Write-Log "4. Processus en écoute sur ports 8080 et 6333"
try {
    $listening = netstat -an | findstr ":8080\|:6333"
    Write-Log "Ports en écoute: $listening"
} catch {
    Write-Log "Erreur netstat: $_"
}

Write-Log "=== FIN DIAGNOSTIC ==="
Write-Log "Log enregistré dans: $logFile"
