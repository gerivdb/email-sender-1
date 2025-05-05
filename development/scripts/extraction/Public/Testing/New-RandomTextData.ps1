<#
.SYNOPSIS
    Génère des données textuelles aléatoires pour les tests.

.DESCRIPTION
    Cette fonction génère des données textuelles aléatoires qui peuvent être utilisées
    pour les tests de performance et de fonctionnalité du module d'extraction.
    Elle permet de personnaliser la taille, la complexité et d'autres caractéristiques du texte.

.PARAMETER WordCount
    Nombre de mots à générer. Par défaut: 100.

.PARAMETER MinSentenceLength
    Longueur minimale d'une phrase en mots. Par défaut: 5.

.PARAMETER MaxSentenceLength
    Longueur maximale d'une phrase en mots. Par défaut: 15.

.PARAMETER Complexity
    Niveau de complexité du texte (1-10). Influence le vocabulaire utilisé.
    1-3: Vocabulaire simple
    4-7: Vocabulaire intermédiaire
    8-10: Vocabulaire complexe
    Par défaut: 5.

.PARAMETER Language
    Langue du texte généré. Actuellement supporté: 'fr' (français), 'en' (anglais).
    Par défaut: 'fr'.

.PARAMETER IncludeParagraphs
    Si spécifié, le texte sera formaté en paragraphes.

.PARAMETER ParagraphBreakProbability
    Probabilité d'insérer un saut de paragraphe après une phrase (0.0-1.0).
    Par défaut: 0.2.

.PARAMETER RandomSeed
    Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
    des textes identiques à chaque exécution avec la même graine.

.EXAMPLE
    $text = New-RandomTextData -WordCount 200 -Complexity 7 -Language 'fr' -IncludeParagraphs

.EXAMPLE
    $text = New-RandomTextData -WordCount 50 -Complexity 3 -RandomSeed 12345

.NOTES
    Cette fonction est conçue pour les tests et ne doit pas être utilisée en production.
#>
function New-RandomTextData {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$WordCount = 100,
        
        [Parameter(Mandatory = $false)]
        [int]$MinSentenceLength = 5,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxSentenceLength = 15,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$Complexity = 5,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('fr', 'en')]
        [string]$Language = 'fr',
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeParagraphs,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 1.0)]
        [double]$ParagraphBreakProbability = 0.2,
        
        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )
    
    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    }
    else {
        $random = New-Object System.Random
    }
    
    # Dictionnaires de mots par langue et niveau de complexité
    $wordDictionaries = @{
        'fr' = @{
            'simple' = @(
                "le", "la", "un", "une", "et", "ou", "de", "des", "ce", "cette", "ces", "mon", "ma", "mes", 
                "ton", "ta", "tes", "son", "sa", "ses", "notre", "nos", "votre", "vos", "leur", "leurs", 
                "je", "tu", "il", "elle", "nous", "vous", "ils", "elles", "être", "avoir", "faire", "dire", 
                "voir", "venir", "aller", "prendre", "mettre", "passer", "donner", "trouver", "parler", 
                "aimer", "vouloir", "pouvoir", "savoir", "falloir", "devoir", "jour", "temps", "année", 
                "fois", "homme", "femme", "enfant", "chose", "monde", "vie", "main", "oeil", "tête", 
                "coeur", "eau", "air", "terre", "feu", "maison", "travail", "pays", "ville", "rue"
            ),
            'medium' = @(
                "information", "extraction", "document", "analyse", "système", "processus", "méthode", 
                "technique", "résultat", "donnée", "structure", "fonction", "module", "paramètre", 
                "variable", "constante", "condition", "boucle", "itération", "récursion", "algorithme", 
                "performance", "optimisation", "implémentation", "développement", "conception", 
                "architecture", "interface", "composant", "service", "application", "programme", 
                "logiciel", "bibliothèque", "framework", "plateforme", "environnement", "infrastructure", 
                "configuration", "installation", "intégration", "déploiement", "maintenance", "évolution", 
                "version", "mise à jour", "correction", "amélioration", "fonctionnalité", "caractéristique"
            ),
            'complex' = @(
                "parallélisation", "synchronisation", "désérialisation", "interopérabilité", 
                "internationalisation", "localisation", "authentification", "autorisation", 
                "cryptographie", "virtualisation", "conteneurisation", "orchestration", "microservice", 
                "résilience", "scalabilité", "disponibilité", "maintenabilité", "testabilité", 
                "observabilité", "traçabilité", "idempotence", "atomicité", "consistance", "isolation", 
                "durabilité", "polymorphisme", "encapsulation", "héritage", "abstraction", 
                "métaprogrammation", "réflexion", "introspection", "sérialisation", "marshalling", 
                "multithreading", "asynchronisme", "concurrence", "parallélisme", "vectorisation", 
                "transpilation", "compilation", "interprétation", "bytecode", "méta-modèle", 
                "ontologie", "taxonomie", "sémantique", "pragmatique", "heuristique"
            )
        ),
        'en' = @{
            'simple' = @(
                "the", "a", "an", "and", "or", "of", "to", "in", "on", "at", "by", "for", "with", "about", 
                "from", "up", "down", "over", "under", "this", "that", "these", "those", "my", "your", 
                "his", "her", "its", "our", "their", "I", "you", "he", "she", "it", "we", "they", "be", 
                "have", "do", "say", "see", "come", "go", "take", "put", "make", "get", "find", "give", 
                "tell", "work", "call", "try", "ask", "need", "feel", "seem", "leave", "like", "day", 
                "time", "year", "way", "thing", "man", "woman", "child", "world", "life", "hand", "eye", 
                "head", "heart", "water", "air", "earth", "fire", "house", "work", "country", "city", "street"
            ),
            'medium' = @(
                "information", "extraction", "document", "analysis", "system", "process", "method", 
                "technique", "result", "data", "structure", "function", "module", "parameter", 
                "variable", "constant", "condition", "loop", "iteration", "recursion", "algorithm", 
                "performance", "optimization", "implementation", "development", "design", 
                "architecture", "interface", "component", "service", "application", "program", 
                "software", "library", "framework", "platform", "environment", "infrastructure", 
                "configuration", "installation", "integration", "deployment", "maintenance", "evolution", 
                "version", "update", "correction", "improvement", "functionality", "feature"
            ),
            'complex' = @(
                "parallelization", "synchronization", "deserialization", "interoperability", 
                "internationalization", "localization", "authentication", "authorization", 
                "cryptography", "virtualization", "containerization", "orchestration", "microservice", 
                "resilience", "scalability", "availability", "maintainability", "testability", 
                "observability", "traceability", "idempotence", "atomicity", "consistency", "isolation", 
                "durability", "polymorphism", "encapsulation", "inheritance", "abstraction", 
                "metaprogramming", "reflection", "introspection", "serialization", "marshalling", 
                "multithreading", "asynchronism", "concurrency", "parallelism", "vectorization", 
                "transpilation", "compilation", "interpretation", "bytecode", "metamodel", 
                "ontology", "taxonomy", "semantics", "pragmatics", "heuristics"
            )
        }
    }
    
    # Vérifier si la langue est supportée
    if (-not $wordDictionaries.ContainsKey($Language)) {
        Write-Warning "Langue '$Language' non supportée. Utilisation du français par défaut."
        $Language = 'fr'
    }
    
    # Sélectionner les dictionnaires en fonction de la complexité
    $selectedDictionaries = @()
    
    if ($Complexity -le 3) {
        $selectedDictionaries += ,($wordDictionaries[$Language]['simple'] * 3)
        $selectedDictionaries += ,($wordDictionaries[$Language]['medium'] * 1)
    }
    elseif ($Complexity -le 7) {
        $selectedDictionaries += ,($wordDictionaries[$Language]['simple'] * 2)
        $selectedDictionaries += ,($wordDictionaries[$Language]['medium'] * 2)
        $selectedDictionaries += ,($wordDictionaries[$Language]['complex'] * 1)
    }
    else {
        $selectedDictionaries += ,($wordDictionaries[$Language]['simple'] * 1)
        $selectedDictionaries += ,($wordDictionaries[$Language]['medium'] * 2)
        $selectedDictionaries += ,($wordDictionaries[$Language]['complex'] * 3)
    }
    
    # Fusionner les dictionnaires
    $allWords = $selectedDictionaries | ForEach-Object { $_ }
    
    # Générer les mots
    $words = @()
    for ($i = 0; $i -lt $WordCount; $i++) {
        $wordIndex = $random.Next(0, $allWords.Count)
        $words += $allWords[$wordIndex]
    }
    
    # Construire le texte
    $text = ""
    $currentSentence = ""
    $wordCount = 0
    $sentenceLength = $random.Next($MinSentenceLength, $MaxSentenceLength + 1)
    
    foreach ($word in $words) {
        # Ajouter le mot à la phrase courante
        if ($currentSentence -eq "") {
            # Première lettre en majuscule
            $currentSentence = $word.Substring(0, 1).ToUpper() + $word.Substring(1)
        }
        else {
            $currentSentence += " " + $word
        }
        
        $wordCount++
        
        # Terminer la phrase si on atteint la longueur cible
        if ($wordCount -ge $sentenceLength) {
            # Ajouter un point final
            $currentSentence += "."
            
            # Ajouter la phrase au texte
            if ($IncludeParagraphs -and $text -ne "" -and $random.NextDouble() -lt $ParagraphBreakProbability) {
                $text += $currentSentence + [Environment]::NewLine + [Environment]::NewLine
            }
            else {
                $text += $currentSentence + " "
            }
            
            # Réinitialiser pour la prochaine phrase
            $currentSentence = ""
            $wordCount = 0
            $sentenceLength = $random.Next($MinSentenceLength, $MaxSentenceLength + 1)
        }
    }
    
    # Ajouter la dernière phrase si nécessaire
    if ($currentSentence -ne "") {
        $currentSentence += "."
        $text += $currentSentence
    }
    
    return $text.Trim()
}

# Exporter la fonction
Export-ModuleMember -Function New-RandomTextData
