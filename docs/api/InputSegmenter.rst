.. InputSegmenter API documentation

Module InputSegmenter
===================

Le module ``InputSegmenter`` fournit des fonctionnalités pour segmenter automatiquement les entrées volumineuses en morceaux plus petits et gérables. Il est particulièrement utile pour traiter des données qui dépassent les limites de taille imposées par certains outils ou API.

Fonctions principales
--------------------

Initialize-InputSegmentation
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Initialize-InputSegmentation [-Enabled <Boolean>] [-MaxInputSizeKB <Int32>] [-SegmentSizeKB <Int32>] [-OverlapSizeKB <Int32>] [-StateStoragePath <String>]

Initialise le module de segmentation des entrées avec les paramètres spécifiés.

Paramètres:
    * **Enabled** (*Boolean*) - Active ou désactive la segmentation des entrées. Valeur par défaut : $true
    * **MaxInputSizeKB** (*Int32*) - Taille maximale d'entrée en kilo-octets avant segmentation. Valeur par défaut : 100
    * **SegmentSizeKB** (*Int32*) - Taille de chaque segment en kilo-octets. Valeur par défaut : 50
    * **OverlapSizeKB** (*Int32*) - Taille de chevauchement entre segments en kilo-octets. Valeur par défaut : 5
    * **StateStoragePath** (*String*) - Chemin du dossier de stockage de l'état de segmentation. Valeur par défaut : ".\temp\segmentation"

Valeur de retour:
    Booléen indiquant si l'initialisation a réussi.

Exemple:

.. code-block:: powershell

    # Initialiser le module de segmentation avec des paramètres personnalisés
    Initialize-InputSegmentation -Enabled $true -MaxInputSizeKB 200 -SegmentSizeKB 100 -OverlapSizeKB 10 -StateStoragePath ".\data\segmentation"

Measure-InputSize
~~~~~~~~~~~~~~~

.. code-block:: powershell

    Measure-InputSize -Input <Object> [-InputType <String>]

Mesure la taille d'une entrée en kilo-octets.

Paramètres:
    * **Input** (*Object*) - L'entrée à mesurer (chaîne de caractères, objet JSON, fichier, etc.).
    * **InputType** (*String*) - Type d'entrée (Text, JSON, File, Object). Si non spécifié, le type est détecté automatiquement.

Valeur de retour:
    Un objet avec les propriétés suivantes:
    
    * **SizeKB** (*Double*) - Taille de l'entrée en kilo-octets.
    * **SizeBytes** (*Int64*) - Taille de l'entrée en octets.
    * **InputType** (*String*) - Type d'entrée détecté.
    * **NeedsSegmentation** (*Boolean*) - Indique si l'entrée doit être segmentée (taille > MaxInputSizeKB).

Exemple:

.. code-block:: powershell

    # Mesurer la taille d'une chaîne de caractères
    $text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
    $textSize = Measure-InputSize -Input $text -InputType "Text"
    
    Write-Host "Taille du texte: $($textSize.SizeKB) KB"
    Write-Host "Segmentation nécessaire: $($textSize.NeedsSegmentation)"
    
    # Mesurer la taille d'un fichier
    $fileSize = Measure-InputSize -Input ".\data\large_file.json" -InputType "File"
    
    Write-Host "Taille du fichier: $($fileSize.SizeKB) KB"
    Write-Host "Segmentation nécessaire: $($fileSize.NeedsSegmentation)"

Split-TextInput
~~~~~~~~~~~~~

.. code-block:: powershell

    Split-TextInput -Text <String> [-SegmentSizeKB <Int32>] [-OverlapSizeKB <Int32>] [-PreserveParagraphs]

Segmente une chaîne de caractères en morceaux plus petits.

Paramètres:
    * **Text** (*String*) - Le texte à segmenter.
    * **SegmentSizeKB** (*Int32*) - Taille de chaque segment en kilo-octets. Si non spécifié, utilise la valeur définie lors de l'initialisation.
    * **OverlapSizeKB** (*Int32*) - Taille de chevauchement entre segments en kilo-octets. Si non spécifié, utilise la valeur définie lors de l'initialisation.
    * **PreserveParagraphs** (*Switch*) - Préserve les paragraphes lors de la segmentation.

Valeur de retour:
    Un tableau de segments de texte.

Exemple:

.. code-block:: powershell

    # Segmenter un texte
    $text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
    $segments = Split-TextInput -Text $text -SegmentSizeKB 10 -OverlapSizeKB 1 -PreserveParagraphs
    
    Write-Host "Nombre de segments: $($segments.Count)"
    
    # Afficher les premiers caractères de chaque segment
    for ($i = 0; $i -lt $segments.Count; $i++) {
        $preview = $segments[$i].Substring(0, [Math]::Min(50, $segments[$i].Length))
        Write-Host "Segment $($i+1): $preview..."
    }

Split-JsonInput
~~~~~~~~~~~~~

.. code-block:: powershell

    Split-JsonInput -Json <Object> [-SegmentSizeKB <Int32>] [-PreserveStructure] [-SplitArrays] [-SplitObjects]

Segmente un objet JSON en morceaux plus petits.

Paramètres:
    * **Json** (*Object*) - L'objet JSON à segmenter (chaîne de caractères ou objet déjà désérialisé).
    * **SegmentSizeKB** (*Int32*) - Taille de chaque segment en kilo-octets. Si non spécifié, utilise la valeur définie lors de l'initialisation.
    * **PreserveStructure** (*Switch*) - Préserve la structure JSON lors de la segmentation.
    * **SplitArrays** (*Switch*) - Segmente les tableaux JSON.
    * **SplitObjects** (*Switch*) - Segmente les objets JSON.

Valeur de retour:
    Un tableau de segments JSON.

Exemple:

.. code-block:: powershell

    # Créer un objet JSON avec un grand tableau
    $largeArray = @()
    for ($i = 0; $i -lt 1000; $i++) {
        $largeArray += @{
            id = $i
            name = "Item $i"
            description = "Description of item $i"
        }
    }
    $jsonObject = @{
        items = $largeArray
        metadata = @{
            count = $largeArray.Count
            type = "test"
        }
    }
    
    # Segmenter l'objet JSON
    $jsonSegments = Split-JsonInput -Json $jsonObject -SegmentSizeKB 10 -PreserveStructure -SplitArrays
    
    Write-Host "Nombre de segments JSON: $($jsonSegments.Count)"
    
    # Afficher la structure de chaque segment
    for ($i = 0; $i -lt $jsonSegments.Count; $i++) {
        $segment = $jsonSegments[$i]
        $itemCount = if ($segment.items) { $segment.items.Count } else { 0 }
        Write-Host "Segment $($i+1): $itemCount items"
    }

Split-FileInput
~~~~~~~~~~~~~

.. code-block:: powershell

    Split-FileInput -FilePath <String> [-OutputDirectory <String>] [-SegmentSizeKB <Int32>] [-OverlapSizeKB <Int32>] [-DetectFormat]

Segmente un fichier en morceaux plus petits.

Paramètres:
    * **FilePath** (*String*) - Chemin du fichier à segmenter.
    * **OutputDirectory** (*String*) - Dossier de sortie pour les segments. Par défaut : dossier du fichier d'entrée.
    * **SegmentSizeKB** (*Int32*) - Taille de chaque segment en kilo-octets. Si non spécifié, utilise la valeur définie lors de l'initialisation.
    * **OverlapSizeKB** (*Int32*) - Taille de chevauchement entre segments en kilo-octets. Si non spécifié, utilise la valeur définie lors de l'initialisation.
    * **DetectFormat** (*Switch*) - Détecte automatiquement le format du fichier et utilise la méthode de segmentation appropriée.

Valeur de retour:
    Un tableau de chemins vers les fichiers de segments créés.

Exemple:

.. code-block:: powershell

    # Segmenter un fichier texte
    $segmentFiles = Split-FileInput -FilePath ".\data\large_file.txt" -OutputDirectory ".\data\segments" -SegmentSizeKB 50 -DetectFormat
    
    Write-Host "Nombre de fichiers de segments créés: $($segmentFiles.Count)"
    
    # Afficher les chemins des fichiers de segments
    foreach ($segmentFile in $segmentFiles) {
        Write-Host "Fichier de segment: $segmentFile"
    }

Split-Input
~~~~~~~~~

.. code-block:: powershell

    Split-Input -Input <Object> [-InputType <String>] [-SegmentSizeKB <Int32>] [-OverlapSizeKB <Int32>] [-OutputDirectory <String>] [-PreserveStructure]

Segmente une entrée en fonction de son type.

Paramètres:
    * **Input** (*Object*) - L'entrée à segmenter (chaîne de caractères, objet JSON, fichier, etc.).
    * **InputType** (*String*) - Type d'entrée (Text, JSON, File, Object). Si non spécifié, le type est détecté automatiquement.
    * **SegmentSizeKB** (*Int32*) - Taille de chaque segment en kilo-octets. Si non spécifié, utilise la valeur définie lors de l'initialisation.
    * **OverlapSizeKB** (*Int32*) - Taille de chevauchement entre segments en kilo-octets. Si non spécifié, utilise la valeur définie lors de l'initialisation.
    * **OutputDirectory** (*String*) - Dossier de sortie pour les segments de fichiers. Par défaut : dossier du fichier d'entrée.
    * **PreserveStructure** (*Switch*) - Préserve la structure lors de la segmentation.

Valeur de retour:
    Un tableau de segments ou de chemins vers les fichiers de segments créés.

Exemple:

.. code-block:: powershell

    # Segmenter une entrée (type détecté automatiquement)
    $input = Get-Content -Path ".\data\large_file.json" -Raw
    $segments = Split-Input -Input $input -SegmentSizeKB 50 -PreserveStructure
    
    Write-Host "Nombre de segments: $($segments.Count)"
    
    # Segmenter un fichier
    $fileSegments = Split-Input -Input ".\data\large_file.csv" -InputType "File" -OutputDirectory ".\data\segments" -SegmentSizeKB 100
    
    Write-Host "Nombre de fichiers de segments créés: $($fileSegments.Count)"

Save-SegmentationState
~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Save-SegmentationState -State <Object> [-StateId <String>] [-StoragePath <String>]

Sauvegarde l'état de segmentation pour une utilisation ultérieure.

Paramètres:
    * **State** (*Object*) - L'état de segmentation à sauvegarder.
    * **StateId** (*String*) - Identifiant unique de l'état. Par défaut : GUID généré automatiquement.
    * **StoragePath** (*String*) - Chemin du dossier de stockage. Si non spécifié, utilise la valeur définie lors de l'initialisation.

Valeur de retour:
    L'identifiant de l'état sauvegardé.

Exemple:

.. code-block:: powershell

    # Segmenter un texte
    $text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
    $segments = Split-TextInput -Text $text -SegmentSizeKB 10
    
    # Créer un état de segmentation
    $state = @{
        OriginalInput = $text
        Segments = $segments
        CurrentSegmentIndex = 0
        TotalSegments = $segments.Count
        Timestamp = Get-Date
    }
    
    # Sauvegarder l'état
    $stateId = Save-SegmentationState -State $state -StoragePath ".\data\segmentation_states"
    
    Write-Host "État de segmentation sauvegardé avec l'ID: $stateId"

Get-SegmentationState
~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Get-SegmentationState -StateId <String> [-StoragePath <String>]

Récupère un état de segmentation sauvegardé.

Paramètres:
    * **StateId** (*String*) - Identifiant de l'état à récupérer.
    * **StoragePath** (*String*) - Chemin du dossier de stockage. Si non spécifié, utilise la valeur définie lors de l'initialisation.

Valeur de retour:
    L'état de segmentation récupéré.

Exemple:

.. code-block:: powershell

    # Récupérer un état de segmentation
    $state = Get-SegmentationState -StateId "12345678-1234-1234-1234-123456789012" -StoragePath ".\data\segmentation_states"
    
    if ($state) {
        Write-Host "État de segmentation récupéré"
        Write-Host "Nombre total de segments: $($state.TotalSegments)"
        Write-Host "Segment actuel: $($state.CurrentSegmentIndex + 1)"
        
        # Utiliser le segment actuel
        $currentSegment = $state.Segments[$state.CurrentSegmentIndex]
        Write-Host "Taille du segment actuel: $([Math]::Round((([System.Text.Encoding]::UTF8.GetBytes($currentSegment)).Length / 1024), 2)) KB"
    } else {
        Write-Host "État de segmentation non trouvé"
    }

Invoke-WithSegmentation
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: powershell

    Invoke-WithSegmentation -Input <Object> -ScriptBlock <ScriptBlock> [-InputType <String>] [-SegmentSizeKB <Int32>] [-OverlapSizeKB <Int32>] [-PreserveStructure] [-CombineResults] [-ContinueOnError]

Exécute un bloc de script sur chaque segment d'une entrée.

Paramètres:
    * **Input** (*Object*) - L'entrée à segmenter et à traiter.
    * **ScriptBlock** (*ScriptBlock*) - Le bloc de script à exécuter sur chaque segment. Le segment est passé comme premier argument.
    * **InputType** (*String*) - Type d'entrée (Text, JSON, File, Object). Si non spécifié, le type est détecté automatiquement.
    * **SegmentSizeKB** (*Int32*) - Taille de chaque segment en kilo-octets. Si non spécifié, utilise la valeur définie lors de l'initialisation.
    * **OverlapSizeKB** (*Int32*) - Taille de chevauchement entre segments en kilo-octets. Si non spécifié, utilise la valeur définie lors de l'initialisation.
    * **PreserveStructure** (*Switch*) - Préserve la structure lors de la segmentation.
    * **CombineResults** (*Switch*) - Combine les résultats de chaque segment en un seul résultat.
    * **ContinueOnError** (*Switch*) - Continue l'exécution même si une erreur se produit lors du traitement d'un segment.

Valeur de retour:
    Un tableau des résultats de l'exécution du bloc de script sur chaque segment, ou un résultat combiné si CombineResults est spécifié.

Exemple:

.. code-block:: powershell

    # Fonction de traitement qui compte les mots dans un texte
    function Count-Words {
        param (
            [string]$Text
        )
        
        $words = $Text -split '\W+' | Where-Object { $_ -ne '' }
        return $words.Count
    }
    
    # Texte volumineux
    $text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
    
    # Compter les mots avec segmentation
    $wordCounts = Invoke-WithSegmentation -Input $text -ScriptBlock {
        param($segment)
        return Count-Words -Text $segment
    } -InputType "Text" -SegmentSizeKB 10 -CombineResults
    
    Write-Host "Nombre total de mots: $wordCounts"
    
    # Traitement plus complexe avec JSON
    $largeJson = @{
        items = 1..1000 | ForEach-Object {
            @{
                id = $_
                name = "Item $_"
                value = $_ * 10
            }
        }
    }
    
    # Calculer la somme des valeurs
    $results = Invoke-WithSegmentation -Input $largeJson -ScriptBlock {
        param($segment)
        
        $sum = 0
        if ($segment.items) {
            foreach ($item in $segment.items) {
                $sum += $item.value
            }
        }
        
        return $sum
    } -InputType "JSON" -SegmentSizeKB 10 -PreserveStructure
    
    $totalSum = ($results | Measure-Object -Sum).Sum
    Write-Host "Somme totale des valeurs: $totalSum"
