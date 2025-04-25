# Outils de gestion des références

Ce répertoire contient des scripts pour détecter et mettre à jour les références brisées dans les fichiers du projet, notamment suite à la réorganisation des scripts et à la centralisation de la roadmap.

## Scripts disponibles

### Detect-BrokenReferences.ps1

Ce script analyse les fichiers du projet pour identifier les références de chemins qui ne correspondent plus à la nouvelle structure. Il génère un rapport détaillé des références brisées sans effectuer de modifications.

#### Paramètres

- **ScanPath** : Chemin du répertoire à analyser. Par défaut, utilise le répertoire courant.
- **OutputPath** : Chemin où enregistrer le rapport des références brisées. Par défaut, utilise le répertoire courant.
- **CustomMappings** : Chemin vers un fichier JSON contenant des mappages personnalisés de chemins obsolètes vers nouveaux chemins.

#### Exemples d'utilisation

```powershell
# Analyser le répertoire courant
.\Detect-BrokenReferences.ps1

# Analyser un répertoire spécifique
.\Detect-BrokenReferences.ps1 -ScanPath "D:\Projets\EMAIL_SENDER_1"

# Utiliser des mappages personnalisés
.\Detect-BrokenReferences.ps1 -CustomMappings "path_mappings.json"
```

### Update-References.ps1

Ce script analyse les fichiers du projet pour identifier les références de chemins qui ne correspondent plus à la nouvelle structure et peut effectuer les remplacements de manière sécurisée.

#### Paramètres

- **ScanPath** : Chemin du répertoire à analyser. Par défaut, utilise le répertoire courant.
- **ReportOnly** : Si spécifié, génère uniquement un rapport sans effectuer de modifications.
- **BackupFiles** : Si spécifié, crée une sauvegarde des fichiers avant de les modifier.
- **OutputPath** : Chemin où enregistrer le rapport des références brisées. Par défaut, utilise le répertoire courant.

#### Exemples d'utilisation

```powershell
# Analyser le répertoire courant et générer un rapport sans effectuer de modifications
.\Update-References.ps1 -ReportOnly

# Analyser un répertoire spécifique, créer des sauvegardes et mettre à jour les références
.\Update-References.ps1 -ScanPath "D:\Projets\EMAIL_SENDER_1" -BackupFiles
```

### Test-ReferenceUpdater.ps1

Ce script crée un environnement de test pour vérifier le bon fonctionnement des scripts Detect-BrokenReferences.ps1 et Update-References.ps1.

#### Paramètres

- **TestDirectory** : Répertoire où créer l'environnement de test. Par défaut, utilise un sous-répertoire "test" du répertoire courant.
- **CleanupAfterTest** : Si spécifié, supprime l'environnement de test après l'exécution.

#### Exemples d'utilisation

```powershell
# Exécuter les tests et conserver l'environnement pour inspection
.\Test-ReferenceUpdater.ps1

# Exécuter les tests et supprimer l'environnement après l'exécution
.\Test-ReferenceUpdater.ps1 -CleanupAfterTest
```

## Format des mappages personnalisés

Pour utiliser des mappages personnalisés avec le script Detect-BrokenReferences.ps1, créez un fichier JSON avec le format suivant :

```json
{
  "chemin/obsolete1.md": "nouveau/chemin1.md",
  "chemin\\obsolete2.md": "nouveau\\chemin2.md"
}
```

## Rapports générés

Les scripts génèrent deux types de rapports :

1. **broken_references_detailed.md** : Rapport détaillé contenant les informations sur chaque référence brisée, y compris le numéro de ligne et le contenu de la ligne.
2. **broken_references_summary.md** : Rapport de synthèse contenant un résumé des références brisées par fichier.

## Bonnes pratiques

- Exécutez toujours Detect-BrokenReferences.ps1 avant Update-References.ps1 pour identifier les références brisées sans effectuer de modifications.
- Utilisez l'option -BackupFiles avec Update-References.ps1 pour créer des sauvegardes des fichiers avant de les modifier.
- Vérifiez les rapports générés avant de confirmer les mises à jour.
- Testez les scripts dans un environnement de test avant de les utiliser sur des fichiers importants.

## Dépannage

Si vous rencontrez des problèmes avec les scripts, vérifiez les points suivants :

- Assurez-vous que PowerShell 5.1 ou supérieur est installé.
- Vérifiez que vous avez les droits d'accès en lecture et en écriture sur les fichiers et répertoires concernés.
- Si les scripts ne détectent pas certaines références brisées, vérifiez les mappages de chemins et ajoutez des mappages personnalisés si nécessaire.
