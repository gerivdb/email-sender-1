#Requires -Version 5.1
<#
.SYNOPSIS
Fusionne les métadonnées de deux objets d'information extraite.

.DESCRIPTION
La fonction Merge-ExtractedInfoMetadata fusionne les métadonnées de deux objets d'information extraite
en utilisant la stratégie de fusion spécifiée.

.PARAMETER Metadata1
Les métadonnées du premier objet d'information extraite.

.PARAMETER Metadata2
Les métadonnées du deuxième objet d'information extraite.

.PARAMETER MergeStrategy
La stratégie à utiliser pour résoudre les conflits lors de la fusion. Les valeurs possibles sont :
- FirstWins : En cas de conflit, la valeur du premier objet est conservée.
- LastWins : En cas de conflit, la valeur du dernier objet est conservée.
- HighestConfidence : En cas de conflit, la valeur de l'objet avec le score de confiance le plus élevé est conservée.
- Combine : Les valeurs sont combinées lorsque possible (ex: concaténation de textes, fusion de hashtables).

La valeur par défaut est "LastWins".

.PARAMETER ConfidenceScore1
Le score de confiance du premier objet d'information extraite. Utilisé uniquement avec la stratégie
HighestConfidence.

.PARAMETER ConfidenceScore2
Le score de confiance du deuxième objet d'information extraite. Utilisé uniquement avec la stratégie
HighestConfidence.

.OUTPUTS
[hashtable] Les métadonnées fusionnées.

.EXAMPLE
$metadata1 = @{ Author = "John"; Category = "Tech" }
$metadata2 = @{ Author = "Jane"; Tags = @("AI", "ML") }
$mergedMetadata = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "LastWins"

Fusionne deux ensembles de métadonnées en utilisant la stratégie du dernier gagne.

.EXAMPLE
$metadata1 = @{ Author = "John"; Category = "Tech" }
$metadata2 = @{ Author = "Jane"; Tags = @("AI", "ML") }
$mergedMetadata = Merge-ExtractedInfoMetadata -Metadata1 $metadata1 -Metadata2 $metadata2 -MergeStrategy "HighestConfidence" -ConfidenceScore1 80 -ConfidenceScore2 60

Fusionne deux ensembles de métadonnées en utilisant la stratégie de confiance la plus élevée.

.NOTES
Date de création : 2025-05-15
#>
function Merge-ExtractedInfoMetadata {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [hashtable]$Metadata1 = @{},

        [Parameter(Mandatory = $false, Position = 1)]
        [hashtable]$Metadata2 = @{},

        [Parameter(Mandatory = $false)]
        [ValidateSet('FirstWins', 'LastWins', 'HighestConfidence', 'Combine')]
        [string]$MergeStrategy = 'LastWins',

        [Parameter(Mandatory = $false)]
        [double]$ConfidenceScore1 = 50,

        [Parameter(Mandatory = $false)]
        [double]$ConfidenceScore2 = 50
    )

    # Initialiser les métadonnées fusionnées
    $mergedMetadata = @{}

    # Si l'un des ensembles de métadonnées est vide, retourner l'autre
    if ($null -eq $Metadata1 -or $Metadata1.Count -eq 0) {
        return $Metadata2.Clone()
    }

    if ($null -eq $Metadata2 -or $Metadata2.Count -eq 0) {
        return $Metadata1.Clone()
    }

    # Fusionner les métadonnées selon la stratégie choisie
    switch ($MergeStrategy) {
        'FirstWins' {
            # Copier toutes les métadonnées du premier objet
            foreach ($key in $Metadata1.Keys) {
                $mergedMetadata[$key] = $Metadata1[$key]
            }

            # Ajouter les métadonnées du deuxième objet qui n'existent pas dans le premier
            foreach ($key in $Metadata2.Keys) {
                if (-not $mergedMetadata.ContainsKey($key)) {
                    $mergedMetadata[$key] = $Metadata2[$key]
                }
            }
        }

        'LastWins' {
            # Copier toutes les métadonnées du premier objet
            foreach ($key in $Metadata1.Keys) {
                $mergedMetadata[$key] = $Metadata1[$key]
            }

            # Ajouter ou remplacer les métadonnées du deuxième objet
            foreach ($key in $Metadata2.Keys) {
                $mergedMetadata[$key] = $Metadata2[$key]
            }
        }

        'HighestConfidence' {
            # Déterminer quel objet a le score de confiance le plus élevé
            $useFirstObject = $ConfidenceScore1 -ge $ConfidenceScore2

            if ($useFirstObject) {
                # Copier toutes les métadonnées du premier objet
                foreach ($key in $Metadata1.Keys) {
                    $mergedMetadata[$key] = $Metadata1[$key]
                }

                # Ajouter les métadonnées du deuxième objet qui n'existent pas dans le premier
                foreach ($key in $Metadata2.Keys) {
                    if (-not $mergedMetadata.ContainsKey($key)) {
                        $mergedMetadata[$key] = $Metadata2[$key]
                    }
                }
            } else {
                # Copier toutes les métadonnées du deuxième objet
                foreach ($key in $Metadata2.Keys) {
                    $mergedMetadata[$key] = $Metadata2[$key]
                }

                # Ajouter les métadonnées du premier objet qui n'existent pas dans le deuxième
                foreach ($key in $Metadata1.Keys) {
                    if (-not $mergedMetadata.ContainsKey($key)) {
                        $mergedMetadata[$key] = $Metadata1[$key]
                    }
                }
            }
        }

        'Combine' {
            # Ensemble de toutes les clés
            $allKeys = @($Metadata1.Keys) + @($Metadata2.Keys) | Select-Object -Unique

            foreach ($key in $allKeys) {
                # Si la clé n'existe que dans l'un des ensembles, utiliser cette valeur
                if (-not $Metadata1.ContainsKey($key)) {
                    $mergedMetadata[$key] = $Metadata2[$key]
                    continue
                }

                if (-not $Metadata2.ContainsKey($key)) {
                    $mergedMetadata[$key] = $Metadata1[$key]
                    continue
                }

                # Si la clé existe dans les deux ensembles, combiner les valeurs si possible
                $value1 = $Metadata1[$key]
                $value2 = $Metadata2[$key]

                # Déterminer le type des valeurs
                $type1 = if ($null -eq $value1) { "Null" } else { $value1.GetType().Name }
                $type2 = if ($null -eq $value2) { "Null" } else { $value2.GetType().Name }

                # Combiner les valeurs selon leur type
                if ($type1 -eq "String" -and $type2 -eq "String") {
                    # Concaténer les chaînes
                    $mergedMetadata[$key] = "$value1 $value2".Trim()
                } elseif (($type1 -eq "Object[]" -or $type1 -eq "ArrayList") -and
                        ($type2 -eq "Object[]" -or $type2 -eq "ArrayList")) {
                    # Combiner les tableaux
                    $mergedMetadata[$key] = @($value1) + @($value2) | Select-Object -Unique
                } elseif ($type1 -eq "Hashtable" -and $type2 -eq "Hashtable") {
                    # Fusionner les hashtables récursivement
                    $mergedMetadata[$key] = Merge-ExtractedInfoMetadata -Metadata1 $value1 -Metadata2 $value2 -MergeStrategy $MergeStrategy
                } elseif ($type1 -eq "Int32" -and $type2 -eq "Int32" -or
                    $type1 -eq "Double" -and $type2 -eq "Double" -or
                    $type1 -eq "Int64" -and $type2 -eq "Int64" -or
                    $type1 -eq "Decimal" -and $type2 -eq "Decimal") {
                    # Calculer la moyenne des valeurs numériques
                    $mergedMetadata[$key] = ($value1 + $value2) / 2
                } elseif ($type1 -eq "Boolean" -and $type2 -eq "Boolean") {
                    # Opération OR pour les booléens
                    $mergedMetadata[$key] = $value1 -or $value2
                } elseif ($type1 -eq "DateTime" -and $type2 -eq "DateTime") {
                    # Utiliser la date la plus récente
                    $mergedMetadata[$key] = if ($value1 -gt $value2) { $value1 } else { $value2 }
                } else {
                    # Pour les types incompatibles, utiliser la valeur du deuxième objet
                    $mergedMetadata[$key] = $value2
                }
            }
        }
    }

    return $mergedMetadata
}

# La fonction sera exportée par le module principal
