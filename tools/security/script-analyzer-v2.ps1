# Script Analyzer - Security Audit Tool
# Plan Dev v41 - Phase 1.1.1.1 - Script Security Analysis
# Version: 1.1
# Date: 2025-06-03

[CmdletBinding()]
param(
   [Parameter(Mandatory = $true)]
   [string]$ScriptPath,
    
   [string]$OutputPath = ".\security-audit-report.json",
    
   [switch]$DetailedOutput
)

# Configuration de l'analyseur
$SecurityPatterns = @{
   Critical = @{
      "Move-Item sans validation"           = "Move-Item.*\$"
      "Get-ChildItem récursif non contrôlé" = "Get-ChildItem.*-Recurse"
      "Remove-Item dangereux"               = "Remove-Item.*-Force"
      "Suppression sans confirmation"       = 'Remove-Item.*-Confirm:.*false'
      "Accès aux fichiers système"          = '\$env:'
      "Exécution de commandes externes"     = "Invoke-Expression|iex|&"
   }
   Major    = @{
      "Pas de validation d'entrée" = 'param.*\[string\].*(?!.*Mandatory)'
      "Chemins hardcodés"          = '[A-Z]:\\'
      "Pas de gestion d'erreur"    = '(?!.*try).*Move-Item'
      "Variables non initialisées" = '\$[a-zA-Z]+ ='
      "Filtrage insuffisant"       = 'Where-Object.*-notcontains'
   }
   Minor    = @{
      "Pas de logging"             = '(?!.*Write-).*Move-Item'
      "Pas de progress indicator"  = "ForEach-Object(?!.*Write-Progress)"
      "Variables peu descriptives" = '\$[a-z]{1,2}\b'
      "Commentaires insuffisants"  = "^(?!#).*Move-Item"
   }
}

$CriticalFiles = @{
   System   = @('.gitmodules', '.gitignore', '.git/', '.github/', '.vscode/', '.env*')
   Config   = @('package.json', 'go.mod', 'go.sum', 'Makefile', 'docker-compose.yml', 'Dockerfile')
   Security = @('*.key', '*.pem', '*.cert', '*.p12', 'secrets.*', 'credentials.*')
   Build    = @('*.sln', '*.csproj', '*.vcxproj', 'CMakeLists.txt', 'build.gradle', 'pom.xml')
}

function Test-ScriptSecurity {
   param([string]$Content, [string]$FilePath)
    
   $vulnerabilities = @()
   $score = 100
    
   Write-Host "🔍 Analyse de sécurité du script: $FilePath" -ForegroundColor Cyan
    
   # Analyse des patterns critiques
   foreach ($category in $SecurityPatterns.Keys) {
      Write-Host "  Vérification niveau $category..." -ForegroundColor Yellow
        
      foreach ($patternName in $SecurityPatterns[$category].Keys) {
         $pattern = $SecurityPatterns[$category][$patternName]
         $matches = [regex]::Matches($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)
            
         if ($matches.Count -gt 0) {
            $severity = switch ($category) {
               "Critical" { $score -= 30; "CRITIQUE" }
               "Major" { $score -= 15; "MAJEUR" }
               "Minor" { $score -= 5; "MINEUR" }
            }
                
            $vulnerability = @{
               Type       = $patternName
               Severity   = $severity
               Category   = $category
               Matches    = $matches.Count
               Lines      = @()
               Impact     = Get-VulnerabilityImpact -Type $patternName
               Mitigation = Get-MitigationStrategy -Type $patternName
            }
                
            # Identifier les lignes concernées
            $lines = $Content -split "`n"
            for ($i = 0; $i -lt $lines.Length; $i++) {
               if ([regex]::IsMatch($lines[$i], $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                  $vulnerability.Lines += @{
                     Number  = $i + 1
                     Content = $lines[$i].Trim()
                  }
               }
            }
                
            $vulnerabilities += $vulnerability
            Write-Host "    ⚠️  $patternName ($severity) - $($matches.Count) occurrence(s)" -ForegroundColor Red
         }
      }
   }
    
   return @{
      SecurityScore   = [math]::Max(0, $score)
      Vulnerabilities = $vulnerabilities
      Summary         = Get-SecuritySummary -Score $score -Vulnerabilities $vulnerabilities
   }
}

function Test-FileProtectionList {
   param([string]$Content)
    
   Write-Host "🛡️  Analyse de la liste de protection..." -ForegroundColor Cyan
    
   # Extraire la liste aPreserver
   $preservePattern = '\$aPreserver\s*=\s*@\((.*?)\)'
   $match = [regex]::Match($Content, $preservePattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
   if (-not $match.Success) {
      return @{
         Status          = "CRITIQUE"
         Issues          = @("Aucune liste de protection trouvée")
         MissingCritical = $CriticalFiles.System + $CriticalFiles.Config
         Coverage        = 0
      }
   }
    
   $preserveList = $match.Groups[1].Value -split "," | ForEach-Object { 
      $_.Trim().Trim("'").Trim('"') 
   } | Where-Object { $_ -ne "" }
    
   $missing = @()
   $coverage = 0
   $totalCritical = ($CriticalFiles.Values | ForEach-Object { $_ }).Count
    
   foreach ($category in $CriticalFiles.Keys) {
      foreach ($pattern in $CriticalFiles[$category]) {
         $found = $false
         foreach ($item in $preserveList) {
            if ($item -like $pattern -or $pattern -like "*$item*") {
               $found = $true
               $coverage++
               break
            }
         }
         if (-not $found) {
            $missing += @{
               Pattern  = $pattern
               Category = $category
               Risk     = Get-FileRisk -Pattern $pattern
            }
         }
      }
   }
    
   return @{
      Status          = if ($missing.Count -eq 0) { "SECURE" } 
      elseif ($missing.Count -lt 5) { "WARNING" } 
      else { "CRITIQUE" }
      PreserveList    = $preserveList
      Missing         = $missing
      Coverage        = [math]::Round(($coverage / $totalCritical) * 100, 2)
      Recommendations = Get-ProtectionRecommendations -Missing $missing
   }
}

function Get-VulnerabilityImpact {
   param([string]$Type)
    
   $impacts = @{
      "Move-Item sans validation"           = "Risque de déplacement de fichiers critiques système, corruption du projet"
      "Get-ChildItem récursif non contrôlé" = "Performance dégradée, accès non autorisé à des dossiers sensibles"
      "Remove-Item dangereux"               = "Suppression accidentelle de données critiques, perte irréversible"
      "Pas de validation d'entrée"          = "Injection de commandes, manipulation de chemins malveillants"
      "Chemins hardcodés"                   = "Portabilité réduite, erreurs sur différents environnements"
      "Pas de gestion d'erreur"             = "Échec silencieux, corruption partielle de données"
   }
    
   return $impacts[$Type] ?? "Impact non documenté"
}

function Get-MitigationStrategy {
   param([string]$Type)
    
   $strategies = @{
      "Move-Item sans validation"           = "Ajouter Test-Path, validation de destination, simulation préalable"
      "Get-ChildItem récursif non contrôlé" = "Limiter la profondeur, filtrer les dossiers système"
      "Remove-Item dangereux"               = "Ajouter -Confirm, sauvegarde préalable, validation utilisateur"
      "Pas de validation d'entrée"          = "Validation des paramètres, sanitisation des chemins"
      "Chemins hardcodés"                   = "Utiliser variables d'environnement, chemins relatifs"
      "Pas de gestion d'erreur"             = "Implémenter try-catch, logging des erreurs"
   }
    
   return $strategies[$Type] ?? "Stratégie à définir"
}

function Get-FileRisk {
   param([string]$Pattern)
    
   $risks = @{
      '.gitmodules'  = "CRITIQUE - Corruption des sous-modules Git"
      '.gitignore'   = "MAJEUR - Perte de configuration Git"
      '.env*'        = "CRITIQUE - Exposition de secrets/credentials"
      'package.json' = "CRITIQUE - Corruption des dépendances Node.js"
      'go.mod'       = "CRITIQUE - Corruption des dépendances Go"
      'Makefile'     = "MAJEUR - Perte des scripts de build"
   }
    
   return $risks[$Pattern] ?? "MINEUR - Impact fonctionnel limité"
}

function Get-ProtectionRecommendations {
   param([array]$Missing)
    
   $recommendations = @()
    
   foreach ($item in $Missing) {
      $recommendations += "Ajouter '$($item.Pattern)' à la liste de protection ($($item.Category))"
   }
    
   if ($Missing.Count -gt 0) {
      $recommendations += "Implémenter une whitelist basée sur les extensions critiques"
      $recommendations += "Ajouter validation contextuelle pour les fichiers métier"
      $recommendations += "Créer une configuration externe pour la liste de protection"
   }
    
   return $recommendations
}

function Get-SecuritySummary {
   param([int]$Score, [array]$Vulnerabilities)
    
   $criticalCount = ($Vulnerabilities | Where-Object { $_.Severity -eq "CRITIQUE" }).Count
   $majorCount = ($Vulnerabilities | Where-Object { $_.Severity -eq "MAJEUR" }).Count
   $minorCount = ($Vulnerabilities | Where-Object { $_.Severity -eq "MINEUR" }).Count
    
   $status = switch ($Score) {
      { $_ -ge 80 } { "ACCEPTABLE" }
      { $_ -ge 60 } { "ATTENTION" }
      { $_ -ge 40 } { "PROBLEMATIQUE" }
      default { "CRITIQUE" }
   }
    
   return @{
      SecurityStatus       = $status
      Score                = $Score
      TotalVulnerabilities = $Vulnerabilities.Count
      CriticalCount        = $criticalCount
      MajorCount           = $majorCount
      MinorCount           = $minorCount
      Recommendation       = if ($criticalCount -gt 0) { "REFACTORISATION IMMEDIATE REQUISE" } 
      elseif ($majorCount -gt 2) { "Corrections majeures nécessaires" }
      else { "Améliorations mineures suggérées" }
   }
}

function Get-OverallRisk {
   param([int]$SecurityScore, [string]$ProtectionStatus)
    
   if ($SecurityScore -lt 40 -or $ProtectionStatus -eq "CRITIQUE") {
      return "CRITIQUE - Risque immédiat de corruption du projet"
   }
   elseif ($SecurityScore -lt 60 -or $ProtectionStatus -eq "WARNING") {
      return "ÉLEVÉ - Corrections urgentes recommandées"
   }
   elseif ($SecurityScore -lt 80) {
      return "MODÉRÉ - Améliorations suggérées"
   }
   else {
      return "FAIBLE - Script acceptable avec surveillance"
   }
}

function Get-NextSteps {
   param($SecurityResults, $ProtectionResults)
    
   $steps = @()
    
   if ($SecurityResults.Summary.CriticalCount -gt 0) {
      $steps += "1. URGENT: Corriger les vulnérabilités critiques identifiées"
   }
    
   if ($ProtectionResults.Missing.Count -gt 0) {
      $steps += "2. Mettre à jour la liste de protection avec les fichiers critiques manquants"
   }
    
   if ($SecurityResults.Summary.MajorCount -gt 0) {
      $steps += "3. Implémenter les corrections pour les vulnérabilités majeures"
   }
    
   $steps += "4. Développer le script sécurisé organize-root-files-secure.ps1"
   $steps += "5. Implémenter le système de simulation et confirmation"
   $steps += "6. Ajouter logging détaillé et gestion d'erreur"
    
   return $steps
}

# Fonction principale
function Invoke-ScriptSecurityAudit {
   param([string]$ScriptPath, [string]$OutputPath)
    
   if (-not (Test-Path $ScriptPath)) {
      throw "Script non trouvé: $ScriptPath"
   }
    
   $content = Get-Content $ScriptPath -Raw
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
   Write-Host "🔒 AUDIT DE SÉCURITÉ - Plan Dev v41" -ForegroundColor Green
   Write-Host "Script analysé: $ScriptPath" -ForegroundColor Green
   Write-Host "Horodatage: $timestamp" -ForegroundColor Green
   Write-Host "=" * 60 -ForegroundColor Green
    
   # Analyse de sécurité générale
   $securityResults = Test-ScriptSecurity -Content $content -FilePath $ScriptPath
    
   # Analyse de la protection des fichiers
   $protectionResults = Test-FileProtectionList -Content $content
    
   # Compilation du rapport
   $report = @{
      AuditInfo        = @{
         Timestamp      = $timestamp
         ScriptPath     = $ScriptPath
         Analyzer       = "script-analyzer.ps1 v1.1"
         PlanDevVersion = "v41"
      }
      SecurityAnalysis = $securityResults
      FileProtection   = $protectionResults
      OverallRisk      = Get-OverallRisk -SecurityScore $securityResults.SecurityScore -ProtectionStatus $protectionResults.Status
      NextSteps        = Get-NextSteps -SecurityResults $securityResults -ProtectionResults $protectionResults
   }
    
   # Affichage du résumé
   Write-Host "`n📊 RÉSUMÉ DE L'AUDIT" -ForegroundColor Magenta
   Write-Host "Score de sécurité: $($securityResults.SecurityScore)/100 ($($securityResults.Summary.SecurityStatus))" -ForegroundColor $(if ($securityResults.SecurityScore -lt 60) { "Red" } else { "Yellow" })
   Write-Host "Protection des fichiers: $($protectionResults.Status) ($($protectionResults.Coverage)% de couverture)" -ForegroundColor $(if ($protectionResults.Status -eq "CRITIQUE") { "Red" } else { "Yellow" })
   Write-Host "Vulnérabilités trouvées: $($securityResults.Vulnerabilities.Count)" -ForegroundColor Red
   Write-Host "Fichiers critiques manquants: $($protectionResults.Missing.Count)" -ForegroundColor Red
    
   # Sauvegarde du rapport
   $report | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding UTF8
   Write-Host "`n💾 Rapport sauvegardé: $OutputPath" -ForegroundColor Green
    
   return $report
}

# Exécution de l'audit
try {
   $auditResult = Invoke-ScriptSecurityAudit -ScriptPath $ScriptPath -OutputPath $OutputPath
    
   if ($DetailedOutput) {
      Write-Host "`n🔍 DÉTAILS COMPLETS DE L'AUDIT" -ForegroundColor Cyan
      $auditResult | ConvertTo-Json -Depth 10
   }
    
   exit $(if ($auditResult.SecurityAnalysis.SecurityScore -lt 60) { 1 } else { 0 })
}
catch {
   Write-Error "Erreur lors de l'audit: $_"
   exit 2
}
