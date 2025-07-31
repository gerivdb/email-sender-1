# Incident – Boucle de validation écriture/lecture

## Description
Une boucle de validation sur l’écriture/lecture de fichiers a été détectée : la validation reposait sur la présence d’un exécutable et une lecture immédiate, causant des échecs et des boucles infinies si le fichier ou l’exécutable était absent.

## Analyse
- Validation non robuste, absence de signal explicite de succès.
- Risque de boucle si le fichier n’est pas disponible ou si l’exécutable est absent.

## Correction
- Nouvelle stratégie : signal de succès (callback) ou attente contrôlée avec tentatives et timeout.
- Modification de la fonction `writeFile` : logs détaillés, callback optionnel, fallback par attente contrôlée.
- Tests unitaires ajoutés pour valider le comportement.

## Fichiers impactés
- `tools/event-bus-model-generator/main.go`
- `tools/event-bus-model-generator/writefile_test.go`

## Date
31/07/2025

## Statut
Résolu et validé par tests unitaires.
