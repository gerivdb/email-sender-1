# Tâche: PRED-123

## Titre
Implémenter le module de régression linéaire simple

## Statut
in-progress

## Dépendances
- PRED-101: Définition des interfaces de prédiction
- PRED-115: Implémentation du module TrendAnalyzer

## Priorité
high

## Estimation
4 heures

## Description

### Contexte
Le système de prédiction de charge nécessite un module de régression linéaire simple pour prédire les valeurs futures des métriques système. Ce module doit s'intégrer avec le module TrendAnalyzer existant et respecter les interfaces définies dans le PRD.

### Objectifs
1. Créer un module PowerShell `SimpleLinearRegression.psm1` qui implémente les fonctionnalités de régression linéaire
2. Implémenter les fonctions principales pour créer des modèles et faire des prédictions
3. Assurer la compatibilité avec PowerShell 5.1+ sans dépendances externes
4. Fournir des métriques de qualité pour évaluer les modèles (R², RMSE, MAE)

### Spécifications techniques

#### Structure du module
- Variables globales minimales (uniquement `$script:Models` pour stocker les modèles)
- Fonctions d'accès aux modèles (`Get-SimpleLinearModel`)
- Fonctions principales exposées (`New-SimpleLinearModel`, `Invoke-SimpleLinearPrediction`)

#### Fonction New-SimpleLinearModel
- **Paramètres**:
  * `XValues [double[]]` (obligatoire): Valeurs indépendantes
  * `YValues [double[]]` (obligatoire): Valeurs dépendantes
  * `ModelName [string]` (optionnel): Nom du modèle, généré automatiquement si non fourni
- **Comportement**:
  * Calcul des coefficients (pente et ordonnée) par méthode des moindres carrés
  * Calcul des métriques de qualité (R², RMSE, MAE)
  * Stockage du modèle dans `$script:Models`
- **Retour**: Nom du modèle créé

#### Fonction Invoke-SimpleLinearPrediction
- **Paramètres**:
  * `ModelName [string]` (obligatoire): Nom du modèle à utiliser
  * `XValues [double[]]` (obligatoire): Valeurs pour lesquelles prédire
  * `ConfidenceLevel [double]` (optionnel, défaut 0.95): Niveau de confiance
- **Comportement**:
  * Récupération du modèle par son nom
  * Calcul des prédictions pour chaque valeur X
  * Calcul des intervalles de confiance
- **Retour**: Hashtable avec prédictions et intervalles

#### Gestion des erreurs
- Vérification des dimensions des tableaux d'entrée
- Gestion des cas de division par zéro
- Validation des paramètres (ConfidenceLevel entre 0 et 1)
- Retour de `$null` avec message d'erreur explicite en cas d'échec

### Contraintes
- Compatible PowerShell 5.1+
- Pas de dépendances externes
- Respect des conventions de nommage PowerShell
- Documentation complète (commentaires .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE)

## Stratégie de test

### Tests unitaires
1. **Test de création de modèle**:
   - Données parfaitement linéaires (y = 2x)
   - Vérification des coefficients (pente = 2, ordonnée = 0)
   - Vérification des métriques (R² proche de 1)

2. **Test de prédiction**:
   - Prédiction pour des valeurs dans la plage des données d'entraînement
   - Prédiction pour des valeurs hors de la plage (extrapolation)
   - Vérification des intervalles de confiance

3. **Test avec données bruitées**:
   - Données avec tendance linéaire + bruit aléatoire
   - Vérification que les coefficients sont proches des valeurs attendues
   - Vérification que R² est raisonnable (> 0.8)

4. **Tests de robustesse**:
   - Gestion des tableaux vides ou trop petits
   - Gestion des valeurs extrêmes
   - Gestion des noms de modèles invalides ou inexistants

### Critères d'acceptation
- Tous les tests unitaires passent
- Le code respecte les conventions de style PowerShell
- La documentation est complète et précise
- Les performances sont acceptables (< 100ms pour créer un modèle avec 1000 points)

## Notes de développement
- Utiliser la méthode des moindres carrés pour calculer les coefficients
- Pour les intervalles de confiance, utiliser l'approximation normale
- Stocker les modèles en mémoire uniquement (pas de persistance)
- Prévoir une extension future pour d'autres types de régression

## Livrables
- Module `SimpleLinearRegression.psm1`
- Script de test `Test-SimpleLinearRegression.ps1`
- Documentation des fonctions et exemples d'utilisation

## Historique
- 2025-05-13: Création de la tâche
- 2025-05-14: Mise à jour des spécifications après revue du PRD
