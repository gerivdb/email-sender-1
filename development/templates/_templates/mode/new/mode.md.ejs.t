---
to: docs/guides/modes/<%= nameLower %>-mode.md
---
# Mode <%= name %>

*<%= description %>*

**Catégorie**: <%= category %>  
**Date de création**: <%= date %>

## Description

Le mode <%= name %> permet <%= description.toLowerCase() %>. Il fait partie de la catégorie des modes de <%= category %>.

## Commandes disponibles

### Commandes standard

| Commande | Description | Exemple |
|----------|-------------|---------|
| `RUN` | Exécute le mode sur la cible spécifiée | `.\<%= nameLower %>-mode.ps1 -Command RUN -Target "chemin/vers/cible"` |
| `CHECK` | Vérifie l'état du mode | `.\<%= nameLower %>-mode.ps1 -Command CHECK -Target "chemin/vers/cible"` |
| `DEBUG` | Débogue le mode | `.\<%= nameLower %>-mode.ps1 -Command DEBUG -Target "chemin/vers/cible"` |
| `TEST` | Exécute les tests du mode | `.\<%= nameLower %>-mode.ps1 -Command TEST -Target "chemin/vers/cible"` |
| `HELP` | Affiche l'aide du mode | `.\<%= nameLower %>-mode.ps1 -Command HELP` |

### Commandes spécifiques

<% commands.forEach(function(cmd) { 
    if (!['RUN', 'CHECK', 'DEBUG', 'TEST', 'HELP'].includes(cmd.name)) { %>
| `<%= cmd.name %>` | <%= cmd.description %> | `.\<%= nameLower %>-mode.ps1 -Command <%= cmd.name %> -Target "chemin/vers/cible"` |
<% }
}); %>

## Options

Le mode <%= name %> accepte les options suivantes via le paramètre `-Options` (hashtable) :

| Option | Description | Valeur par défaut | Exemple |
|--------|-------------|-------------------|---------|
| `Verbose` | Active le mode verbeux | `$false` | `-Options @{Verbose=$true}` |
| `LogLevel` | Niveau de journalisation | `"Info"` | `-Options @{LogLevel="Debug"}` |
| `OutputFormat` | Format de sortie | `"Text"` | `-Options @{OutputFormat="JSON"}` |

## Exemples d'utilisation

### Exemple 1: Exécution simple

```powershell
.\<%= nameLower %>-mode.ps1 -Command RUN -Target "chemin/vers/cible"
```

### Exemple 2: Exécution avec options

```powershell
.\<%= nameLower %>-mode.ps1 -Command RUN -Target "chemin/vers/cible" -Options @{
    Verbose = $true
    LogLevel = "Debug"
    OutputFormat = "JSON"
}
```

<% if (commands.some(cmd => !['RUN', 'CHECK', 'DEBUG', 'TEST', 'HELP'].includes(cmd.name))) { %>
### Exemple 3: Utilisation d'une commande spécifique

```powershell
.\<%= nameLower %>-mode.ps1 -Command <%= commands.find(cmd => !['RUN', 'CHECK', 'DEBUG', 'TEST', 'HELP'].includes(cmd.name)).name %> -Target "chemin/vers/cible"
```
<% } %>

## Intégration avec d'autres modes

Le mode <%= name %> peut être utilisé en combinaison avec d'autres modes pour créer des workflows complets :

<% if (category === 'analyse') { %>
### Workflow d'analyse et développement

```
<%= name %> → DEV-R → TEST → DEBUG → REVIEW
```
<% } else if (category === 'développement') { %>
### Workflow de développement

```
GRAN → <%= name %> → TEST → REVIEW → GIT
```
<% } else if (category === 'optimisation') { %>
### Workflow d'optimisation

```
PREDIC → <%= name %> → TEST → DEBUG → REVIEW
```
<% } else { %>
### Workflow spécialisé

```
ARCHI → <%= name %> → TEST → DEBUG → REVIEW
```
<% } %>

## Personnalisation

Le mode <%= name %> peut être personnalisé en modifiant le fichier de configuration `config/<%= nameLower %>-mode.config.json`.

## Dépannage

### Problèmes courants

- **Erreur "Commande non reconnue"**: Vérifiez que la commande est correctement orthographiée et fait partie des commandes disponibles.
- **Erreur "Cible introuvable"**: Vérifiez que le chemin spécifié dans le paramètre `-Target` existe et est accessible.

### Journalisation

Les logs du mode <%= name %> sont stockés dans le répertoire `logs/<%= nameLower %>-mode/`.

## Voir aussi

- [Guide général des modes opérationnels](./modes-overview.md)
- [Mode CHECK](./check-mode.md)
- [Mode DEBUG](./debug-mode.md)
