# Journal des erreurs

## 2025-04-08 20:45

### Erreur : Valeur null dans les expressions rÃ©guliÃ¨res
- **Message d'erreur** : `Exception lors de l'appel de Â« Matches Â» avec Â« 2 Â» argument(s) : Â« La valeur ne peut pas Ãªtre null. Nom du paramÃ¨tre : input Â»`
- **Fichiers concernÃ©s** : 
  - `scripts\maintenance\encoding\Detect-BrokenReferences.ps1`
  - `scripts\maintenance\standards\Test-ScriptCompliance-v2.ps1`
- **Cause** : Tentative d'utilisation de la mÃ©thode statique `[regex]::Matches()` avec une variable potentiellement null sans vÃ©rification prÃ©alable.
- **Solution** : Ajout de vÃ©rifications conditionnelles (`if ($null -ne $variable)`) avant d'appeler la mÃ©thode.
- **Pattern d'erreur inÃ©dit** : Erreur silencieuse dans l'analyse des expressions rÃ©guliÃ¨res qui ne se manifeste que lors du traitement de certains fichiers spÃ©cifiques, rendant le diagnostic difficile.

### Erreur : AccÃ¨s Ã  un objet Matches potentiellement vide
- **Message d'erreur** : Erreur indirecte causÃ©e par l'accÃ¨s Ã  `$Matches[0]` lorsque `$Matches` est vide ou null.
- **Fichiers concernÃ©s** : `scripts\maintenance\standards\Test-ScriptCompliance-v2.ps1`
- **Cause** : AprÃ¨s une opÃ©ration de correspondance d'expression rÃ©guliÃ¨re, le script tentait d'accÃ©der Ã  `$Matches[0]` sans vÃ©rifier si `$Matches` contenait des Ã©lÃ©ments.
- **Solution** : Ajout d'une vÃ©rification double (`$null -ne $Matches -and $Matches.Count -gt 0`) avant d'accÃ©der aux Ã©lÃ©ments de `$Matches`.
- **Pattern d'erreur inÃ©dit** : Erreur de propagation oÃ¹ une valeur null ou vide dans une Ã©tape intermÃ©diaire d'analyse provoque des erreurs en cascade dans les Ã©tapes suivantes, compliquant l'identification de la source rÃ©elle du problÃ¨me.

### Patterns d'erreur inÃ©dits identifiÃ©s

1. **Erreurs de propagation en cascade** : Une erreur non gÃ©rÃ©e dans un script de base (comme `Detect-BrokenReferences.ps1`) peut se propager Ã  travers plusieurs couches d'appels de scripts, rendant difficile l'identification de la source rÃ©elle du problÃ¨me. Ce pattern est particuliÃ¨rement problÃ©matique dans les systÃ¨mes modulaires oÃ¹ les scripts s'appellent les uns les autres.

2. **Erreurs conditionnelles dÃ©pendantes du contenu** : Les erreurs qui ne se manifestent que lors du traitement de certains types de fichiers ou de contenus spÃ©cifiques sont difficiles Ã  reproduire et Ã  diagnostiquer. Dans notre cas, l'erreur n'apparaissait que lors de l'analyse de fichiers avec certaines caractÃ©ristiques.

3. **Erreurs silencieuses dans les mÃ©thodes statiques** : Contrairement aux cmdlets PowerShell qui ont souvent des comportements par dÃ©faut pour gÃ©rer les valeurs null, les mÃ©thodes statiques comme `[regex]::Matches()` Ã©chouent de maniÃ¨re explicite avec des valeurs null, nÃ©cessitant des vÃ©rifications manuelles.

4. **Erreurs d'hypothÃ¨se sur les rÃ©sultats d'expressions rÃ©guliÃ¨res** : Supposer qu'une expression rÃ©guliÃ¨re trouvera toujours une correspondance est une source courante d'erreurs. Les scripts doivent toujours vÃ©rifier si des correspondances ont Ã©tÃ© trouvÃ©es avant de tenter d'y accÃ©der.
