# Outils de gestion des rÃ©fÃ©rences

Ce rÃ©pertoire contient des scripts pour dÃ©tecter et mettre Ã  jour les rÃ©fÃ©rences brisÃ©es dans les fichiers du projet, notamment suite Ã  la rÃ©organisation des scripts et Ã  la centralisation de la roadmap.

## Scripts disponibles

### Detect-BrokenReferences.ps1

Ce script analyse les fichiers du projet pour identifier les rÃ©fÃ©rences de chemins qui ne correspondent plus Ã  la nouvelle structure. Il gÃ©nÃ¨re un rapport dÃ©taillÃ© des rÃ©fÃ©rences brisÃ©es sans effectuer de modifications.

#### ParamÃ¨tres

- **ScanPath** : Chemin du rÃ©pertoire Ã  analyser. Par dÃ©faut, utilise le rÃ©pertoire courant.
- **OutputPath** : Chemin oÃ¹ enregistrer le rapport des rÃ©fÃ©rences brisÃ©es. Par dÃ©faut, utilise le rÃ©pertoire courant.
- **CustomMappings** : Chemin vers un fichier JSON contenant des mappages personnalisÃ©s de chemins obsolÃ¨tes vers nouveaux chemins.

#### Exemples d'utilisation

```powershell
# Analyser le rÃ©pertoire courant
.\Detect-BrokenReferences.ps1

# Analyser un rÃ©pertoire spÃ©cifique
.\Detect-BrokenReferences.ps1 -ScanPath "D:\Projets\EMAIL_SENDER_1"

# Utiliser des mappages personnalisÃ©s
.\Detect-BrokenReferences.ps1 -CustomMappings "path_mappings.json"
```

### Update-References.ps1

Ce script analyse les fichiers du projet pour identifier les rÃ©fÃ©rences de chemins qui ne correspondent plus Ã  la nouvelle structure et peut effectuer les remplacements de maniÃ¨re sÃ©curisÃ©e.

#### ParamÃ¨tres

- **ScanPath** : Chemin du rÃ©pertoire Ã  analyser. Par dÃ©faut, utilise le rÃ©pertoire courant.
- **ReportOnly** : Si spÃ©cifiÃ©, gÃ©nÃ¨re uniquement un rapport sans effectuer de modifications.
- **BackupFiles** : Si spÃ©cifiÃ©, crÃ©e une sauvegarde des fichiers avant de les modifier.
- **OutputPath** : Chemin oÃ¹ enregistrer le rapport des rÃ©fÃ©rences brisÃ©es. Par dÃ©faut, utilise le rÃ©pertoire courant.

#### Exemples d'utilisation

```powershell
# Analyser le rÃ©pertoire courant et gÃ©nÃ©rer un rapport sans effectuer de modifications
.\Update-References.ps1 -ReportOnly

# Analyser un rÃ©pertoire spÃ©cifique, crÃ©er des sauvegardes et mettre Ã  jour les rÃ©fÃ©rences
.\Update-References.ps1 -ScanPath "D:\Projets\EMAIL_SENDER_1" -BackupFiles
```

### Test-ReferenceUpdater.ps1

Ce script crÃ©e un environnement de test pour vÃ©rifier le bon fonctionnement des scripts Detect-BrokenReferences.ps1 et Update-References.ps1.

#### ParamÃ¨tres

- **TestDirectory** : RÃ©pertoire oÃ¹ crÃ©er l'environnement de test. Par dÃ©faut, utilise un sous-rÃ©pertoire "test" du rÃ©pertoire courant.
- **CleanupAfterTest** : Si spÃ©cifiÃ©, supprime l'environnement de test aprÃ¨s l'exÃ©cution.

#### Exemples d'utilisation

```powershell
# ExÃ©cuter les tests et conserver l'environnement pour inspection
.\Test-ReferenceUpdater.ps1

# ExÃ©cuter les tests et supprimer l'environnement aprÃ¨s l'exÃ©cution
.\Test-ReferenceUpdater.ps1 -CleanupAfterTest
```

## Format des mappages personnalisÃ©s

Pour utiliser des mappages personnalisÃ©s avec le script Detect-BrokenReferences.ps1, crÃ©ez un fichier JSON avec le format suivant :

```json
{
  "chemin/obsolete1.md": "nouveau/chemin1.md",
  "chemin\\obsolete2.md": "nouveau\\chemin2.md"
}
```

## Rapports gÃ©nÃ©rÃ©s

Les scripts gÃ©nÃ¨rent deux types de rapports :

1. **broken_references_detailed.md** : Rapport dÃ©taillÃ© contenant les informations sur chaque rÃ©fÃ©rence brisÃ©e, y compris le numÃ©ro de ligne et le contenu de la ligne.
2. **broken_references_summary.md** : Rapport de synthÃ¨se contenant un rÃ©sumÃ© des rÃ©fÃ©rences brisÃ©es par fichier.

## Bonnes pratiques

- ExÃ©cutez toujours Detect-BrokenReferences.ps1 avant Update-References.ps1 pour identifier les rÃ©fÃ©rences brisÃ©es sans effectuer de modifications.
- Utilisez l'option -BackupFiles avec Update-References.ps1 pour crÃ©er des sauvegardes des fichiers avant de les modifier.
- VÃ©rifiez les rapports gÃ©nÃ©rÃ©s avant de confirmer les mises Ã  jour.
- Testez les scripts dans un environnement de test avant de les utiliser sur des fichiers importants.

## DÃ©pannage

Si vous rencontrez des problÃ¨mes avec les scripts, vÃ©rifiez les points suivants :

- Assurez-vous que PowerShell 5.1 ou supÃ©rieur est installÃ©.
- VÃ©rifiez que vous avez les droits d'accÃ¨s en lecture et en Ã©criture sur les fichiers et rÃ©pertoires concernÃ©s.
- Si les scripts ne dÃ©tectent pas certaines rÃ©fÃ©rences brisÃ©es, vÃ©rifiez les mappages de chemins et ajoutez des mappages personnalisÃ©s si nÃ©cessaire.
