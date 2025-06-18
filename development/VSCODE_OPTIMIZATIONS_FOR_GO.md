# Optimisations VS Code pour le développement Go

Ce document détaille les optimisations effectuées sur les paramètres VS Code pour améliorer l'expérience de développement Go, notamment en réduisant les notifications toast persistantes.

## Modifications apportées

### Réduction des notifications

- **Durée des notifications :** Réduit de 2500ms à 1500ms
- **Emplacement des notifications :** Maintenu en bas pour éviter l'encombrement
- **Masquage dans la barre d'état :** Activé pour éviter les distractions
- **Problèmes de décorations :** Désactivé pour réduire le bruit visuel
- **Notifications d'erreurs :** Suppression des rapports d'erreurs automatiques

### Optimisations de gopls (Go Language Server)

- **Délai de diagnostics :** Défini à 500ms pour améliorer la réactivité
- **Indices désactivés :** Suppression des indices envahissants pour :
  - Types de variables
  - Champs de littéraux composites
  - Types de littéraux composites
  - Valeurs constantes
  - Paramètres de type de fonction
  - Noms de paramètres
  - Types de variables de plage

### Code Lens et conseils

- **Code Lens pour les tests :** Désactivé pour réduire le bruit visuel
- **Code Lens global :** Désactivé pour améliorer les performances
- **Indices en ligne :** Désactivés pour une interface plus propre

### Configuration de compilation/test Go

- **Flags de construction :** Ajout de l'option `-v` pour une sortie plus détaillée
- **Timeout des tests :** Défini à 30 secondes
- **Construction au sauvegarde :** Maintenu à l'échelle de l'espace de travail

### Interface utilisateur

- **Centre de commandes :** Désactivé pour une interface plus épurée
- **Minimap :** Déjà désactivée, configuration améliorée

## Avantages

1. **Réduction des distractions :** Moins de notifications persistantes
2. **Performance améliorée :** Réduction des opérations de fond
3. **Interface plus propre :** Moins d'éléments visuels non essentiels
4. **Flux de travail optimisé :** Meilleure expérience pour le développement Go

## Remarques

Ces optimisations visent à réduire les notifications toast persistantes tout en maintenant une expérience de développement Go productive. D'autres ajustements peuvent être effectués en fonction des préférences personnelles.

Pour modifier davantage les paramètres des notifications, consultez la documentation officielle de VS Code sur les [paramètres de notification](https://code.visualstudio.com/docs/getstarted/settings#_notifications-settings).
