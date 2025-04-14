<#
.SYNOPSIS
    Analyse les pull requests GitHub pour détecter les erreurs potentielles.
.DESCRIPTION
    Ce script analyse les pull requests GitHub pour détecter les erreurs potentielles
    dans les fichiers PowerShell modifiés. Il utilise le module ErrorPatternAnalyzer
    pour l'analyse et génère un rapport détaillé.
.PARAMETER Action
    Action à effectuer : List, Analyze, Comment.
.PARAMETER PullRequestNumber
    Numéro de la pull request à analyser.
.PARAMETER State
    État des pull requests à lister : Open, Closed, All.
.EXAMPLE
    .\Analyze-PullRequest.ps1 -Action List -State Open
.EXAMPLE
    .\Analyze-PullRequest.ps1 -Action Analyze -PullRequestNumber 123
.EXAMPLE
    .\Analyze-PullRequest.ps1 -Action Comment -PullRequestNumber 123
.NOTES
    Auteur: Augment Code
    Date: 14/04/2025
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("List", "Analyze", "Comment")]
    [string]$Action,
    
    [Parameter()]
    [int]$PullRequestNumber,
    
    [Parameter()]
    [ValidateSet("Open", "Closed", "All")]
    [string]$State = "Open"
)

# Vérifier si Python est installé
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python n'est pas installé ou n'est pas dans le PATH."
    exit 1
}

# Vérifier si le script Python existe
$scriptPath = Join-Path -Path (git rev-parse --show-toplevel) -ChildPath "scripts\journal\web\pr_integration.py"
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Script Python non trouvé: $scriptPath"
    exit 1
}

# Vérifier les paramètres
if ($Action -in @("Analyze", "Comment") -and -not $PullRequestNumber) {
    Write-Error "Le paramètre PullRequestNumber est requis pour l'action $Action."
    exit 1
}

# Construire la commande Python
$pythonArgs = @($scriptPath, $Action.ToLower())

if ($PullRequestNumber) {
    $pythonArgs += "--pr", $PullRequestNumber
}

if ($State) {
    $pythonArgs += "--state", $State.ToLower()
}

# Exécuter la commande Python
try {
    if ($PSCmdlet.ShouldProcess("Pull request $PullRequestNumber", "Exécuter l'action $Action")) {
        $result = & python $pythonArgs
        $result | ForEach-Object { Write-Host $_ }
    }
} catch {
    Write-Error "Erreur lors de l'exécution du script Python: $_"
    exit 1
}

# Vérifier le code de sortie
if ($LASTEXITCODE -ne 0) {
    Write-Error "Le script Python a retourné un code d'erreur: $LASTEXITCODE"
    exit $LASTEXITCODE
}
