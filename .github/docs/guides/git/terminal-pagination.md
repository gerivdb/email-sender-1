# Guide : Résoudre les problèmes de pagination Git dans les terminaux

## Problème

Dans certains environnements, notamment dans l'Agent VS Code ou dans des terminaux simulés, les commandes Git qui utilisent un paginateur pour afficher leurs résultats (comme `git branch`, `git log`, etc.) peuvent sembler se bloquer ou ne pas terminer correctement.

Ce problème se manifeste généralement par :
- Une commande qui ne se termine pas
- Un caractère `:` qui apparaît à la fin de la sortie, indiquant que le paginateur attend une entrée
- L'impossibilité d'interagir avec le paginateur comme on le ferait dans un terminal standard

## Cause

Ce comportement est dû au **mode de pagination interactif de Git** :

1. **Pagination par défaut** : Git active automatiquement un paginateur (généralement `less` ou `more`) lorsque la sortie d'une commande dépasse la hauteur du terminal
2. **Interaction requise** : Le paginateur attend des commandes interactives (comme `q` pour quitter, flèches pour naviguer, etc.)
3. **Incompatibilité** : Les terminaux simulés ou l'Agent VS Code ne prennent pas entièrement en charge ces interactions, ce qui fait que la commande semble bloquée

## Solutions

### Solution 1 : Désactiver temporairement la pagination pour une commande spécifique

Pour exécuter une commande Git spécifique sans pagination :

```powershell
git --no-pager branch
git --no-pager log
```

Cette approche est utile pour des usages ponctuels sans modifier la configuration globale.

### Solution 2 : Désactiver la pagination Git globalement

Pour désactiver complètement la pagination pour toutes les commandes Git :

```powershell
git config --global core.pager ''
```

Cette configuration persiste jusqu'à ce qu'elle soit modifiée à nouveau.

### Solution 3 : Utiliser un paginateur personnalisé

Pour configurer un paginateur qui fonctionne mieux avec votre terminal :

```powershell
# Utiliser less avec des options adaptées
git config --global core.pager 'less -F -X'

# Utiliser more à la place de less
git config --global core.pager 'more'
```

L'option `-F` fait quitter automatiquement less si la sortie tient sur une page.
L'option `-X` évite que less efface l'écran.

### Solution 4 : Utiliser des commandes Git alternatives

Certaines alternatives aux commandes Git standard peuvent éviter les problèmes de pagination :

```powershell
# Alternative à git branch
git for-each-ref --format='%(refname:short)' refs/heads/
```

### Solution 5 : Créer des alias PowerShell personnalisés

Créez des fonctions qui appliquent automatiquement l'option `--no-pager` :

```powershell
function git-branch { git --no-pager branch $args }
function git-log { git --no-pager log $args }
```

Ajoutez ces fonctions à votre profil PowerShell pour les rendre persistantes.

## Restaurer la configuration par défaut

Si vous souhaitez restaurer la pagination Git à son comportement par défaut :

```powershell
git config --global core.pager 'less'
```

## Configurations avancées pour différents contextes

Pour les utilisateurs plus avancés, il est possible de configurer Git pour utiliser différents paginateurs selon le contexte :

```powershell
# Configuration spécifique à certaines commandes
git config --global pager.branch false  # Désactive la pagination uniquement pour 'git branch'
git config --global pager.log 'less -S' # Active le défilement horizontal pour 'git log'
```

## Recommandation pour ce projet

Pour l'environnement d'Agent VS Code utilisé dans ce projet, nous recommandons la solution 2 (désactiver la pagination globalement), car elle offre l'expérience la plus fluide et cohérente pour l'ensemble de l'équipe.

Si vous travaillez principalement en dehors de l'Agent VS Code, la solution 3 ou 5 pourrait être plus adaptée à vos besoins, vous permettant de profiter de la pagination lorsqu'elle est utile.