# Analyse de la fonction Register-Manager

## Signature et paramètres

La fonction `Register-Manager` du Process Manager est définie avec la signature suivante :

```powershell
function Register-Manager {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
}
```plaintext
### Analyse des paramètres

1. **Name** (string, obligatoire)
   - Représente le nom du gestionnaire à enregistrer
   - Utilisé comme clé dans le dictionnaire des gestionnaires
   - Doit être unique (sauf si `-Force` est spécifié)
   - Exemple : "ModeManager", "RoadmapManager", etc.

2. **Path** (string, obligatoire)
   - Chemin vers le script du gestionnaire
   - Doit pointer vers un fichier existant
   - Peut être un chemin relatif ou absolu
   - Exemple : "development\managers\mode-manager\scripts\mode-manager.ps1"

3. **Force** (switch, facultatif)
   - Indique si l'enregistrement doit être forcé même si le gestionnaire existe déjà
   - Valeur par défaut : `$false`
   - Permet de remplacer un gestionnaire existant

### Attributs et décorateurs

1. **[CmdletBinding(SupportsShouldProcess = $true)]**
   - Indique que la fonction prend en charge la confirmation des actions
   - Permet l'utilisation des paramètres communs comme `-WhatIf` et `-Confirm`
   - Nécessite l'utilisation de `$PSCmdlet.ShouldProcess()` dans le corps de la fonction

2. **[Parameter(Mandatory = $true)]**
   - Indique que le paramètre est obligatoire
   - L'utilisateur sera invité à fournir une valeur si elle n'est pas spécifiée

## Comportement et logique

La fonction `Register-Manager` effectue les opérations suivantes :

1. **Vérification de l'existence du fichier du gestionnaire**
   ```powershell
   if (-not (Test-Path -Path $Path)) {
       Write-Log -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
       return $false
   }
   ```
   - Vérifie si le fichier spécifié par `$Path` existe
   - Retourne `$false` si le fichier n'existe pas

2. **Vérification si le gestionnaire est déjà enregistré**
   ```powershell
   if ($config.Managers.$Name -and -not $Force) {
       Write-Log -Message "Le gestionnaire '$Name' est déjà enregistré. Utilisez -Force pour le remplacer." -Level Warning
       return $false
   }
   ```
   - Vérifie si un gestionnaire avec le même nom existe déjà
   - Si oui et que `-Force` n'est pas spécifié, retourne `$false`

3. **Enregistrement du gestionnaire**
   ```powershell
   if ($PSCmdlet.ShouldProcess($Name, "Enregistrer le gestionnaire")) {
       $config.Managers | Add-Member -NotePropertyName $Name -NotePropertyValue @{
           Path = $Path
           Enabled = $true
           RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
       } -Force

       # Enregistrer la configuration

       $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFilePath -Encoding UTF8
       Write-Log -Message "Gestionnaire '$Name' enregistré avec succès." -Level Info
       return $true
   }
   ```
   - Utilise `$PSCmdlet.ShouldProcess()` pour confirmer l'action
   - Ajoute le gestionnaire à la configuration avec les métadonnées suivantes :
     - `Path` : Chemin vers le script du gestionnaire
     - `Enabled` : État du gestionnaire (activé par défaut)
     - `RegisteredAt` : Date et heure d'enregistrement
   - Enregistre la configuration mise à jour dans le fichier de configuration
   - Retourne `$true` si l'enregistrement a réussi

## Utilisation

La fonction `Register-Manager` est utilisée dans les contextes suivants :

1. **Enregistrement manuel d'un gestionnaire**
   ```powershell
   Register-Manager -Name "ModeManager" -Path "development\managers\mode-manager\scripts\mode-manager.ps1"
   ```

2. **Enregistrement forcé d'un gestionnaire existant**
   ```powershell
   Register-Manager -Name "ModeManager" -Path "development\managers\mode-manager\scripts\mode-manager.ps1" -Force
   ```

3. **Enregistrement automatique lors de la découverte**
   ```powershell
   if (Register-Manager -Name $managerName -Path $managerScriptPath -Force:$Force) {
       $managersRegistered++
   }
   ```

## Intégration avec d'autres composants

La fonction `Register-Manager` est intégrée avec les composants suivants :

1. **Configuration du Process Manager**
   - Utilise la variable `$config` pour accéder à la configuration
   - Utilise la variable `$configFilePath` pour enregistrer la configuration

2. **Système de journalisation**
   - Utilise la fonction `Write-Log` pour journaliser les actions et les erreurs

3. **Fonction Discover-Managers**
   - Appelée par la fonction `Discover-Managers` pour enregistrer les gestionnaires découverts

4. **Script integrate-managers.ps1**
   - Utilisée par le script `integrate-managers.ps1` pour intégrer les gestionnaires existants

## Conclusion

La fonction `Register-Manager` est un composant central du Process Manager qui permet d'enregistrer des gestionnaires dans le système. Elle offre une interface simple et robuste pour l'enregistrement des gestionnaires, avec des vérifications appropriées pour éviter les erreurs et les conflits.
