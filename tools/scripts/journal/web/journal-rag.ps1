# Script PowerShell pour le systÃ¨me RAG du journal de bord

param (
    [Parameter(Position=0)]
    [string]$Command,

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ScriptsDir = "scripts\python\journal"

function Show-Help {
    Write-Host "Utilisation du systÃ¨me RAG pour le journal de bord"
    Write-Host ""
    Write-Host "Commandes disponibles:"
    Write-Host "  setup       - Configure le systÃ¨me RAG"
    Write-Host "  new         - CrÃ©e une nouvelle entrÃ©e dans le journal"
    Write-Host "  search      - Recherche dans le journal"
    Write-Host "  query       - Interroge le systÃ¨me RAG"
    Write-Host "  rebuild     - Reconstruit les index"
    Write-Host "  help        - Affiche cette aide"
    Write-Host ""
    Write-Host "Exemples:"
    Write-Host "  .\scripts\cmd\journal-rag.ps1 setup"
    Write-Host "  .\scripts\cmd\journal-rag.ps1 new"
    Write-Host "  .\scripts\cmd\journal-rag.ps1 search"
    Write-Host "  .\scripts\cmd\journal-rag.ps1 query 'problÃ¨mes d''encodage'"
    Write-Host "  .\scripts\cmd\journal-rag.ps1 rebuild"
}

function Setup-System {
    Write-Host "Configuration du systÃ¨me RAG..."
    python "$ScriptsDir\setup.py" $Arguments
}

function New-Entry {
    Write-Host "CrÃ©ation d'une nouvelle entrÃ©e..."
    python "$ScriptsDir\journal_vscode.py" new
}

function Search-Journal {
    Write-Host "Recherche dans le journal..."
    python "$ScriptsDir\journal_vscode.py" search
}

function Query-RAG {
    if ($Arguments.Count -eq 0) {
        Write-Host "Erreur: RequÃªte manquante"
        Write-Host "Exemple: .\scripts\cmd\journal-rag.ps1 query 'problÃ¨mes d''encodage'"
        return
    }

    $Query = $Arguments -join " "
    Write-Host "Interrogation du systÃ¨me RAG: '$Query'..."
    python "$ScriptsDir\journal_rag_simple.py" --query $Query
}

function Rebuild-Indexes {
    Write-Host "Reconstruction des index..."
    python "$ScriptsDir\journal_search_simple.py" --rebuild
    python "$ScriptsDir\journal_rag_simple.py" --rebuild --export
}

# ExÃ©cution de la commande
switch ($Command) {
    "setup" { Setup-System }
    "new" { New-Entry }
    "search" { Search-Journal }
    "query" { Query-RAG }
    "rebuild" { Rebuild-Indexes }
    "help" { Show-Help }
    default { Show-Help }
}
