<#
.SYNOPSIS
    Fonctions pour la tokenization de fichiers markdown.

.DESCRIPTION
    Ce module contient des fonctions pour tokenizer et analyser des fichiers markdown,
    avec une attention particulière pour les roadmaps et les listes de tâches.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-08-18
#>

#region Types de tokens et énumérations

<#
.SYNOPSIS
    Énumération des types de tokens markdown.

.DESCRIPTION
    Cette énumération définit les différents types de tokens qui peuvent être
    reconnus dans un document markdown.
#>
enum MarkdownTokenType {
    # Éléments de structure
    Header              # Titre (# Titre)
    Paragraph           # Paragraphe de texte
    BlankLine           # Ligne vide
    HorizontalRule      # Ligne horizontale (---, ***, ___)

    # Listes et tâches
    UnorderedListItem   # Élément de liste non ordonnée (-, *, +)
    OrderedListItem     # Élément de liste ordonnée (1., 2., etc.)
    TaskItem            # Élément de tâche (- [ ] Tâche)

    # Formatage de texte
    Bold                # Texte en gras (**texte** ou __texte__)
    Italic              # Texte en italique (*texte* ou _texte_)
    Code                # Code inline (`code`)
    CodeBlock           # Bloc de code (```code```)

    # Liens et références
    Link                # Lien ([texte](url))
    Image               # Image (![alt](url))
    Reference           # Référence ([texte][ref])

    # Éléments spécifiques aux roadmaps
    TaskId              # Identifiant de tâche (1.2.3, **1.2.3**, etc.)
    TaskStatus          # Statut de tâche ([ ], [x], etc.)
    TaskAssignment      # Assignation de tâche (@personne)
    TaskTag             # Tag de tâche (#tag)
    TaskPriority        # Priorité de tâche (!priorité)
    TaskDate            # Date de tâche (date:2023-08-18)

    # Autres
    Comment             # Commentaire (<!-- commentaire -->)
    Quote               # Citation (> citation)
    Table               # Tableau (| col1 | col2 |)
    FrontMatter         # Frontmatter (---)
    Unknown             # Type inconnu
}

<#
.SYNOPSIS
    Classe représentant un token markdown.

.DESCRIPTION
    Cette classe définit la structure d'un token markdown, avec son type,
    sa valeur, sa position dans le document, et d'autres propriétés utiles.
#>
class MarkdownToken {
    [MarkdownTokenType]$Type        # Type de token
    [string]$Value                  # Valeur textuelle du token
    [int]$LineNumber                # Numéro de ligne dans le document
    [int]$StartPosition             # Position de début dans la ligne
    [int]$EndPosition               # Position de fin dans la ligne
    [int]$IndentationLevel          # Niveau d'indentation
    [MarkdownToken[]]$Children      # Tokens enfants (pour les tokens imbriqués)
    [hashtable]$Metadata            # Métadonnées supplémentaires

    # Constructeur par défaut
    MarkdownToken() {
        $this.Type = [MarkdownTokenType]::Unknown
        $this.Value = ""
        $this.LineNumber = 0
        $this.StartPosition = 0
        $this.EndPosition = 0
        $this.IndentationLevel = 0
        $this.Children = @()
        $this.Metadata = @{}
    }

    # Constructeur avec paramètres de base
    MarkdownToken([MarkdownTokenType]$type, [string]$value, [int]$lineNumber, [int]$startPosition, [int]$endPosition) {
        $this.Type = $type
        $this.Value = $value
        $this.LineNumber = $lineNumber
        $this.StartPosition = $startPosition
        $this.EndPosition = $endPosition
        $this.IndentationLevel = 0
        $this.Children = @()
        $this.Metadata = @{}
    }

    # Constructeur complet
    MarkdownToken([MarkdownTokenType]$type, [string]$value, [int]$lineNumber, [int]$startPosition, [int]$endPosition, [int]$indentationLevel) {
        $this.Type = $type
        $this.Value = $value
        $this.LineNumber = $lineNumber
        $this.StartPosition = $startPosition
        $this.EndPosition = $endPosition
        $this.IndentationLevel = $indentationLevel
        $this.Children = @()
        $this.Metadata = @{}
    }

    # Méthode pour ajouter un token enfant
    [void] AddChild([MarkdownToken]$child) {
        $this.Children += $child
    }

    # Méthode pour ajouter une métadonnée
    [void] AddMetadata([string]$key, [object]$value) {
        $this.Metadata[$key] = $value
    }

    # Méthode pour obtenir une représentation textuelle du token
    [string] ToString() {
        return "[$($this.Type)] Line $($this.LineNumber): $($this.Value)"
    }
}

#endregion

#region Fonctions de tokenization

<#
.SYNOPSIS
    Tokenize une chaîne de texte markdown.

.DESCRIPTION
    Cette fonction analyse une chaîne de texte markdown et la convertit en une liste de tokens.

.PARAMETER MarkdownText
    Chaîne de texte markdown à analyser.

.EXAMPLE
    $tokens = ConvertFrom-MarkdownToTokens -MarkdownText "# Titre`n`nParagraphe"

.OUTPUTS
    MarkdownToken[]
#>
function ConvertFrom-MarkdownToTokens {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$MarkdownText = ""
    )

    try {
        # Vérifier si le texte est null ou vide
        if ($null -eq $MarkdownText -or [string]::IsNullOrEmpty($MarkdownText)) {
            return @()
        }

        # Diviser le texte en lignes
        $lines = $MarkdownText -split "`n"

        # Initialiser la liste des tokens
        $tokens = @()

        # Traiter chaque ligne
        for ($lineNumber = 0; $lineNumber -lt $lines.Count; $lineNumber++) {
            $line = $lines[$lineNumber]

            # Tokenizer la ligne
            $lineTokens = Get-MarkdownLineTokens -Line $line -LineNumber ($lineNumber + 1)

            # Ajouter les tokens de la ligne à la liste globale
            $tokens += $lineTokens
        }

        # Construire l'arbre des tokens (gestion des imbrications)
        $tokenTree = Build-MarkdownTokenTree -Tokens $tokens

        return $tokenTree
    } catch {
        Write-Error "Erreur lors de la tokenization du markdown: $_"
        return @()
    }
}

<#
.SYNOPSIS
    Tokenize un fichier markdown.

.DESCRIPTION
    Cette fonction lit un fichier markdown et le convertit en une liste de tokens.

.PARAMETER FilePath
    Chemin vers le fichier markdown à analyser.

.EXAMPLE
    $tokens = ConvertFrom-MarkdownFileToTokens -FilePath "roadmap.md"

.OUTPUTS
    MarkdownToken[]
#>
function ConvertFrom-MarkdownFileToTokens {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas ou n'est pas un fichier."
            return @()
        }

        # Lire le contenu du fichier
        $markdownContent = Get-MarkdownContent -FilePath $FilePath

        if ($null -eq $markdownContent) {
            Write-Error "Impossible de lire le contenu du fichier '$FilePath'."
            return @()
        }

        # Convertir le contenu en tokens
        $tokens = ConvertFrom-MarkdownToTokens -MarkdownText ($markdownContent.Lines -join "`n")

        return $tokens
    } catch {
        Write-Error "Erreur lors de la tokenization du fichier markdown: $_"
        return @()
    }
}

<#
.SYNOPSIS
    Tokenize une ligne de texte markdown.

.DESCRIPTION
    Cette fonction analyse une ligne de texte markdown et la convertit en une liste de tokens.

.PARAMETER Line
    Ligne de texte markdown à analyser.

.PARAMETER LineNumber
    Numéro de la ligne dans le document.

.EXAMPLE
    $lineTokens = Get-MarkdownLineTokens -Line "# Titre" -LineNumber 1

.OUTPUTS
    MarkdownToken[]
#>
function Get-MarkdownLineTokens {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Line,

        [Parameter(Mandatory = $true)]
        [int]$LineNumber
    )

    try {
        # Initialiser la liste des tokens
        $tokens = @()

        # Vérifier si la ligne est null
        if ($null -eq $Line) {
            $Line = ""
        }

        # Calculer le niveau d'indentation
        $indentationLevel = Get-IndentationLevel -Line $Line

        # Ligne vide
        if ([string]::IsNullOrWhiteSpace($Line)) {
            $token = [MarkdownToken]::new([MarkdownTokenType]::BlankLine, "", $LineNumber, 0, 0, $indentationLevel)
            $tokens += $token
            return $tokens
        }

        # Ligne horizontale
        if ($Line -match '^\s*(---|\*\*\*|___)\s*$') {
            $token = [MarkdownToken]::new([MarkdownTokenType]::HorizontalRule, $Line.Trim(), $LineNumber, 0, $Line.Length, $indentationLevel)
            $tokens += $token
            return $tokens
        }

        # Titre
        if ($Line -match '^\s*(#{1,6})\s+(.+)$') {
            $level = $matches[1].Length
            $title = $matches[2].Trim()
            $token = [MarkdownToken]::new([MarkdownTokenType]::Header, $title, $LineNumber, 0, $Line.Length, $indentationLevel)
            $token.AddMetadata("Level", $level)
            $tokens += $token
            return $tokens
        }

        # Élément de liste non ordonnée
        if ($Line -match '^\s*(-|\*|\+)\s+(.+)$') {
            $marker = $matches[1]
            $content = $matches[2].Trim()

            # Vérifier s'il s'agit d'une tâche
            if ($content -match '^\[([ xX])\]\s+(.+)$') {
                $status = $matches[1]
                $taskContent = $matches[2].Trim()

                $token = [MarkdownToken]::new([MarkdownTokenType]::TaskItem, $taskContent, $LineNumber, 0, $Line.Length, $indentationLevel)
                $token.AddMetadata("Status", $status)
                $token.AddMetadata("Marker", $marker)

                # Extraire l'identifiant de tâche s'il existe
                if ($taskContent -match '^(\*\*[0-9.]+\*\*|\([0-9.]+\)|[0-9.]+)\s+(.+)$') {
                    $taskId = $matches[1].Trim('*', '(', ')')
                    $taskDescription = $matches[2].Trim()

                    $token.Value = $taskDescription
                    $token.AddMetadata("TaskId", $taskId)

                    # Ajouter un token spécifique pour l'identifiant
                    $idToken = [MarkdownToken]::new([MarkdownTokenType]::TaskId, $taskId, $LineNumber, 0, $matches[1].Length, $indentationLevel)
                    $token.AddChild($idToken)
                }

                # Extraire les assignations (@personne)
                if ($taskContent -match '@([a-zA-Z0-9_-]+)') {
                    $assignments = @()
                    foreach ($match in [regex]::Matches($taskContent, '@([a-zA-Z0-9_-]+)')) {
                        $assignment = $match.Groups[1].Value
                        $assignments += $assignment

                        # Ajouter un token spécifique pour l'assignation
                        $assignmentToken = [MarkdownToken]::new([MarkdownTokenType]::TaskAssignment, $assignment, $LineNumber, $match.Index, $match.Index + $match.Length, $indentationLevel)
                        $token.AddChild($assignmentToken)
                    }

                    $token.AddMetadata("Assignments", $assignments)
                }

                # Extraire les tags (#tag)
                if ($taskContent -match '#([a-zA-Z0-9_-]+)') {
                    $tags = @()
                    foreach ($match in [regex]::Matches($taskContent, '#([a-zA-Z0-9_-]+)')) {
                        $tag = $match.Groups[1].Value
                        $tags += $tag

                        # Ajouter un token spécifique pour le tag
                        $tagToken = [MarkdownToken]::new([MarkdownTokenType]::TaskTag, $tag, $LineNumber, $match.Index, $match.Index + $match.Length, $indentationLevel)
                        $token.AddChild($tagToken)
                    }

                    $token.AddMetadata("Tags", $tags)
                }

                $tokens += $token
            } else {
                # Liste non ordonnée standard
                $token = [MarkdownToken]::new([MarkdownTokenType]::UnorderedListItem, $content, $LineNumber, 0, $Line.Length, $indentationLevel)
                $token.AddMetadata("Marker", $marker)
                $tokens += $token
            }

            return $tokens
        }

        # Élément de liste ordonnée
        if ($Line -match '^\s*([0-9]+\.)\s+(.+)$') {
            $marker = $matches[1]
            $content = $matches[2].Trim()
            $token = [MarkdownToken]::new([MarkdownTokenType]::OrderedListItem, $content, $LineNumber, 0, $Line.Length, $indentationLevel)
            $token.AddMetadata("Marker", $marker)
            $token.AddMetadata("Number", [int]($marker.TrimEnd('.')))
            $tokens += $token
            return $tokens
        }

        # Citation
        if ($Line -match '^\s*>\s+(.+)$') {
            $content = $matches[1].Trim()
            $token = [MarkdownToken]::new([MarkdownTokenType]::Quote, $content, $LineNumber, 0, $Line.Length, $indentationLevel)
            $tokens += $token
            return $tokens
        }

        # Bloc de code
        if ($Line -match '^\s*```(.*)$') {
            $language = $matches[1].Trim()
            $token = [MarkdownToken]::new([MarkdownTokenType]::CodeBlock, $language, $LineNumber, 0, $Line.Length, $indentationLevel)
            $token.AddMetadata("Language", $language)
            $tokens += $token
            return $tokens
        }

        # Tableau
        if ($Line -match '^\s*\|(.+)\|\s*$') {
            $content = $matches[1].Trim()
            $token = [MarkdownToken]::new([MarkdownTokenType]::Table, $content, $LineNumber, 0, $Line.Length, $indentationLevel)

            # Extraire les cellules du tableau
            $cells = @()
            foreach ($cell in $content -split '\|') {
                $cells += $cell.Trim()
            }

            $token.AddMetadata("Cells", $cells)
            $tokens += $token
            return $tokens
        }

        # Frontmatter
        if ($Line -match '^\s*---\s*$') {
            $token = [MarkdownToken]::new([MarkdownTokenType]::FrontMatter, "---", $LineNumber, 0, $Line.Length, $indentationLevel)
            $tokens += $token
            return $tokens
        }

        # Commentaire
        if ($Line -match '^\s*<!--(.+)-->\s*$') {
            $content = $matches[1].Trim()
            $token = [MarkdownToken]::new([MarkdownTokenType]::Comment, $content, $LineNumber, 0, $Line.Length, $indentationLevel)
            $tokens += $token
            return $tokens
        }

        # Si aucun des patterns précédents ne correspond, considérer comme un paragraphe
        $token = [MarkdownToken]::new([MarkdownTokenType]::Paragraph, $Line.Trim(), $LineNumber, 0, $Line.Length, $indentationLevel)
        $tokens += $token

        return $tokens
    } catch {
        Write-Error "Erreur lors de la tokenization de la ligne: $_"
        return @()
    }
}

<#
.SYNOPSIS
    Calcule le niveau d'indentation d'une ligne.

.DESCRIPTION
    Cette fonction calcule le niveau d'indentation d'une ligne en comptant
    les espaces et les tabulations au début de la ligne.

.PARAMETER Line
    Ligne de texte à analyser.

.EXAMPLE
    $indentationLevel = Get-IndentationLevel -Line "    - Item"

.OUTPUTS
    System.Int32
#>
function Get-IndentationLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$Line = ""
    )

    try {
        # Si la ligne est null ou vide, retourner 0
        if ($null -eq $Line -or [string]::IsNullOrWhiteSpace($Line)) {
            return 0
        }

        # Compter les espaces et les tabulations au début de la ligne
        $match = [regex]::Match($Line, '^\s+')

        if ($match.Success) {
            $indentation = $match.Value

            # Remplacer les tabulations par des espaces (1 tabulation = 4 espaces)
            $indentation = $indentation -replace "`t", "    "

            # Calculer le niveau d'indentation (1 niveau = 2 espaces)
            $level = [math]::Floor($indentation.Length / 2)

            return $level
        }

        return 0
    } catch {
        Write-Error "Erreur lors du calcul du niveau d'indentation: $_"
        return 0
    }
}

<#
.SYNOPSIS
    Construit l'arbre des tokens markdown.

.DESCRIPTION
    Cette fonction construit l'arbre des tokens markdown en gérant les imbrications
    basées sur les niveaux d'indentation.

.PARAMETER Tokens
    Liste des tokens à organiser en arbre.

.EXAMPLE
    $tokenTree = Build-MarkdownTokenTree -Tokens $tokens

.OUTPUTS
    MarkdownToken[]
#>
function Build-MarkdownTokenTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [MarkdownToken[]]$Tokens = @()
    )

    try {
        # Si la liste des tokens est null ou vide, retourner une liste vide
        if ($null -eq $Tokens -or $Tokens.Count -eq 0) {
            return @()
        }

        # Initialiser la liste des tokens racines
        $rootTokens = @()

        # Initialiser la pile des tokens parents
        $parentStack = New-Object System.Collections.Stack

        # Parcourir tous les tokens
        for ($i = 0; $i -lt $Tokens.Count; $i++) {
            $token = $Tokens[$i]

            # Si la pile est vide, ajouter le token à la liste des racines
            if ($parentStack.Count -eq 0) {
                $rootTokens += $token
                $parentStack.Push($token)
                continue
            }

            # Récupérer le token parent actuel
            $parent = $parentStack.Peek()

            # Si le token courant a un niveau d'indentation supérieur au parent,
            # l'ajouter comme enfant du parent
            if ($token.IndentationLevel -gt $parent.IndentationLevel) {
                $parent.AddChild($token)
                $parentStack.Push($token)
            }
            # Si le token courant a le même niveau d'indentation que le parent,
            # remonter d'un niveau dans la pile et ajouter le token comme frère du parent
            elseif ($token.IndentationLevel -eq $parent.IndentationLevel) {
                $parentStack.Pop() | Out-Null

                # Si la pile est vide, ajouter le token à la liste des racines
                if ($parentStack.Count -eq 0) {
                    $rootTokens += $token
                } else {
                    # Sinon, l'ajouter comme enfant du nouveau parent
                    $newParent = $parentStack.Peek()
                    $newParent.AddChild($token)
                }

                $parentStack.Push($token)
            }
            # Si le token courant a un niveau d'indentation inférieur au parent,
            # remonter dans la pile jusqu'à trouver un parent de niveau inférieur ou égal
            else {
                while ($parentStack.Count -gt 0 -and $token.IndentationLevel -lt $parentStack.Peek().IndentationLevel) {
                    $parentStack.Pop() | Out-Null
                }

                # Si la pile est vide, ajouter le token à la liste des racines
                if ($parentStack.Count -eq 0) {
                    $rootTokens += $token
                } else {
                    # Sinon, vérifier si le nouveau parent a le même niveau d'indentation
                    $newParent = $parentStack.Peek()

                    if ($token.IndentationLevel -eq $newParent.IndentationLevel) {
                        $parentStack.Pop() | Out-Null

                        # Si la pile est vide, ajouter le token à la liste des racines
                        if ($parentStack.Count -eq 0) {
                            $rootTokens += $token
                        } else {
                            # Sinon, l'ajouter comme enfant du nouveau parent
                            $newParent = $parentStack.Peek()
                            $newParent.AddChild($token)
                        }
                    } else {
                        # Sinon, l'ajouter comme enfant du nouveau parent
                        $newParent.AddChild($token)
                    }
                }

                $parentStack.Push($token)
            }
        }

        return $rootTokens
    } catch {
        Write-Error "Erreur lors de la construction de l'arbre des tokens: $_"
        return $Tokens
    }
}

<#
.SYNOPSIS
    Valide un arbre de tokens markdown.

.DESCRIPTION
    Cette fonction valide un arbre de tokens markdown en vérifiant la cohérence
    des imbrications et des relations parent-enfant.

.PARAMETER Tokens
    Arbre de tokens à valider.

.EXAMPLE
    $validationResult = Test-MarkdownTokenTree -Tokens $tokenTree

.OUTPUTS
    PSCustomObject
#>
function Test-MarkdownTokenTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [MarkdownToken[]]$Tokens = @()
    )

    try {
        # Initialiser le résultat de validation
        $validationResult = [PSCustomObject]@{
            IsValid  = $true
            Errors   = @()
            Warnings = @()
        }

        # Si la liste des tokens est null ou vide, retourner un résultat valide
        if ($null -eq $Tokens -or $Tokens.Count -eq 0) {
            return $validationResult
        }

        # Fonction récursive pour valider un token et ses enfants
        function Test-Token {
            param(
                [MarkdownToken]$Token,
                [ref]$ValidationResult
            )

            # Vérifier si le token est valide
            if ($null -eq $Token) {
                $ValidationResult.Value.IsValid = $false
                $ValidationResult.Value.Errors += "Token null détecté."
                return
            }

            # Vérifier si le type de token est valide
            if ($Token.Type -eq [MarkdownTokenType]::Unknown) {
                $ValidationResult.Value.Warnings += "Token de type inconnu à la ligne $($Token.LineNumber): $($Token.Value)"
            }

            # Vérifier la cohérence des enfants
            foreach ($child in $Token.Children) {
                # Vérifier si le niveau d'indentation de l'enfant est supérieur à celui du parent
                if ($child.IndentationLevel -le $Token.IndentationLevel) {
                    $ValidationResult.Value.Warnings += "Niveau d'indentation incohérent: l'enfant à la ligne $($child.LineNumber) a un niveau d'indentation inférieur ou égal à son parent à la ligne $($Token.LineNumber)."
                }

                # Valider récursivement l'enfant
                Test-Token -Token $child -ValidationResult $ValidationResult
            }
        }

        # Valider chaque token racine
        foreach ($token in $Tokens) {
            Test-Token -Token $token -ValidationResult ([ref]$validationResult)
        }

        return $validationResult
    } catch {
        Write-Error "Erreur lors de la validation de l'arbre des tokens: $_"
        return [PSCustomObject]@{
            IsValid  = $false
            Errors   = @("Erreur lors de la validation: $_")
            Warnings = @()
        }
    }
}

#endregion

# Exporter les fonctions
Export-ModuleMember -Function ConvertFrom-MarkdownToTokens, ConvertFrom-MarkdownFileToTokens, Get-MarkdownLineTokens, Get-IndentationLevel, Build-MarkdownTokenTree, Test-MarkdownTokenTree
