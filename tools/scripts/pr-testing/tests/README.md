# Tests unitaires pour les scripts de test de pull requests

Ce dossier contient les tests unitaires pour les scripts de test de pull requests.

## Fichiers de test

- **Test-PRScripts.ps1** : Tests unitaires optimisés pour tous les scripts de test de pull requests
- **Simple-PRTests-Fixed.ps1** : Version alternative des tests unitaires

## Exécution des tests

Pour exécuter tous les tests et générer un rapport :

```powershell
.\Test-PRScripts.ps1
```

Le script génère automatiquement un rapport dans un dossier temporaire et affiche le chemin du rapport à la fin de l'exécution.

## Rapports de tests

Le rapport de tests contient des informations sur les tests exécutés, les tests réussis et les tests échoués. Il est généré dans un fichier texte qui inclut :

- Le nombre total de tests exécutés
- Le nombre de tests réussis
- Le nombre de tests échoués
- La date et l'heure de l'exécution des tests

## Approche de test

Les tests unitaires utilisent une approche simplifiée sans dépendance à Pester pour éviter les problèmes de récursion. Ils suivent une approche de test basée sur les mocks pour éviter d'exécuter réellement les opérations potentiellement destructives ou coûteuses.

### Mocks

Les fonctions suivantes sont mockées pour éviter d'exécuter réellement les opérations :

- **Fonctions Git** : Initialize-GitRepository, New-GitBranch, Submit-Changes, Push-Changes
- **Fonctions de manipulation de fichiers** : Add-NewFiles, Update-ExistingFiles, Remove-ExistingFiles
- **Fonctions d'analyse** : Get-PullRequestInfo, Invoke-PRAnalysis, New-PerformanceReport
- **Fonctions de test** : Initialize-TestRepository, Invoke-PRTest, New-GlobalTestReport

### Structure des tests

Le script de test suit la structure suivante :

1. **Test-NewTestRepository** : Tests pour le script de création de dépôt de test
   - Vérifie l'existence de la fonction New-TestRepository
   - Vérifie que Initialize-GitRepository est appelé avec les bons paramètres

2. **Test-NewTestPullRequest** : Tests pour le script de génération de pull requests
   - Vérifie l'existence de la fonction New-TestPullRequest
   - Vérifie que New-GitBranch est appelé avec les bons paramètres

3. **Test-MeasurePRAnalysisPerformance** : Tests pour le script de mesure des performances
   - Vérifie l'existence de la fonction Measure-PRAnalysisPerformance
   - Vérifie que Get-PullRequestInfo retourne un objet valide
   - Vérifie que New-PerformanceReport génère un rapport et retourne le chemin
   - Vérifie que Measure-PRAnalysisPerformance accepte des paramètres personnalisés

4. **Test-StartPRTestSuite** : Tests pour le script d'exécution de la suite de tests
   - Vérifie l'existence de la fonction Start-PRTestSuite
   - Vérifie que Initialize-TestRepository est appelé lorsque CreateRepository est true
   - Vérifie que Invoke-PRTest est appelé lorsque RunAllTests est true

5. **Invoke-AllTests** : Fonction pour exécuter tous les tests et générer un rapport

### Fonctionnalités avancées

- **Paramètre Force** : Tous les scripts acceptent maintenant un paramètre Force pour éviter les confirmations interactives
- **Logging détaillé** : Les tests affichent des informations détaillées sur les appels aux fonctions mockées
- **Vérification des paramètres** : Les tests vérifient que les fonctions sont appelées avec les bons paramètres

## Avantages de cette approche

- **Simplicité** : Pas de dépendance à des frameworks de test externes
- **Fiabilité** : Évite les problèmes de récursion et de dépendances circulaires
- **Rapidité** : Exécution rapide des tests sans chargement de modules externes
- **Clarté** : Résultats clairs et faciles à comprendre
- **Flexibilité** : Facile à étendre avec de nouveaux tests

## Maintenance

Pour maintenir les tests à jour :

1. Mettez à jour les tests lorsque vous modifiez les scripts
2. Ajoutez de nouveaux tests pour les nouvelles fonctionnalités
3. Exécutez régulièrement les tests pour vous assurer que tout fonctionne correctement
4. Utilisez le paramètre Force pour éviter les confirmations interactives

## Intégration avec TestOmnibus

Ces tests peuvent être intégrés dans le système TestOmnibus pour une exécution automatisée et des rapports centralisés. Pour ce faire :

1. Ajoutez le script Test-PRScripts.ps1 à la liste des tests à exécuter dans TestOmnibus
2. Configurez TestOmnibus pour capturer les résultats des tests
3. Générez des rapports consolidés avec les résultats de tous les tests

## Exécution automatisée

Pour exécuter les tests automatiquement dans un pipeline CI/CD :

```powershell
powershell -ExecutionPolicy Bypass -Command ".\Test-PRScripts.ps1"
```

Cette commande exécute les tests sans interaction utilisateur et retourne un code de sortie qui peut être utilisé pour déterminer si les tests ont réussi ou échoué.
