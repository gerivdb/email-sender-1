<#
.SYNOPSIS
    Fonctions pour la tokenization de fichiers markdown.

.DESCRIPTION
    Ce module contient des fonctions pour tokenizer et analyser des fichiers markdown,
    avec une attention particuliÃ¨re pour les roadmaps et les listes de tÃ¢ches.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-08-18
#>

#region Types de tokens et Ã©numÃ©rations

<#
.SYNOPSIS
    Ã‰numÃ©ration des types de tokens markdown.

.DESCRIPTION
    Cette Ã©numÃ©ration dÃ©finit les diffÃ©rents types de tokens qui peuvent Ãªtre
    reconnus dans un document markdown.
#>
enum MarkdownTokenType {
    # Ã‰lÃ©ments de structure
    Header              # Titre (# Titre)
    Paragraph           # Paragraphe de texte
    BlankLine           # Ligne vide
    HorizontalRule      # Ligne horizontale (---, ***, ___)

    # Listes et tÃ¢ches
    UnorderedListItem   # Ã‰lÃ©ment de liste non ordonnÃ©e (-, *, +)
    OrderedListItem     # Ã‰lÃ©ment de liste ordonnÃ©e (1., 2., etc.)
    TaskItem            # Ã‰lÃ©ment de tÃ¢che (- [ ] TÃ¢che)

    # Formatage de texte
    Bold                # Texte en gras (**texte** ou __texte__)
    Italic              # Texte en italique (*texte* ou _texte_)
    Code                # Code inline (`code`)
    CodeBlock           # Bloc de code (```code```)

    # Liens et rÃ©fÃ©rences
    Link                # Lien ([texte](url))
    Image               # Image (![alt](url))
    Reference           # RÃ©fÃ©rence ([texte][ref])

    # Ã‰lÃ©ments spÃ©cifiques aux roadmaps
    TaskId              # Identifiant de tÃ¢che (1.2.3, **1.2.3**, etc.)
    TaskStatus          # Statut de tÃ¢che ([ ], [x], etc.)
    TaskAssignment      # Assignation de tÃ¢che (@personne)
    TaskTag             # Tag de tÃ¢che (#tag)
    TaskPriority        # PrioritÃ© de tÃ¢che (!prioritÃ©)
    TaskDate            # Date de tÃ¢che (date:2023-08-18)

    # Autres
    Comment             # Commentaire (<!-- commentaire -->)
    Quote               # Citation (> citation)
    Table               # Tableau (| col1 | col2 |)
    FrontMatter         # Frontmatter (---)
    Unknown             # Type inconnu
}

<#
.SYNOPSIS
    Classe reprÃ©sentant un token markdown.

.DESCRIPTION
    Cette classe dÃ©finit la structure d'un token markdown, avec son type,
    sa valeur, sa position dans le document, et d'autres propriÃ©tÃ©s utiles.
#>
class MarkdownToken {
    [MarkdownTokenType]$Type        # Type de token
    [string]$Value                  # Valeur textuelle du token
    [int]$LineNumber                # NumÃ©ro de ligne dans le document
    [int]$StartPosition             # Position de dÃ©but dans la ligne
    [int]$EndPosition               # Position de fin dans la ligne
    [int]$IndentationLevel          # Niveau d'indentation
    [MarkdownToken[]]$Children      # Tokens enfants (pour les tokens imbriquÃ©s)
    [hashtable]$Metadata            # MÃ©tadonnÃ©es supplÃ©mentaires

    # Constructeur par dÃ©faut
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

    # Constructeur avec paramÃ¨tres de base
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

    # MÃ©thode pour ajouter un token enfant
    [void] AddChild([MarkdownToken]$child) {
        $this.Children += $child
    }

    # MÃ©thode pour ajouter une mÃ©tadonnÃ©e
    [void] AddMetadata([string]$key, [object]$value) {
        $this.Metadata[$key] = $value
    }

    # MÃ©thode pour obtenir une reprÃ©sentation textuelle du token
    [string] ToString() {
        return "[$($this.Type)] Line $($this.LineNumber): $($this.Value)"
    }
}

#endregion

#region Fonctions de tokenization

<#
.SYNOPSIS
    Tokenize une chaÃ®ne de texte markdown.

.DESCRIPTION
    Cette fonction analyse une chaÃ®ne de texte markdown et la convertit en une liste de tokens.

.PARAMETER MarkdownText
    ChaÃ®ne de texte markdown Ã  analyser.

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
        # VÃ©rifier si le texte est null ou vide
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

            # Ajouter les tokens de la ligne Ã  la liste globale
            $tokens += $lineTokens
        }

        # Construire l'arbre des tokens (gestion des imbrications)
        $tokenTree = New-MarkdownTokenTree -Tokens $tokens

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
    Chemin vers le fichier markdown Ã  analyser.

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
        # VÃ©rifier si le fichier existe
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
    Ligne de texte markdown Ã  analyser.

.PARAMETER LineNumber
    NumÃ©ro de la ligne dans le document.

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

        # VÃ©rifier si la ligne est null
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

        # Ã‰lÃ©ment de liste non ordonnÃ©e
        if ($Line -match '^\s*(-|\*|\+)\s+(.+)$') {
            $marker = $matches[1]
            $content = $matches[2].Trim()

            # VÃ©rifier s'il s'agit d'une tÃ¢che
            if ($content -match '^\[([ xX])\]\s+(.+)$') {
                $status = $matches[1]
                $taskContent = $matches[2].Trim()

                $token = [MarkdownToken]::new([MarkdownTokenType]::TaskItem, $taskContent, $LineNumber, 0, $Line.Length, $indentationLevel)
                $token.AddMetadata("Status", $status)
                $token.AddMetadata("Marker", $marker)

                # Extraire l'identifiant de tÃ¢che s'il existe
                if ($taskContent -match '^(\*\*[0-9.]+\*\*|\([0-9.]+\)|[0-9.]+)\s+(.+)$') {
                    $taskId = $matches[1].Trim('*', '(', ')')
                    $taskDescription = $matches[2].Trim()

                    $token.Value = $taskDescription
                    $token.AddMetadata("TaskId", $taskId)

                    # Ajouter un token spÃ©cifique pour l'identifiant
                    $idToken = [MarkdownToken]::new([MarkdownTokenType]::TaskId, $taskId, $LineNumber, 0, $matches[1].Length, $indentationLevel)
                    $token.AddChild($idToken)
                }

                # Extraire les assignations (@personne)
                if ($taskContent -match '@([a-zA-Z0-9_-]+)') {
                    $assignments = @()
                    foreach ($match in [regex]::Matches($taskContent, '@([a-zA-Z0-9_-]+)')) {
                        $assignment = $match.Groups[1].Value
                        $assignments += $assignment

                        # Ajouter un token spÃ©cifique pour l'assignation
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

                        # Ajouter un token spÃ©cifique pour le tag
                        $tagToken = [MarkdownToken]::new([MarkdownTokenType]::TaskTag, $tag, $LineNumber, $match.Index, $match.Index + $match.Length, $indentationLevel)
                        $token.AddChild($tagToken)
                    }

                    $token.AddMetadata("Tags", $tags)
                }

                $tokens += $token
            } else {
                # Liste non ordonnÃ©e standard
                $token = [MarkdownToken]::new([MarkdownTokenType]::UnorderedListItem, $content, $LineNumber, 0, $Line.Length, $indentationLevel)
                $token.AddMetadata("Marker", $marker)
                $tokens += $token
            }

            return $tokens
        }

        # Ã‰lÃ©ment de liste ordonnÃ©e
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

        # Si aucun des patterns prÃ©cÃ©dents ne correspond, considÃ©rer comme un paragraphe
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
    les espaces et les tabulations au dÃ©but de la ligne.

.PARAMETER Line
    Ligne de texte Ã  analyser.

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

        # Compter les espaces et les tabulations au dÃ©but de la ligne
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
    Cette fonction construit l'arbre des tokens markdown en gÃ©rant les imbrications
    basÃ©es sur les niveaux d'indentation.

.PARAMETER Tokens
    Liste des tokens Ã  organiser en arbre.

.EXAMPLE
    $tokenTree = New-MarkdownTokenTree -Tokens $tokens

.OUTPUTS
    MarkdownToken[]
#>
function New-MarkdownTokenTree {
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

            # Si la pile est vide, ajouter le token Ã  la liste des racines
            if ($parentStack.Count -eq 0) {
                $rootTokens += $token
                $parentStack.Push($token)
                continue
            }

            # RÃ©cupÃ©rer le token parent actuel
            $parent = $parentStack.Peek()

            # Si le token courant a un niveau d'indentation supÃ©rieur au parent,
            # l'ajouter comme enfant du parent
            if ($token.IndentationLevel -gt $parent.IndentationLevel) {
                $parent.AddChild($token)
                $parentStack.Push($token)
            }
            # Si le token courant a le mÃªme niveau d'indentation que le parent,
            # remonter d'un niveau dans la pile et ajouter le token comme frÃ¨re du parent
            elseif ($token.IndentationLevel -eq $parent.IndentationLevel) {
                $parentStack.Pop() | Out-Null

                # Si la pile est vide, ajouter le token Ã  la liste des racines
                if ($parentStack.Count -eq 0) {
                    $rootTokens += $token
                } else {
                    # Sinon, l'ajouter comme enfant du nouveau parent
                    $newParent = $parentStack.Peek()
                    $newParent.AddChild($token)
                }

                $parentStack.Push($token)
            }
            # Si le token courant a un niveau d'indentation infÃ©rieur au parent,
            # remonter dans la pile jusqu'Ã  trouver un parent de niveau infÃ©rieur ou Ã©gal
            else {
                while ($parentStack.Count -gt 0 -and $token.IndentationLevel -lt $parentStack.Peek().IndentationLevel) {
                    $parentStack.Pop() | Out-Null
                }

                # Si la pile est vide, ajouter le token Ã  la liste des racines
                if ($parentStack.Count -eq 0) {
                    $rootTokens += $token
                } else {
                    # Sinon, vÃ©rifier si le nouveau parent a le mÃªme niveau d'indentation
                    $newParent = $parentStack.Peek()

                    if ($token.IndentationLevel -eq $newParent.IndentationLevel) {
                        $parentStack.Pop() | Out-Null

                        # Si la pile est vide, ajouter le token Ã  la liste des racines
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
    Cette fonction valide un arbre de tokens markdown en vÃ©rifiant la cohÃ©rence
    des imbrications et des relations parent-enfant.

.PARAMETER Tokens
    Arbre de tokens Ã  valider.

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
        # Initialiser le rÃ©sultat de validation
        $validationResult = [PSCustomObject]@{
            IsValid  = $true
            Errors   = @()
            Warnings = @()
        }

        # Si la liste des tokens est null ou vide, retourner un rÃ©sultat valide
        if ($null -eq $Tokens -or $Tokens.Count -eq 0) {
            return $validationResult
        }

        # Fonction rÃ©cursive pour valider un token et ses enfants
        function Test-Token {
            param(
                [MarkdownToken]$Token,
                [ref]$ValidationResult
            )

            # VÃ©rifier si le token est valide
            if ($null -eq $Token) {
                $ValidationResult.Value.IsValid = $false
                $ValidationResult.Value.Errors += "Token null dÃ©tectÃ©."
                return
            }

            # VÃ©rifier si le type de token est valide
            if ($Token.Type -eq [MarkdownTokenType]::Unknown) {
                $ValidationResult.Value.Warnings += "Token de type inconnu Ã  la ligne $($Token.LineNumber): $($Token.Value)"
            }

            # VÃ©rifier la cohÃ©rence des enfants
            foreach ($child in $Token.Children) {
                # VÃ©rifier si le niveau d'indentation de l'enfant est supÃ©rieur Ã  celui du parent
                if ($child.IndentationLevel -le $Token.IndentationLevel) {
                    $ValidationResult.Value.Warnings += "Niveau d'indentation incohÃ©rent: l'enfant Ã  la ligne $($child.LineNumber) a un niveau d'indentation infÃ©rieur ou Ã©gal Ã  son parent Ã  la ligne $($Token.LineNumber)."
                }

                # Valider rÃ©cursivement l'enfant
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
Export-ModuleMember -Function ConvertFrom-MarkdownToTokens, ConvertFrom-MarkdownFileToTokens, Get-MarkdownLineTokens, Get-IndentationLevel, New-MarkdownTokenTree, Test-MarkdownTokenTree

