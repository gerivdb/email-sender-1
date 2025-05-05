#Requires -Version 5.1
<#
.SYNOPSIS
Fusionne deux ou plusieurs objets d'information extraite en un seul objet consolidé.

.DESCRIPTION
La fonction Merge-ExtractedInfo permet de fusionner des objets d'information extraite qui proviennent
de la même source mais contiennent des informations complémentaires. Elle prend en charge différentes
stratégies de fusion pour gérer les conflits entre les propriétés.

.PARAMETER PrimaryInfo
L'objet d'information extraite principal qui servira de base pour la fusion.

.PARAMETER SecondaryInfo
L'objet d'information extraite secondaire à fusionner avec l'objet principal.

.PARAMETER InfoArray
Un tableau d'objets d'information extraite à fusionner. Cette option est mutuellement exclusive avec
les paramètres PrimaryInfo et SecondaryInfo.

.PARAMETER MergeStrategy
La stratégie à utiliser pour résoudre les conflits lors de la fusion. Les valeurs possibles sont :
- FirstWins : En cas de conflit, la valeur du premier objet est conservée.
- LastWins : En cas de conflit, la valeur du dernier objet est conservée.
- HighestConfidence : En cas de conflit, la valeur de l'objet avec le score de confiance le plus élevé est conservée.
- Combine : Les valeurs sont combinées lorsque possible (ex: concaténation de textes, fusion de hashtables).

La valeur par défaut est "LastWins".

.PARAMETER MetadataMergeStrategy
La stratégie à utiliser pour fusionner les métadonnées. Les valeurs possibles sont les mêmes que pour
le paramètre MergeStrategy. Si non spécifié, la même stratégie que MergeStrategy est utilisée.

.PARAMETER Force
Indique si la fusion doit être forcée même si les objets ne sont pas parfaitement compatibles.
Par défaut, les objets doivent être du même type pour être fusionnés.

.EXAMPLE
$text1 = New-TextExtractedInfo -Source "document.txt" -Text "Première partie du texte." -Language "fr"
$text2 = New-TextExtractedInfo -Source "document.txt" -Text "Seconde partie du texte." -Language "fr"
$mergedText = Merge-ExtractedInfo -PrimaryInfo $text1 -SecondaryInfo $text2 -MergeStrategy "Combine"

Fusionne deux objets TextExtractedInfo en combinant leurs textes.

.EXAMPLE
$data1 = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "John"; Age = 30 } -DataFormat "Hashtable"
$data1.ConfidenceScore = 70
$data2 = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "John Doe"; Email = "john@example.com" } -DataFormat "Hashtable"
$data2.ConfidenceScore = 90
$mergedData = Merge-ExtractedInfo -PrimaryInfo $data1 -SecondaryInfo $data2 -MergeStrategy "HighestConfidence"

Fusionne deux objets StructuredDataExtractedInfo en utilisant la stratégie de confiance la plus élevée.

.EXAMPLE
$infoArray = @($text1, $text2, $text3)
$mergedInfo = Merge-ExtractedInfo -InfoArray $infoArray -MergeStrategy "LastWins"

Fusionne plusieurs objets d'information extraite en utilisant la stratégie du dernier gagne.

.NOTES
Date de création : 2025-05-15
#>
function Merge-ExtractedInfo {
    [CmdletBinding(DefaultParameterSetName = 'TwoObjects')]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'TwoObjects', Position = 0)]
        [hashtable]$PrimaryInfo,

        [Parameter(Mandatory = $true, ParameterSetName = 'TwoObjects', Position = 1)]
        [hashtable]$SecondaryInfo,

        [Parameter(Mandatory = $true, ParameterSetName = 'Array', Position = 0)]
        [hashtable[]]$InfoArray,

        [Parameter(Mandatory = $false)]
        [ValidateSet('FirstWins', 'LastWins', 'HighestConfidence', 'Combine')]
        [string]$MergeStrategy = 'LastWins',

        [Parameter(Mandatory = $false)]
        [ValidateSet('FirstWins', 'LastWins', 'HighestConfidence', 'Combine')]
        [string]$MetadataMergeStrategy,

        [Parameter(Mandatory = $false)]
        [switch]$Force = $false
    )

    begin {
        # Initialisation des variables
        $mergedInfo = $null
        $objectsToMerge = @()

        # Déterminer la stratégie de fusion des métadonnées
        if (-not $PSBoundParameters.ContainsKey('MetadataMergeStrategy')) {
            $MetadataMergeStrategy = $MergeStrategy
        }

        # Préparer la liste des objets à fusionner
        if ($PSCmdlet.ParameterSetName -eq 'TwoObjects') {
            $objectsToMerge = @($PrimaryInfo, $SecondaryInfo)
        } else {
            $objectsToMerge = $InfoArray
        }

        # Vérifier qu'il y a au moins un objet à fusionner
        if ($objectsToMerge.Count -eq 0) {
            throw "Aucun objet à fusionner n'a été fourni."
        }

        # Si un seul objet est fourni, le retourner tel quel
        if ($objectsToMerge.Count -eq 1) {
            Write-Verbose "Un seul objet fourni, aucune fusion nécessaire."
            return $objectsToMerge[0]
        }
    }

    process {
        # Cette fonction ne traite pas les objets en pipeline, donc le bloc process est vide
    }

    end {
        # Validation des objets à fusionner
        Write-Verbose "Validation des objets à fusionner..."

        # Importer la fonction de validation
        . (Join-Path -Path $PSScriptRoot -ChildPath "Test-ExtractedInfoCompatibility.ps1")

        # Vérifier la compatibilité des objets à fusionner
        for ($i = 0; $i -lt $objectsToMerge.Count - 1; $i++) {
            $info1 = $objectsToMerge[$i]
            $info2 = $objectsToMerge[$i + 1]

            $compatibilityResult = Test-ExtractedInfoCompatibility -Info1 $info1 -Info2 $info2 -Force:$Force

            if (-not $compatibilityResult.IsCompatible) {
                $errorMessage = "Les objets à fusionner ne sont pas compatibles :"
                foreach ($reason in $compatibilityResult.Reasons) {
                    $errorMessage += "`n- $reason"
                }

                throw $errorMessage
            }

            if ($compatibilityResult.CompatibilityLevel -lt 80) {
                Write-Warning "Les objets à fusionner ont un niveau de compatibilité faible ($($compatibilityResult.CompatibilityLevel)%)."
                foreach ($reason in $compatibilityResult.Reasons) {
                    Write-Warning "- $reason"
                }
            }
        }

        Write-Verbose "Validation des objets terminée. Niveau de compatibilité : $($compatibilityResult.CompatibilityLevel)%"

        # Fusion des objets selon la stratégie choisie
        Write-Verbose "Fusion des objets selon la stratégie : $MergeStrategy"

        # Importer les fonctions auxiliaires
        . (Join-Path -Path $PSScriptRoot -ChildPath "Merge-ExtractedInfoMetadata.ps1")
        . (Join-Path -Path $PSScriptRoot -ChildPath "Get-MergedConfidenceScore.ps1")

        # Initialiser l'objet fusionné avec le premier objet
        $mergedInfo = $objectsToMerge[0].Clone()

        # Fusionner les objets un par un
        for ($i = 1; $i -lt $objectsToMerge.Count; $i++) {
            $currentInfo = $objectsToMerge[$i]

            Write-Verbose "Fusion de l'objet $i/$($objectsToMerge.Count - 1)..."

            # Fusion des propriétés de base
            Write-Verbose "Fusion des propriétés de base..."

            # Fusion de la source
            if ($mergedInfo.ContainsKey('Source') -and $currentInfo.ContainsKey('Source')) {
                if ($mergedInfo.Source -ne $currentInfo.Source) {
                    switch ($MergeStrategy) {
                        'FirstWins' {
                            # Conserver la source du premier objet (déjà fait)
                        }
                        'LastWins' {
                            $mergedInfo.Source = $currentInfo.Source
                        }
                        'HighestConfidence' {
                            $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                            $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                            if ($confidenceScore2 -gt $confidenceScore1) {
                                $mergedInfo.Source = $currentInfo.Source
                            }
                        }
                        'Combine' {
                            # Combiner les sources si elles sont différentes
                            $mergedInfo.Source = "$($mergedInfo.Source), $($currentInfo.Source)"
                        }
                    }
                }
            } elseif ($currentInfo.ContainsKey('Source')) {
                $mergedInfo.Source = $currentInfo.Source
            }

            # Fusion de l'ID
            # L'ID est une propriété unique, on conserve généralement celui du premier objet
            # Mais on peut le stocker dans les métadonnées pour référence
            if ($mergedInfo.ContainsKey('Id') -and $currentInfo.ContainsKey('Id') -and $mergedInfo.Id -ne $currentInfo.Id) {
                if (-not $mergedInfo.ContainsKey('Metadata')) {
                    $mergedInfo.Metadata = @{}
                }

                if (-not $mergedInfo.Metadata.ContainsKey('MergedIds')) {
                    $mergedInfo.Metadata.MergedIds = @($mergedInfo.Id)
                }

                $mergedInfo.Metadata.MergedIds += $currentInfo.Id
            }

            # Fusion des propriétés communes à tous les types
            $commonProperties = @('Description', 'Tags', 'Category', 'Priority', 'Status')

            foreach ($property in $commonProperties) {
                if ($mergedInfo.ContainsKey($property) -and $currentInfo.ContainsKey($property)) {
                    switch ($MergeStrategy) {
                        'FirstWins' {
                            # Conserver la valeur du premier objet (déjà fait)
                        }
                        'LastWins' {
                            $mergedInfo[$property] = $currentInfo[$property]
                        }
                        'HighestConfidence' {
                            $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                            $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                            if ($confidenceScore2 -gt $confidenceScore1) {
                                $mergedInfo[$property] = $currentInfo[$property]
                            }
                        }
                        'Combine' {
                            # Combiner les valeurs selon leur type
                            $value1 = $mergedInfo[$property]
                            $value2 = $currentInfo[$property]

                            if ($value1 -is [string] -and $value2 -is [string]) {
                                # Concaténer les chaînes
                                if ($value1 -ne $value2) {
                                    $mergedInfo[$property] = "$value1, $value2"
                                }
                            } elseif (($value1 -is [array] -or $value1 -is [System.Collections.ArrayList]) -and
                                    ($value2 -is [array] -or $value2 -is [System.Collections.ArrayList])) {
                                # Combiner les tableaux
                                $mergedInfo[$property] = @($value1) + @($value2) | Select-Object -Unique
                            } elseif ($value1 -is [hashtable] -and $value2 -is [hashtable]) {
                                # Fusionner les hashtables
                                $mergedValue = $value1.Clone()
                                foreach ($key in $value2.Keys) {
                                    $mergedValue[$key] = $value2[$key]
                                }
                                $mergedInfo[$property] = $mergedValue
                            } else {
                                # Pour les autres types, utiliser la valeur du deuxième objet
                                $mergedInfo[$property] = $value2
                            }
                        }
                    }
                } elseif ($currentInfo.ContainsKey($property)) {
                    $mergedInfo[$property] = $currentInfo[$property]
                }
            }

            # Ajouter les propriétés du deuxième objet qui n'existent pas dans le premier
            foreach ($key in $currentInfo.Keys) {
                if (-not $mergedInfo.ContainsKey($key) -and
                    $key -ne '_Type' -and
                    $key -ne 'Id' -and
                    $key -ne 'Source' -and
                    $key -ne 'ExtractedAt' -and
                    $key -ne 'LastModifiedDate' -and
                    $key -ne 'ProcessingState' -and
                    $key -ne 'ConfidenceScore' -and
                    $key -ne 'Metadata') {

                    $mergedInfo[$key] = $currentInfo[$key]
                }
            }

            # Fusion des métadonnées
            if ($mergedInfo.ContainsKey('Metadata') -or $currentInfo.ContainsKey('Metadata')) {
                $metadata1 = if ($mergedInfo.ContainsKey('Metadata')) { $mergedInfo.Metadata } else { @{} }
                $metadata2 = if ($currentInfo.ContainsKey('Metadata')) { $currentInfo.Metadata } else { @{} }

                $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                $mergedInfo.Metadata = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy $MetadataMergeStrategy -ConfidenceScore1 $confidenceScore1 -ConfidenceScore2 $confidenceScore2
            }

            # Fusion des scores de confiance
            if ($mergedInfo.ContainsKey('ConfidenceScore') -or $currentInfo.ContainsKey('ConfidenceScore')) {
                $scores = @()

                if ($mergedInfo.ContainsKey('ConfidenceScore')) {
                    $scores += $mergedInfo.ConfidenceScore
                }

                if ($currentInfo.ContainsKey('ConfidenceScore')) {
                    $scores += $currentInfo.ConfidenceScore
                }

                # Déterminer la méthode de calcul du score de confiance en fonction de la stratégie de fusion
                $confidenceMethod = switch ($MergeStrategy) {
                    'FirstWins' { 'Maximum' }
                    'LastWins' { 'Maximum' }
                    'HighestConfidence' { 'Maximum' }
                    'Combine' { 'Weighted' }
                    default { 'Weighted' }
                }

                $mergedInfo.ConfidenceScore = Get-MergedConfidenceScore -ConfidenceScores $scores -Method $confidenceMethod
            }

            # Fusion des dates d'extraction
            if ($mergedInfo.ContainsKey('ExtractedAt') -and $currentInfo.ContainsKey('ExtractedAt')) {
                switch ($MergeStrategy) {
                    'FirstWins' {
                        # Conserver la date du premier objet (déjà fait)
                    }
                    'LastWins' {
                        $mergedInfo.ExtractedAt = $currentInfo.ExtractedAt
                    }
                    'HighestConfidence' {
                        $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                        $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                        if ($confidenceScore2 -gt $confidenceScore1) {
                            $mergedInfo.ExtractedAt = $currentInfo.ExtractedAt
                        }
                    }
                    'Combine' {
                        # Utiliser la date la plus récente
                        if ($currentInfo.ExtractedAt -gt $mergedInfo.ExtractedAt) {
                            $mergedInfo.ExtractedAt = $currentInfo.ExtractedAt
                        }
                    }
                }
            } elseif ($currentInfo.ContainsKey('ExtractedAt')) {
                $mergedInfo.ExtractedAt = $currentInfo.ExtractedAt
            }

            # Fusion de l'état de traitement
            if ($mergedInfo.ContainsKey('ProcessingState') -and $currentInfo.ContainsKey('ProcessingState')) {
                switch ($MergeStrategy) {
                    'FirstWins' {
                        # Conserver l'état du premier objet (déjà fait)
                    }
                    'LastWins' {
                        $mergedInfo.ProcessingState = $currentInfo.ProcessingState
                    }
                    'HighestConfidence' {
                        $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                        $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                        if ($confidenceScore2 -gt $confidenceScore1) {
                            $mergedInfo.ProcessingState = $currentInfo.ProcessingState
                        }
                    }
                    'Combine' {
                        # Utiliser l'état le plus avancé
                        $states = @('New', 'Processing', 'Processed', 'Error', 'Archived')
                        $state1Index = $states.IndexOf($mergedInfo.ProcessingState)
                        $state2Index = $states.IndexOf($currentInfo.ProcessingState)

                        if ($state2Index -gt $state1Index) {
                            $mergedInfo.ProcessingState = $currentInfo.ProcessingState
                        }
                    }
                }
            } elseif ($currentInfo.ContainsKey('ProcessingState')) {
                $mergedInfo.ProcessingState = $currentInfo.ProcessingState
            }

            # Gestion des cas spécifiques par type d'objet
            Write-Verbose "Gestion des cas spécifiques par type d'objet : $($mergedInfo._Type)"

            switch ($mergedInfo._Type) {
                "TextExtractedInfo" {
                    # Fusion du texte
                    if ($mergedInfo.ContainsKey('Text') -and $currentInfo.ContainsKey('Text')) {
                        switch ($MergeStrategy) {
                            'FirstWins' {
                                # Conserver le texte du premier objet (déjà fait)
                            }
                            'LastWins' {
                                $mergedInfo.Text = $currentInfo.Text
                            }
                            'HighestConfidence' {
                                $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                                $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                                if ($confidenceScore2 -gt $confidenceScore1) {
                                    $mergedInfo.Text = $currentInfo.Text
                                }
                            }
                            'Combine' {
                                # Combiner les textes
                                if ($mergedInfo.Text -ne $currentInfo.Text) {
                                    $mergedInfo.Text = "$($mergedInfo.Text)`n`n$($currentInfo.Text)"
                                }
                            }
                        }
                    } elseif ($currentInfo.ContainsKey('Text')) {
                        $mergedInfo.Text = $currentInfo.Text
                    }

                    # Fusion de la langue
                    if ($mergedInfo.ContainsKey('Language') -and $currentInfo.ContainsKey('Language')) {
                        if ($mergedInfo.Language -ne $currentInfo.Language) {
                            switch ($MergeStrategy) {
                                'FirstWins' {
                                    # Conserver la langue du premier objet (déjà fait)
                                }
                                'LastWins' {
                                    $mergedInfo.Language = $currentInfo.Language
                                }
                                'HighestConfidence' {
                                    $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                                    $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                                    if ($confidenceScore2 -gt $confidenceScore1) {
                                        $mergedInfo.Language = $currentInfo.Language
                                    }
                                }
                                'Combine' {
                                    # Pour la langue, on ne peut pas vraiment combiner, donc on utilise la langue du texte le plus long
                                    if ($currentInfo.ContainsKey('Text') -and $mergedInfo.ContainsKey('Text')) {
                                        if ($currentInfo.Text.Length -gt $mergedInfo.Text.Length) {
                                            $mergedInfo.Language = $currentInfo.Language
                                        }
                                    }
                                }
                            }
                        }
                    } elseif ($currentInfo.ContainsKey('Language')) {
                        $mergedInfo.Language = $currentInfo.Language
                    }
                }

                "StructuredDataExtractedInfo" {
                    # Fusion des données structurées
                    if ($mergedInfo.ContainsKey('Data') -and $currentInfo.ContainsKey('Data')) {
                        switch ($MergeStrategy) {
                            'FirstWins' {
                                # Conserver les données du premier objet (déjà fait)
                            }
                            'LastWins' {
                                $mergedInfo.Data = $currentInfo.Data
                            }
                            'HighestConfidence' {
                                $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                                $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                                if ($confidenceScore2 -gt $confidenceScore1) {
                                    $mergedInfo.Data = $currentInfo.Data
                                }
                            }
                            'Combine' {
                                # Combiner les données structurées
                                if ($mergedInfo.Data -is [hashtable] -and $currentInfo.Data -is [hashtable]) {
                                    # Fusionner les hashtables récursivement
                                    $mergedData = Merge-ExtractedInfoMetadata -Metadata1 $mergedInfo.Data -Metadata2 $currentInfo.Data -MergeStrategy 'Combine'
                                    $mergedInfo.Data = $mergedData
                                } elseif ($mergedInfo.Data -is [array] -and $currentInfo.Data -is [array]) {
                                    # Combiner les tableaux
                                    $mergedInfo.Data = @($mergedInfo.Data) + @($currentInfo.Data)
                                } else {
                                    # Pour les autres types, utiliser les données du deuxième objet
                                    $mergedInfo.Data = $currentInfo.Data
                                }
                            }
                        }
                    } elseif ($currentInfo.ContainsKey('Data')) {
                        $mergedInfo.Data = $currentInfo.Data
                    }

                    # Fusion du format de données
                    if ($mergedInfo.ContainsKey('DataFormat') -and $currentInfo.ContainsKey('DataFormat')) {
                        if ($mergedInfo.DataFormat -ne $currentInfo.DataFormat) {
                            switch ($MergeStrategy) {
                                'FirstWins' {
                                    # Conserver le format du premier objet (déjà fait)
                                }
                                'LastWins' {
                                    $mergedInfo.DataFormat = $currentInfo.DataFormat
                                }
                                'HighestConfidence' {
                                    $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                                    $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                                    if ($confidenceScore2 -gt $confidenceScore1) {
                                        $mergedInfo.DataFormat = $currentInfo.DataFormat
                                    }
                                }
                                'Combine' {
                                    # Pour le format de données, on ne peut pas vraiment combiner, donc on utilise celui du deuxième objet
                                    $mergedInfo.DataFormat = $currentInfo.DataFormat
                                }
                            }
                        }
                    } elseif ($currentInfo.ContainsKey('DataFormat')) {
                        $mergedInfo.DataFormat = $currentInfo.DataFormat
                    }
                }

                "GeoLocationExtractedInfo" {
                    # Fusion des coordonnées géographiques
                    $geoProperties = @('Latitude', 'Longitude', 'City', 'Country', 'Address', 'PostalCode', 'Region')

                    foreach ($property in $geoProperties) {
                        if ($mergedInfo.ContainsKey($property) -and $currentInfo.ContainsKey($property)) {
                            switch ($MergeStrategy) {
                                'FirstWins' {
                                    # Conserver la valeur du premier objet (déjà fait)
                                }
                                'LastWins' {
                                    $mergedInfo[$property] = $currentInfo[$property]
                                }
                                'HighestConfidence' {
                                    $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                                    $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                                    if ($confidenceScore2 -gt $confidenceScore1) {
                                        $mergedInfo[$property] = $currentInfo[$property]
                                    }
                                }
                                'Combine' {
                                    # Pour les coordonnées, on ne peut pas vraiment combiner, donc on utilise celles de l'objet avec le score de confiance le plus élevé
                                    $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                                    $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                                    if ($confidenceScore2 -gt $confidenceScore1) {
                                        $mergedInfo[$property] = $currentInfo[$property]
                                    }
                                }
                            }
                        } elseif ($currentInfo.ContainsKey($property)) {
                            $mergedInfo[$property] = $currentInfo[$property]
                        }
                    }
                }

                "MediaExtractedInfo" {
                    # Fusion des propriétés média
                    $mediaProperties = @('MediaPath', 'MediaType', 'MediaFormat', 'MediaSize', 'MediaDuration')

                    foreach ($property in $mediaProperties) {
                        if ($mergedInfo.ContainsKey($property) -and $currentInfo.ContainsKey($property)) {
                            switch ($MergeStrategy) {
                                'FirstWins' {
                                    # Conserver la valeur du premier objet (déjà fait)
                                }
                                'LastWins' {
                                    $mergedInfo[$property] = $currentInfo[$property]
                                }
                                'HighestConfidence' {
                                    $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                                    $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                                    if ($confidenceScore2 -gt $confidenceScore1) {
                                        $mergedInfo[$property] = $currentInfo[$property]
                                    }
                                }
                                'Combine' {
                                    # Pour les propriétés média, on ne peut pas vraiment combiner, donc on utilise celles de l'objet avec le score de confiance le plus élevé
                                    $confidenceScore1 = if ($mergedInfo.ContainsKey('ConfidenceScore')) { $mergedInfo.ConfidenceScore } else { 50 }
                                    $confidenceScore2 = if ($currentInfo.ContainsKey('ConfidenceScore')) { $currentInfo.ConfidenceScore } else { 50 }

                                    if ($confidenceScore2 -gt $confidenceScore1) {
                                        $mergedInfo[$property] = $currentInfo[$property]
                                    }
                                }
                            }
                        } elseif ($currentInfo.ContainsKey($property)) {
                            $mergedInfo[$property] = $currentInfo[$property]
                        }
                    }
                }

                default {
                    # Pour les autres types, on fusionne les propriétés de manière générique
                    Write-Verbose "Type non spécifique : $($mergedInfo._Type). Fusion générique des propriétés."

                    # Ajouter toutes les propriétés du deuxième objet qui n'existent pas dans le premier
                    foreach ($key in $currentInfo.Keys) {
                        if (-not $mergedInfo.ContainsKey($key)) {
                            $mergedInfo[$key] = $currentInfo[$key]
                        }
                    }
                }
            }
        }

        # Mettre à jour la date de dernière modification
        $mergedInfo.LastModifiedDate = [datetime]::Now

        # Retourner l'objet fusionné
        return $mergedInfo
    }
}

# La fonction sera exportée par le module principal
