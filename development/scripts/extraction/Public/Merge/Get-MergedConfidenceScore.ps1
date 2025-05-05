#Requires -Version 5.1
<#
.SYNOPSIS
Calcule un score de confiance fusionné à partir de plusieurs scores de confiance.

.DESCRIPTION
La fonction Get-MergedConfidenceScore calcule un score de confiance fusionné à partir de plusieurs
scores de confiance en utilisant différentes méthodes de calcul.

.PARAMETER ConfidenceScores
Un tableau de scores de confiance à fusionner.

.PARAMETER Method
La méthode à utiliser pour calculer le score de confiance fusionné. Les valeurs possibles sont :
- Average : Calcule la moyenne des scores de confiance.
- Weighted : Calcule une moyenne pondérée des scores de confiance.
- Maximum : Utilise le score de confiance le plus élevé.
- Minimum : Utilise le score de confiance le plus bas.
- Product : Calcule le produit des scores de confiance (normalisés entre 0 et 1).

La valeur par défaut est "Weighted".

.PARAMETER Weights
Un tableau de poids à utiliser pour la méthode Weighted. Si non spécifié, tous les scores ont le même poids.
Le nombre de poids doit correspondre au nombre de scores de confiance.

.OUTPUTS
[double] Le score de confiance fusionné.

.EXAMPLE
$scores = @(80, 90, 70)
$mergedScore = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Average"

Calcule la moyenne des scores de confiance.

.EXAMPLE
$scores = @(80, 90, 70)
$weights = @(0.5, 0.3, 0.2)
$mergedScore = Get-MergedConfidenceScore -ConfidenceScores $scores -Method "Weighted" -Weights $weights

Calcule une moyenne pondérée des scores de confiance.

.NOTES
Date de création : 2025-05-15
#>
function Get-MergedConfidenceScore {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [double[]]$ConfidenceScores,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Average', 'Weighted', 'Maximum', 'Minimum', 'Product')]
        [string]$Method = 'Weighted',

        [Parameter(Mandatory = $false)]
        [double[]]$Weights
    )

    # Vérifier qu'il y a au moins un score de confiance
    if ($ConfidenceScores.Count -eq 0) {
        Write-Warning "Aucun score de confiance fourni. Retour de la valeur par défaut (50)."
        return 50
    }

    # Si un seul score est fourni, le retourner tel quel
    if ($ConfidenceScores.Count -eq 1) {
        return $ConfidenceScores[0]
    }

    # Calculer le score de confiance fusionné selon la méthode choisie
    switch ($Method) {
        'Average' {
            # Calculer la moyenne des scores de confiance
            $sum = 0
            foreach ($score in $ConfidenceScores) {
                $sum += $score
            }
            return $sum / $ConfidenceScores.Count
        }

        'Weighted' {
            # Vérifier si des poids ont été spécifiés
            if ($null -eq $Weights -or $Weights.Count -eq 0) {
                # Si aucun poids n'est spécifié, utiliser des poids égaux
                $Weights = @()
                for ($i = 0; $i -lt $ConfidenceScores.Count; $i++) {
                    $Weights += 1 / $ConfidenceScores.Count
                }
            }

            # Vérifier que le nombre de poids correspond au nombre de scores
            if ($Weights.Count -ne $ConfidenceScores.Count) {
                Write-Warning "Le nombre de poids ($($Weights.Count)) ne correspond pas au nombre de scores de confiance ($($ConfidenceScores.Count)). Utilisation de poids égaux."
                $Weights = @()
                for ($i = 0; $i -lt $ConfidenceScores.Count; $i++) {
                    $Weights += 1 / $ConfidenceScores.Count
                }
            }

            # Calculer la somme des poids pour normalisation
            $weightSum = 0
            foreach ($weight in $Weights) {
                $weightSum += $weight
            }

            # Normaliser les poids si nécessaire
            if ([Math]::Abs($weightSum - 1) -gt 0.0001) {
                for ($i = 0; $i -lt $Weights.Count; $i++) {
                    $Weights[$i] = $Weights[$i] / $weightSum
                }
            }

            # Calculer la moyenne pondérée
            $weightedSum = 0
            for ($i = 0; $i -lt $ConfidenceScores.Count; $i++) {
                $weightedSum += $ConfidenceScores[$i] * $Weights[$i]
            }

            return $weightedSum
        }

        'Maximum' {
            # Retourner le score de confiance le plus élevé
            return ($ConfidenceScores | Measure-Object -Maximum).Maximum
        }

        'Minimum' {
            # Retourner le score de confiance le plus bas
            return ($ConfidenceScores | Measure-Object -Minimum).Minimum
        }

        'Product' {
            # Calculer le produit des scores de confiance (normalisés entre 0 et 1)
            $product = 1
            foreach ($score in $ConfidenceScores) {
                $normalizedScore = $score / 100
                $product *= $normalizedScore
            }

            # Convertir le résultat en pourcentage
            return $product * 100
        }
    }
}

# La fonction sera exportée par le module principal
