# Limitations d'Augment Code

Ce document détaille les limitations techniques et pratiques d'Augment Code, pour vous aider à optimiser votre utilisation de l'outil.

## Tailles d'input et limitations

### Guidelines (instructions pour Agent et Chat)
- Les guidelines, qui permettent de personnaliser les réponses d'Augment (conventions de nommage, préférences de style), sont limitées à **2000 caractères maximum**.
- Cette limitation s'applique aux guidelines globales ou spécifiques à un espace de travail.
- Référence: [Documentation officielle d'Augment](https://docs.augmentcode.com/setup-augment/guidelines)

### Contexte et gestion du code
- Augment Code utilise un **Context Engine** capable de gérer des bases de code volumineuses (jusqu'à des millions de lignes de code).
- Fenêtre de contexte de **200 000 tokens**, significativement plus grande que la plupart des concurrents.
- Cette capacité permet de traiter des projets complexes sans nécessiter une sélection manuelle du contexte.
- Les fichiers ou dossiers ignorés (via un fichier `.augmentignore`) ne sont pas pris en compte dans le traitement.

### Limites d'input pour les requêtes
- **Limite stricte**: 5KB par input
- **Recommandation pratique**: 4KB par appel d'outil pour éviter les problèmes
- Au-delà de ces limites, il est recommandé d'utiliser les techniques de segmentation pour diviser les inputs en morceaux plus petits.

### Problèmes signalés liés à la taille d'input
- Certains utilisateurs ont rapporté des erreurs indiquant que l'input est "trop volumineux" dans le mode Agent, même en essayant de diviser les tâches.
- Ce problème semble être occasionnel et peut affecter l'expérience utilisateur.
- **Solution de contournement**: Structurer le code de manière claire et utiliser des listes de tâches que l'Agent peut suivre pour gérer les modifications complexes.

## Stratégies pour contourner les limitations

### Segmentation des inputs
- Diviser les inputs volumineux en segments plus petits (voir `docs/guides/InputSegmentation.md` pour plus de détails).
- Utiliser l'approche "une fonction à la fois" pour les modifications complexes.
- Structurer les requêtes de manière claire et concise.

### Optimisation du contexte
- Utiliser un fichier `.augmentignore` pour exclure les fichiers non pertinents.
- Fournir des contextes spécifiques et ciblés plutôt que généraux.
- Privilégier des requêtes précises et bien définies.

### Gestion des projets complexes
- Décomposer les tâches complexes en sous-tâches plus petites et gérables.
- Utiliser des listes de tâches numérotées pour guider l'Agent.
- Fournir des exemples concrets pour les modifications souhaitées.

## Performance et qualité

Malgré ces limitations, Augment Code offre des performances supérieures:
- Précision de 67% sur le test CCEval
- Score de 65,4% sur SWE-Bench, surpassant GitHub Copilot (50% avec tous les fichiers ouverts, 30% sans)
- Optimisé pour comprendre le contexte des grandes bases de code

## Contacter le support

Si vous rencontrez des problèmes spécifiques avec les tailles d'input ou si vous avez besoin de précisions:
- Contactez le support d'Augment à **support@augmentcode.com**
- Consultez la documentation officielle sur **docs.augmentcode.com**
