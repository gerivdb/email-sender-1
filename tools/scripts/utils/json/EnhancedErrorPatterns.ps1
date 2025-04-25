param (
    [Parameter(Mandatory=$false)]
    [string]$Path = (Get-Location).Path,

    [Parameter(Mandatory=$false)]
    [switch]$Recurse
)

# Script simplifié pour la détection des patterns d'erreur PowerShell

# Initialiser les patterns d'erreur
$ErrorPatterns = @{
    PowerShell = @(
        @{
            Pattern = 'Cannot find path ''(.+)'' because it does not exist'
            Description = 'Chemin introuvable'
            Category = 'FileSystem'
            Severity = 'Error'
            Suggestion = 'Vérifier si le chemin existe avec Test-Path avant utilisation'
        },
        @{
            Pattern = 'The term ''(.+)'' is not recognized as the name of a cmdlet'
            Description = 'Commande introuvable'
            Category = 'Command'
            Severity = 'Error'
            Suggestion = 'Vérifier l''orthographe ou installer le module nécessaire'
        },
        @{
            Pattern = 'Cannot bind argument to parameter ''(.+)'' because it is null'
            Description = 'Paramètre null'
            Category = 'Parameter'
            Severity = 'Error'
            Suggestion = 'Vérifier que la variable a une valeur avant utilisation'
        },
        @{
            Pattern = 'Cannot index into a null array'
            Description = 'Tableau null'
            Category = 'Array'
            Severity = 'Error'
            Suggestion = 'Vérifier l''initialisation du tableau avant accès'
        },
        @{
            Pattern = 'The property ''(.+)'' cannot be found on this object'
            Description = 'Propriété introuvable'
            Category = 'Object'
            Severity = 'Error'
            Suggestion = 'Vérifier que l''objet possède cette propriété'
        },
        @{
            Pattern = 'You cannot call a method on a null-valued expression'
            Description = 'Méthode sur null'
            Category = 'NullReference'
            Severity = 'Error'
            Suggestion = 'Vérifier que l''objet n''est pas null avant appel de méthode'
        },
        @{
            Pattern = '\[void\]\s*='
            Description = 'Affectation void incorrecte'
            Category = 'Syntax'
            Severity = 'Error'
            Suggestion = 'Remplacer par [void] sans signe égal'
        },
        @{
            Pattern = 'return\s*\(.+\)'
            Description = 'Return avec parenthèses inutiles'
            Category = 'Syntax'
            Severity = 'Warning'
            Suggestion = 'Supprimer les parenthèses après return'
        },
        @{
            Pattern = 'Write-Output\s+.+\s*\|'
            Description = 'Write-Output inutile dans un pipeline'
            Category = 'Performance'
            Severity = 'Warning'
            Suggestion = 'Supprimer Write-Output inutile'
        },
        @{
            Pattern = '\$error\s*='
            Description = 'Assignation à variable automatique'
            Category = 'Syntax'
            Severity = 'Error'
            Suggestion = 'Utiliser un nom différent de variable ($error est en lecture seule)'
        },
        @{
            Pattern = '\$(foreach|true|false|null|args|input|this)\s*='
            Description = 'Assignation à variable réservée'
            Category = 'Syntax'
            Severity = 'Error'
            Suggestion = 'Choisir un nom de variable différent ($1 est réservé)'
        },
        @{
            Pattern = 'throw\s+[''"][^''"]*[''"]\s*$'
            Description = 'Throw avec message littéral'
            Category = 'ErrorHandling'
            Severity = 'Warning'
            Suggestion = 'Privilégier les exceptions spécifiques avec [System.Exception]'
        }
    )
}

function Find-ErrorPatterns {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$false)]
        [string[]]$Categories = @()
    )

    if (-not (Test-Path $FilePath)) {
        Write-Error "Fichier introuvable: $FilePath"
        return
    }

    $content = Get-Content $FilePath -Raw
    $results = @()

    foreach ($pattern in $ErrorPatterns.PowerShell) {
        if ($Categories.Count -gt 0 -and $Categories -notcontains $pattern.Category) {
            continue
        }

        # Vérifier que le pattern et le contenu sont valides avant de rechercher les correspondances
        if ([string]::IsNullOrEmpty($content) -or [string]::IsNullOrEmpty($pattern.Pattern)) {
            Write-Verbose "Contenu ou pattern vide pour le fichier: $FilePath"
            continue
        }

        try {
            $patternMatches = [regex]::Matches($content, $pattern.Pattern)
        } catch {
            Write-Warning "Erreur lors de l'application du pattern '$($pattern.Pattern)': $_"
            continue
        }
        foreach ($match in $patternMatches) {
            $lineNumber = ($content.Substring(0, $match.Index).Split("`n")).Count
            $line = ($content.Split("`n")[$lineNumber - 1]).Trim()

            $results += [PSCustomObject]@{
                FilePath = $FilePath
                LineNumber = $lineNumber
                Line = $line
                Pattern = $pattern.Pattern
                Description = $pattern.Description
                Category = $pattern.Category
                Severity = $pattern.Severity
                Suggestion = $pattern.Suggestion
                Match = $match.Value
            }
        }
    }

    return $results
}

function Find-ErrorPatternsInDirectory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [string]$Filter = "*.ps1",

        [Parameter(Mandatory=$false)]
        [switch]$Recurse,

        [Parameter(Mandatory=$false)]
        [string[]]$Categories = @()
    )

    Write-Verbose "Analyse du répertoire: $Path (Récursif: $Recurse)"
    $files = Get-ChildItem -Path $Path -Filter $Filter -File -Recurse:$Recurse

    if (-not $files) {
        Write-Warning "Aucun fichier trouvé dans $Path avec le filtre $Filter"
        return $null
    }

    Write-Verbose "Fichiers trouvés:"
    $files | ForEach-Object { Write-Verbose "- $_" }

    $results = @()
    foreach ($file in $files) {
        Write-Verbose "Analyse du fichier: $($file.FullName)"
        $results += Find-ErrorPatterns -FilePath $file.FullName -Categories $Categories
    }

    return $results
}

# Run analysis when script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    try {
        $results = Find-ErrorPatternsInDirectory -Path $Path -Recurse:$Recurse
        if ($results) {
            $results | Format-Table -Property FilePath,LineNumber,Description,Category,Severity,Suggestion -AutoSize
        } else {
            Write-Host "Aucune erreur détectée dans les fichiers analysés." -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Erreur lors de l'analyse: $_"
    }
}
