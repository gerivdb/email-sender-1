# Journal des erreurs

## 2025-04-08 20:45

### Erreur : Valeur null dans les expressions régulières
- **Message d'erreur** : `Exception lors de l'appel de « Matches » avec « 2 » argument(s) : « La valeur ne peut pas être null. Nom du paramètre : input »`
- **Fichiers concernés** : 
  - `scripts\maintenance\encoding\Detect-BrokenReferences.ps1`
  - `scripts\maintenance\standards\Test-ScriptCompliance-v2.ps1`
- **Cause** : Tentative d'utilisation de la méthode statique `[regex]::Matches()` avec une variable potentiellement null sans vérification préalable.
- **Solution** : Ajout de vérifications conditionnelles (`if ($null -ne $variable)`) avant d'appeler la méthode.
- **Pattern d'erreur inédit** : Erreur silencieuse dans l'analyse des expressions régulières qui ne se manifeste que lors du traitement de certains fichiers spécifiques, rendant le diagnostic difficile.

### Erreur : Accès à un objet Matches potentiellement vide
- **Message d'erreur** : Erreur indirecte causée par l'accès à `$Matches[0]` lorsque `$Matches` est vide ou null.
- **Fichiers concernés** : `scripts\maintenance\standards\Test-ScriptCompliance-v2.ps1`
- **Cause** : Après une opération de correspondance d'expression régulière, le script tentait d'accéder à `$Matches[0]` sans vérifier si `$Matches` contenait des éléments.
- **Solution** : Ajout d'une vérification double (`$null -ne $Matches -and $Matches.Count -gt 0`) avant d'accéder aux éléments de `$Matches`.
- **Pattern d'erreur inédit** : Erreur de propagation où une valeur null ou vide dans une étape intermédiaire d'analyse provoque des erreurs en cascade dans les étapes suivantes, compliquant l'identification de la source réelle du problème.

### Patterns d'erreur inédits identifiés

1. **Erreurs de propagation en cascade** : Une erreur non gérée dans un script de base (comme `Detect-BrokenReferences.ps1`) peut se propager à travers plusieurs couches d'appels de scripts, rendant difficile l'identification de la source réelle du problème. Ce pattern est particulièrement problématique dans les systèmes modulaires où les scripts s'appellent les uns les autres.

2. **Erreurs conditionnelles dépendantes du contenu** : Les erreurs qui ne se manifestent que lors du traitement de certains types de fichiers ou de contenus spécifiques sont difficiles à reproduire et à diagnostiquer. Dans notre cas, l'erreur n'apparaissait que lors de l'analyse de fichiers avec certaines caractéristiques.

3. **Erreurs silencieuses dans les méthodes statiques** : Contrairement aux cmdlets PowerShell qui ont souvent des comportements par défaut pour gérer les valeurs null, les méthodes statiques comme `[regex]::Matches()` échouent de manière explicite avec des valeurs null, nécessitant des vérifications manuelles.

4. **Erreurs d'hypothèse sur les résultats d'expressions régulières** : Supposer qu'une expression régulière trouvera toujours une correspondance est une source courante d'erreurs. Les scripts doivent toujours vérifier si des correspondances ont été trouvées avant de tenter d'y accéder.
