.. InputSegmenter Examples documentation

Exemples d'utilisation du module InputSegmenter
===========================================

Cette page contient des exemples concrets d'utilisation du module ``InputSegmenter`` pour segmenter automatiquement les entrées volumineuses en morceaux plus petits et gérables.

Exemple 1: Segmentation de texte
------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\InputSegmenter.psm1" -Force
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -Enabled $true -MaxInputSizeKB 100 -SegmentSizeKB 50 -OverlapSizeKB 5 -StateStoragePath ".\temp\segmentation"
    
    # Créer un texte volumineux
    $text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
    
    # Mesurer la taille du texte
    $textSize = Measure-InputSize -Input $text -InputType "Text"
    Write-Host "Taille du texte: $($textSize.SizeKB) KB"
    Write-Host "Segmentation nécessaire: $($textSize.NeedsSegmentation)"
    
    # Segmenter le texte
    $segments = Split-TextInput -Text $text -SegmentSizeKB 20 -OverlapSizeKB 2 -PreserveParagraphs
    
    # Afficher des informations sur les segments
    Write-Host "`nNombre de segments: $($segments.Count)"
    
    for ($i = 0; $i -lt $segments.Count; $i++) {
        $segmentSize = Measure-InputSize -Input $segments[$i] -InputType "Text"
        $preview = $segments[$i].Substring(0, [Math]::Min(50, $segments[$i].Length))
        
        Write-Host "`nSegment $($i+1):"
        Write-Host "Taille: $($segmentSize.SizeKB) KB"
        Write-Host "Aperçu: $preview..."
    }
    
    # Sauvegarder l'état de segmentation
    $state = @{
        OriginalInput = $text
        Segments = $segments
        CurrentSegmentIndex = 0
        TotalSegments = $segments.Count
        Timestamp = Get-Date
    }
    
    $stateId = Save-SegmentationState -State $state
    Write-Host "`nÉtat de segmentation sauvegardé avec l'ID: $stateId"
    
    # Récupérer l'état de segmentation
    $retrievedState = Get-SegmentationState -StateId $stateId
    
    if ($retrievedState) {
        Write-Host "État de segmentation récupéré avec succès"
        Write-Host "Nombre total de segments: $($retrievedState.TotalSegments)"
        Write-Host "Horodatage: $($retrievedState.Timestamp)"
    }

Exemple 2: Segmentation de fichiers
---------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\InputSegmenter.psm1" -Force
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -Enabled $true -MaxInputSizeKB 100 -SegmentSizeKB 50 -OverlapSizeKB 5
    
    # Créer un fichier texte volumineux pour le test
    $testFilePath = ".\temp\large_test_file.txt"
    $testFileContent = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 2000
    
    # Créer le dossier temp s'il n'existe pas
    if (-not (Test-Path -Path ".\temp")) {
        New-Item -Path ".\temp" -ItemType Directory | Out-Null
    }
    
    # Écrire le contenu dans le fichier
    Set-Content -Path $testFilePath -Value $testFileContent
    
    # Mesurer la taille du fichier
    $fileSize = Measure-InputSize -Input $testFilePath -InputType "File"
    Write-Host "Taille du fichier: $($fileSize.SizeKB) KB"
    Write-Host "Segmentation nécessaire: $($fileSize.NeedsSegmentation)"
    
    # Créer un dossier pour les segments
    $outputDirectory = ".\temp\segments"
    if (-not (Test-Path -Path $outputDirectory)) {
        New-Item -Path $outputDirectory -ItemType Directory | Out-Null
    }
    
    # Segmenter le fichier
    $segmentFiles = Split-FileInput -FilePath $testFilePath -OutputDirectory $outputDirectory -SegmentSizeKB 30 -OverlapSizeKB 3
    
    # Afficher des informations sur les fichiers de segments
    Write-Host "`nNombre de fichiers de segments créés: $($segmentFiles.Count)"
    
    foreach ($segmentFile in $segmentFiles) {
        $segmentFileSize = (Get-Item -Path $segmentFile).Length / 1KB
        Write-Host "Fichier de segment: $segmentFile - Taille: $([Math]::Round($segmentFileSize, 2)) KB"
    }
    
    # Lire et afficher le contenu du premier segment
    $firstSegmentContent = Get-Content -Path $segmentFiles[0] -Raw
    $preview = $firstSegmentContent.Substring(0, [Math]::Min(100, $firstSegmentContent.Length))
    Write-Host "`nAperçu du premier segment: $preview..."
    
    # Nettoyer les fichiers de test
    Write-Host "`nNettoyage des fichiers de test..."
    Remove-Item -Path $testFilePath -Force
    Remove-Item -Path $outputDirectory -Recurse -Force

Exemple 3: Segmentation de JSON
-----------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\InputSegmenter.psm1" -Force
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -Enabled $true -MaxInputSizeKB 100 -SegmentSizeKB 50 -OverlapSizeKB 5
    
    # Créer un objet JSON volumineux
    $largeArray = @()
    for ($i = 0; $i -lt 1000; $i++) {
        $largeArray += @{
            id = $i
            name = "Item $i"
            description = "Description of item $i with some additional text to increase the size of the object"
            tags = @("tag1", "tag2", "tag3")
            properties = @{
                color = "red"
                size = "large"
                weight = 10
            }
        }
    }
    
    $jsonObject = @{
        items = $largeArray
        metadata = @{
            count = $largeArray.Count
            type = "test"
            created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    
    # Convertir l'objet en chaîne JSON
    $jsonString = $jsonObject | ConvertTo-Json -Depth 10 -Compress
    
    # Mesurer la taille du JSON
    $jsonSize = Measure-InputSize -Input $jsonString -InputType "JSON"
    Write-Host "Taille du JSON: $($jsonSize.SizeKB) KB"
    Write-Host "Segmentation nécessaire: $($jsonSize.NeedsSegmentation)"
    
    # Segmenter le JSON
    $jsonSegments = Split-JsonInput -Json $jsonObject -SegmentSizeKB 30 -PreserveStructure -SplitArrays
    
    # Afficher des informations sur les segments
    Write-Host "`nNombre de segments JSON: $($jsonSegments.Count)"
    
    for ($i = 0; $i -lt $jsonSegments.Count; $i++) {
        $segment = $jsonSegments[$i]
        $itemCount = if ($segment.items) { $segment.items.Count } else { 0 }
        $segmentJson = $segment | ConvertTo-Json -Depth 3 -Compress
        $segmentSize = Measure-InputSize -Input $segmentJson -InputType "JSON"
        
        Write-Host "`nSegment JSON $($i+1):"
        Write-Host "Taille: $($segmentSize.SizeKB) KB"
        Write-Host "Nombre d'items: $itemCount"
        
        if ($segment.metadata) {
            Write-Host "Métadonnées préservées: Oui"
        } else {
            Write-Host "Métadonnées préservées: Non"
        }
    }
    
    # Sauvegarder le premier segment dans un fichier
    $firstSegmentJson = $jsonSegments[0] | ConvertTo-Json -Depth 10
    Set-Content -Path ".\temp\json_segment_1.json" -Value $firstSegmentJson
    Write-Host "`nPremier segment JSON sauvegardé dans: .\temp\json_segment_1.json"

Exemple 4: Utilisation de Invoke-WithSegmentation
----------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\InputSegmenter.psm1" -Force
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -Enabled $true -MaxInputSizeKB 100 -SegmentSizeKB 50 -OverlapSizeKB 5
    
    # Fonction de traitement qui compte les mots dans un texte
    function Count-Words {
        param (
            [string]$Text
        )
        
        $words = $Text -split '\W+' | Where-Object { $_ -ne '' }
        return $words.Count
    }
    
    # Créer un texte volumineux
    $text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
    
    # Mesurer la taille du texte
    $textSize = Measure-InputSize -Input $text -InputType "Text"
    Write-Host "Taille du texte: $($textSize.SizeKB) KB"
    
    # Compter les mots sans segmentation
    $startTime = Get-Date
    $totalWords = Count-Words -Text $text
    $endTime = Get-Date
    $timeWithoutSegmentation = ($endTime - $startTime).TotalMilliseconds
    
    Write-Host "`nSans segmentation:"
    Write-Host "Nombre total de mots: $totalWords"
    Write-Host "Temps d'exécution: $timeWithoutSegmentation ms"
    
    # Compter les mots avec segmentation
    $startTime = Get-Date
    $wordCounts = Invoke-WithSegmentation -Input $text -ScriptBlock {
        param($segment)
        return Count-Words -Text $segment
    } -InputType "Text" -SegmentSizeKB 20
    $totalWordsWithSegmentation = ($wordCounts | Measure-Object -Sum).Sum
    $endTime = Get-Date
    $timeWithSegmentation = ($endTime - $startTime).TotalMilliseconds
    
    Write-Host "`nAvec segmentation:"
    Write-Host "Nombre total de mots: $totalWordsWithSegmentation"
    Write-Host "Temps d'exécution: $timeWithSegmentation ms"
    Write-Host "Nombre de segments traités: $($wordCounts.Count)"
    
    # Comparer les résultats
    Write-Host "`nComparaison:"
    Write-Host "Différence de mots: $($totalWordsWithSegmentation - $totalWords)"
    Write-Host "Différence de temps: $($timeWithSegmentation - $timeWithoutSegmentation) ms"
    
    # Exemple avec CombineResults
    Write-Host "`nExemple avec CombineResults:"
    $combinedResult = Invoke-WithSegmentation -Input $text -ScriptBlock {
        param($segment)
        return Count-Words -Text $segment
    } -InputType "Text" -SegmentSizeKB 20 -CombineResults
    
    Write-Host "Résultat combiné: $combinedResult"

Exemple 5: Traitement parallèle avec segmentation
-----------------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\InputSegmenter.psm1" -Force
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -Enabled $true -MaxInputSizeKB 100 -SegmentSizeKB 50 -OverlapSizeKB 5
    
    # Fonction de traitement qui simule un traitement intensif
    function Process-Data {
        param (
            [string]$Data
        )
        
        # Simuler un traitement intensif
        Start-Sleep -Milliseconds 500
        
        # Compter les caractères
        return $Data.Length
    }
    
    # Créer des données volumineuses
    $data = "X" * 1000000  # Environ 1 MB de données
    
    # Mesurer la taille des données
    $dataSize = Measure-InputSize -Input $data -InputType "Text"
    Write-Host "Taille des données: $($dataSize.SizeKB) KB"
    
    # Traitement séquentiel avec segmentation
    Write-Host "`nTraitement séquentiel avec segmentation:"
    $startTime = Get-Date
    $results = Invoke-WithSegmentation -Input $data -ScriptBlock {
        param($segment)
        return Process-Data -Data $segment
    } -InputType "Text" -SegmentSizeKB 100
    $totalProcessed = ($results | Measure-Object -Sum).Sum
    $endTime = Get-Date
    $sequentialTime = ($endTime - $startTime).TotalSeconds
    
    Write-Host "Nombre total de caractères traités: $totalProcessed"
    Write-Host "Temps d'exécution: $sequentialTime secondes"
    Write-Host "Nombre de segments traités: $($results.Count)"
    
    # Traitement parallèle avec segmentation
    Write-Host "`nTraitement parallèle avec segmentation:"
    $startTime = Get-Date
    
    # Segmenter les données
    $segments = Split-TextInput -Text $data -SegmentSizeKB 100
    
    # Traiter les segments en parallèle
    $parallelResults = $segments | ForEach-Object -Parallel {
        # Importer la fonction dans le runspace
        function Process-Data {
            param (
                [string]$Data
            )
            
            # Simuler un traitement intensif
            Start-Sleep -Milliseconds 500
            
            # Compter les caractères
            return $Data.Length
        }
        
        # Traiter le segment
        Process-Data -Data $_
    } -ThrottleLimit 10
    
    $totalProcessedParallel = ($parallelResults | Measure-Object -Sum).Sum
    $endTime = Get-Date
    $parallelTime = ($endTime - $startTime).TotalSeconds
    
    Write-Host "Nombre total de caractères traités: $totalProcessedParallel"
    Write-Host "Temps d'exécution: $parallelTime secondes"
    Write-Host "Nombre de segments traités: $($segments.Count)"
    Write-Host "Accélération: $([Math]::Round($sequentialTime / $parallelTime, 2))x"

Exemple 6: Intégration avec une API externe
-----------------------------------------

.. code-block:: powershell

    # Importer le module
    Import-Module -Path ".\modules\InputSegmenter.psm1" -Force
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -Enabled $true -MaxInputSizeKB 5 -SegmentSizeKB 2 -OverlapSizeKB 0.2
    
    # Fonction simulant un appel à une API externe avec une limite de taille
    function Invoke-ExternalAPI {
        param (
            [string]$Data,
            [int]$MaxSizeKB = 2
        )
        
        # Vérifier la taille des données
        $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
        $dataSizeKB = $dataBytes.Length / 1024
        
        if ($dataSizeKB -gt $MaxSizeKB) {
            Write-Error "Les données dépassent la taille maximale autorisée de $MaxSizeKB KB (taille actuelle: $([Math]::Round($dataSizeKB, 2)) KB)"
            return $null
        }
        
        # Simuler un traitement par l'API
        Start-Sleep -Milliseconds 200
        
        # Retourner un résultat simulé
        return @{
            status = "success"
            processed_size_kb = $dataSizeKB
            word_count = ($Data -split '\W+').Count
            character_count = $Data.Length
        }
    }
    
    # Créer un texte volumineux
    $text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 100
    
    # Mesurer la taille du texte
    $textSize = Measure-InputSize -Input $text -InputType "Text"
    Write-Host "Taille du texte: $($textSize.SizeKB) KB"
    
    # Essayer d'appeler l'API directement (devrait échouer)
    Write-Host "`nAppel direct à l'API (sans segmentation):"
    try {
        $result = Invoke-ExternalAPI -Data $text
        Write-Host "Résultat: $($result | ConvertTo-Json -Compress)"
    } catch {
        Write-Host "Erreur: $_"
    }
    
    # Appeler l'API avec segmentation
    Write-Host "`nAppel à l'API avec segmentation:"
    $apiResults = Invoke-WithSegmentation -Input $text -ScriptBlock {
        param($segment)
        return Invoke-ExternalAPI -Data $segment
    } -InputType "Text" -SegmentSizeKB 2 -ContinueOnError
    
    # Afficher les résultats
    Write-Host "Nombre d'appels à l'API: $($apiResults.Count)"
    
    $totalWords = 0
    $totalChars = 0
    
    foreach ($result in $apiResults) {
        $totalWords += $result.word_count
        $totalChars += $result.character_count
    }
    
    Write-Host "Nombre total de mots traités: $totalWords"
    Write-Host "Nombre total de caractères traités: $totalChars"
    
    # Calculer les statistiques
    $averageSize = ($apiResults | Measure-Object -Property processed_size_kb -Average).Average
    Write-Host "Taille moyenne des segments: $([Math]::Round($averageSize, 2)) KB"
