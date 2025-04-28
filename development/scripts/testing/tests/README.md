# Tests unitaires pour les scripts de test de pull requests

Ce dossier contient les tests unitaires pour les scripts de test de pull requests.

## Fichiers de test

- **Test-PRScripts.ps1** : Tests unitaires optimisÃ©s pour tous les scripts de test de pull requests
- **Simple-PRTests-Fixed.ps1** : Version alternative des tests unitaires

## ExÃ©cution des tests

Pour exÃ©cuter tous les tests et gÃ©nÃ©rer un rapport :

```powershell
.\Test-PRScripts.ps1
```

Le script gÃ©nÃ¨re automatiquement un rapport dans un dossier temporaire et affiche le chemin du rapport Ã  la fin de l'exÃ©cution.

## Rapports de tests

Le rapport de tests contient des informations sur les tests exÃ©cutÃ©s, les tests rÃ©ussis et les tests Ã©chouÃ©s. Il est gÃ©nÃ©rÃ© dans un fichier texte qui inclut :

- Le nombre total de tests exÃ©cutÃ©s
- Le nombre de tests rÃ©ussis
- Le nombre de tests Ã©chouÃ©s
- La date et l'heure de l'exÃ©cution des tests

## Approche de test

Les tests unitaires utilisent une approche simplifiÃ©e sans dÃ©pendance Ã  Pester pour Ã©viter les problÃ¨mes de rÃ©cursion. Ils suivent une approche de test basÃ©e sur les mocks pour Ã©viter d'exÃ©cuter rÃ©ellement les opÃ©rations potentiellement destructives ou coÃ»teuses.

### Mocks

Les fonctions suivantes sont mockÃ©es pour Ã©viter d'exÃ©cuter rÃ©ellement les opÃ©rations :

- **Fonctions Git** : Initialize-GitRepository, New-GitBranch, Submit-Changes, Push-Changes
- **Fonctions de manipulation de fichiers** : Add-NewFiles, Update-ExistingFiles, Remove-ExistingFiles
- **Fonctions d'analyse** : Get-PullRequestInfo, Invoke-PRAnalysis, New-PerformanceReport
- **Fonctions de test** : Initialize-TestRepository, Invoke-PRTest, New-GlobalTestReport

### Structure des tests

Le script de test suit la structure suivante :

1. **Test-NewTestRepository** : Tests pour le script de crÃ©ation de dÃ©pÃ´t de test
   - VÃ©rifie l'existence de la fonction New-TestRepository
   - VÃ©rifie que Initialize-GitRepository est appelÃ© avec les bons paramÃ¨tres

2. **Test-NewTestPullRequest** : Tests pour le script de gÃ©nÃ©ration de pull requests
   - VÃ©rifie l'existence de la fonction New-TestPullRequest
   - VÃ©rifie que New-GitBranch est appelÃ© avec les bons paramÃ¨tres

3. **Test-MeasurePRAnalysisPerformance** : Tests pour le script de mesure des performances
   - VÃ©rifie l'existence de la fonction Measure-PRAnalysisPerformance
   - VÃ©rifie que Get-PullRequestInfo retourne un objet valide
   - VÃ©rifie que New-PerformanceReport gÃ©nÃ¨re un rapport et retourne le chemin
   - VÃ©rifie que Measure-PRAnalysisPerformance accepte des paramÃ¨tres personnalisÃ©s

4. **Test-StartPRTestSuite** : Tests pour le script d'exÃ©cution de la suite de tests
   - VÃ©rifie l'existence de la fonction Start-PRTestSuite
   - VÃ©rifie que Initialize-TestRepository est appelÃ© lorsque CreateRepository est true
   - VÃ©rifie que Invoke-PRTest est appelÃ© lorsque RunAllTests est true

5. **Invoke-AllTests** : Fonction pour exÃ©cuter tous les tests et gÃ©nÃ©rer un rapport

### FonctionnalitÃ©s avancÃ©es

- **ParamÃ¨tre Force** : Tous les scripts acceptent maintenant un paramÃ¨tre Force pour Ã©viter les confirmations interactives
- **Logging dÃ©taillÃ©** : Les tests affichent des informations dÃ©taillÃ©es sur les appels aux fonctions mockÃ©es
- **VÃ©rification des paramÃ¨tres** : Les tests vÃ©rifient que les fonctions sont appelÃ©es avec les bons paramÃ¨tres

## Avantages de cette approche

- **SimplicitÃ©** : Pas de dÃ©pendance Ã  des frameworks de test externes
- **FiabilitÃ©** : Ã‰vite les problÃ¨mes de rÃ©cursion et de dÃ©pendances circulaires
- **RapiditÃ©** : ExÃ©cution rapide des tests sans chargement de modules externes
- **ClartÃ©** : RÃ©sultats clairs et faciles Ã  comprendre
- **FlexibilitÃ©** : Facile Ã  Ã©tendre avec de nouveaux tests

## Maintenance

Pour maintenir les tests Ã  jour :

1. Mettez Ã  jour les tests lorsque vous modifiez les scripts
2. Ajoutez de nouveaux tests pour les nouvelles fonctionnalitÃ©s
3. ExÃ©cutez rÃ©guliÃ¨rement les tests pour vous assurer que tout fonctionne correctement
4. Utilisez le paramÃ¨tre Force pour Ã©viter les confirmations interactives

## IntÃ©gration avec TestOmnibus

Ces tests peuvent Ãªtre intÃ©grÃ©s dans le systÃ¨me TestOmnibus pour une exÃ©cution automatisÃ©e et des rapports centralisÃ©s. Pour ce faire :

1. Ajoutez le script Test-PRScripts.ps1 Ã  la liste des tests Ã  exÃ©cuter dans TestOmnibus
2. Configurez TestOmnibus pour capturer les rÃ©sultats des tests
3. GÃ©nÃ©rez des rapports consolidÃ©s avec les rÃ©sultats de tous les tests

## ExÃ©cution automatisÃ©e

Pour exÃ©cuter les tests automatiquement dans un pipeline CI/CD :

```powershell
powershell -ExecutionPolicy Bypass -Command ".\Test-PRScripts.ps1"
```

Cette commande exÃ©cute les tests sans interaction utilisateur et retourne un code de sortie qui peut Ãªtre utilisÃ© pour dÃ©terminer si les tests ont rÃ©ussi ou Ã©chouÃ©.
