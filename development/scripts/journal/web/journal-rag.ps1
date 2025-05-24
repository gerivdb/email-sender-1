# Script PowerShell pour le systÃƒÂ¨me RAG du journal de bord

param (
    [Parameter(Position=0)]
    [string]$Command,

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ScriptsDir = "scripts\python\journal"

function Show-Help {
    Write-Host "Utilisation du systÃƒÂ¨me RAG pour le journal de bord"
    Write-Host ""
    Write-Host "Commandes disponibles:"
    Write-Host "  setup       - Configure le systÃƒÂ¨me RAG"
    Write-Host "  new         - CrÃƒÂ©e une nouvelle entrÃƒÂ©e dans le journal"
    Write-Host "  search      - Recherche dans le journal"
    Write-Host "  query       - Interroge le systÃƒÂ¨me RAG"
    Write-Host "  rebuild     - Reconstruit les index"
    Write-Host "  help        - Affiche cette aide"
    Write-Host ""
    Write-Host "Exemples:"
    Write-Host "  .\development\scripts\cmd\journal-rag.ps1 setup"
    Write-Host "  .\development\scripts\cmd\journal-rag.ps1 new"
    Write-Host "  .\development\scripts\cmd\journal-rag.ps1 search"
    Write-Host "  .\development\scripts\cmd\journal-rag.ps1 query 'problÃƒÂ¨mes d''encodage'"
    Write-Host "  .\development\scripts\cmd\journal-rag.ps1 rebuild"
}

function Initialize-System {
    Write-Host "Configuration du systÃƒÂ¨me RAG..."
    python "$ScriptsDir\setup.py" $Arguments
}

function New-Entry {
    Write-Host "CrÃƒÂ©ation d'une nouvelle entrÃƒÂ©e..."
    python "$ScriptsDir\journal_vscode.py" new
}

function Search-Journal {
    Write-Host "Recherche dans le journal..."
    python "$ScriptsDir\journal_vscode.py" search
}

function Get-RAG {
    if ($Arguments.Count -eq 0) {
        Write-Host "Erreur: RequÃƒÂªte manquante"
        Write-Host "Exemple: .\development\scripts\cmd\journal-rag.ps1 query 'problÃƒÂ¨mes d''encodage'"
        return
    }

    $Query = $Arguments -join " "
    Write-Host "Interrogation du systÃƒÂ¨me RAG: '$Query'..."
    python "$ScriptsDir\journal_rag_simple.py" --query $Query
}

function Update-Indexes {
    Write-Host "Reconstruction des index..."
    python "$ScriptsDir\journal_search_simple.py" --rebuild
    python "$ScriptsDir\journal_rag_simple.py" --rebuild --export
}

# ExÃƒÂ©cution de la commande
switch ($Command) {
    "setup" { Initialize-System }
    "new" { New-Entry }
    "search" { Search-Journal }
    "query" { Get-RAG }
    "rebuild" { Update-Indexes }
    "help" { Show-Help }
    default { Show-Help }
}


