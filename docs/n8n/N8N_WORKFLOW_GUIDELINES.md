# Guide d'Assistance pour Workflow N8N - Gribitch Booking

## Contexte du Projet

Ce projet vise à construire et optimiser un workflow N8N nommé "Email Sender 1" pour automatiser le processus complet de booking de concerts du groupe Gribitch, depuis la prospection initiale jusqu'au suivi post-concert.

### Outils et Intégrations

- **N8N** : Plateforme d'automatisation principale
- **Notion** : Plusieurs bases de données (LOT1, Dispo Membres, Lieux, Agenda...)
- **Google Calendar** : Calendrier BOOKING1 pour la gestion des disponibilités
- **Gmail** : Communication avec les programmateurs
- **OpenRouter** : Accès à l'IA (modèle deepseek/deepseek-chat-v3-0324:free par défaut)
- **Signal** : Potentiellement utilisé pour les notifications

## Analyse des Workflows

Lors de l'analyse d'un fichier JSON de workflow N8N, il est essentiel d'examiner :

- **Connexions actives** : Suivre le flux de données réel, pas seulement les nœuds présents
- **Configuration des nœuds** : Paramètres, options et expressions utilisées
- **Logique des nœuds Code/Fonction** : Analyse du JavaScript personnalisé
- **Credentials** : Vérifier la configuration et l'utilisation des identifiants
- **Points de rupture** : Identifier les nœuds déconnectés ou mal configurés
- **Redondances** : Repérer les duplications de logique inutiles
- **Cohérence** : Vérifier l'alignement avec l'objectif de la section concernée

### Points d'attention particuliers

- **Nœuds de contrôle de flux** : Merge, IF, Switch, Loop/Split In Batches
- **Structure des données** : Format des items attendus/produits par chaque nœud
- **Expressions N8N** : Syntaxe correcte des expressions `{{ $json... }}`, `{{ $node[...]... }}`, `{{ $item... }}`

## Solutions et Bonnes Pratiques

### Format des solutions

Les solutions proposées doivent inclure :

- Snippets JSON de configuration de nœuds
- Expressions N8N précises et correctes
- Code JavaScript fonctionnel pour les nœuds Code/Fonction
- Explication de la transformation des données entre les nœuds

### Exemple de correction de nœud Code

```javascript
// Exemple de correction pour un nœud Code qui traite les disponibilités
const availableDates = [];
const busyDates = new Set($json.busyDates || []);

// Parcourir les 90 prochains jours
for (let i = 0; i < 90; i++) {
  const currentDate = new Date();
  currentDate.setDate(currentDate.getDate() + i);
  
  // Format YYYY-MM-DD
  const formattedDate = currentDate.toISOString().split('T')[0];
  
  // Vérifier si la date est un vendredi ou samedi et n'est pas occupée
  const dayOfWeek = currentDate.getDay();
  if (!busyDates.has(formattedDate) && (dayOfWeek === 5 || dayOfWeek === 6)) {
    availableDates.push({ json: { date: formattedDate, status: 'available' } });
  }
}

return availableDates;
```

### Terminologie N8N

Utiliser les termes techniques corrects :
- **Node** : Un bloc fonctionnel dans le workflow
- **Workflow** : L'ensemble du flux d'automatisation
- **Item** : Une unité de données traitée par le workflow
- **JSON** : Format des données manipulées
- **Expression** : Code dynamique entre `{{ }}` pour accéder aux données
- **Credentials** : Identifiants sécurisés pour les services externes
- **Trigger** : Nœud qui démarre l'exécution du workflow
- **Connection** : Lien entre deux nœuds

## Débogage et Résolution d'Erreurs

### Erreurs courantes

- **Problèmes de Merge** : Mauvaise configuration des entrées ou structure de données incompatible
- **Structure d'item incorrecte** : Format de données inattendu en entrée d'un nœud
- **Erreurs de syntaxe** : Expressions ou code JavaScript mal formés
- **Credentials manquants/incorrects** : Accès aux services externes non configuré
- **Options de nœud mal configurées** : Par exemple, option "Simplify" désactivée sur les nœuds Notion

### Approche de débogage

1. Identifier le nœud où l'erreur se produit
2. Vérifier la structure des données en entrée de ce nœud
3. Examiner la configuration du nœud et ses expressions
4. Suivre le flux de données depuis le déclencheur jusqu'au point d'erreur
5. Vérifier les logs d'exécution pour les messages d'erreur spécifiques

## Améliorations Recommandées

- **Modularité** : Découper les workflows complexes en sous-workflows
- **Robustesse** : Ajouter une gestion des erreurs et des cas limites
- **Lisibilité** : Utiliser des noms de nœuds descriptifs et des notes explicatives
- **Performance** : Optimiser les appels API et les opérations coûteuses
- **Maintenance** : Documenter les sections complexes et les décisions de conception

## Phases du Processus de Booking

Le workflow complet doit couvrir les phases suivantes :

1. **Prospection** : Identification et premier contact avec les programmateurs
2. **Suivi** : Gestion des réponses et relances
3. **Négociation** : Discussion des conditions et dates
4. **Deal** : Confirmation et formalisation de l'accord
5. **Logistique** : Préparation pratique du concert
6. **Post-concert** : Suivi, remerciements et évaluation

Chaque phase doit être clairement identifiable dans le workflow, avec des transitions logiques entre elles.
