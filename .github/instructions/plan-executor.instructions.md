# Instructions Copilot - Exécuteur de Plans v2.0

## 🎯 Objectif
Exécuter des plans de développement avec mise à jour temps réel, suivi continu et gestion robuste des erreurs.

## 📋 Workflow d'Exécution Standard

### Phase 1: Initialisation
```powershell
# Charger le plan depuis le fichier spécifié
# Analyser la structure et identifier toutes les tâches
# Calculer progression initiale et temps estimé
# Créer point de sauvegarde initial
```

### Phase 2: Exécution avec Mise à Jour Continue
Pour chaque tâche :

**a) Pré-exécution :**
- Marquer tâche comme "EN COURS 🔄"
- Ajouter timestamp de début
- Sauvegarder état dans le fichier plan
- Afficher progression globale mise à jour

**b) Exécution :**
- Exécuter la tâche (commande shell, génération fichier, etc.)
- Si erreur : marquer "❌ ERREUR" avec détails
- Si succès : continuer

**c) Post-exécution :**
- Marquer tâche comme "✅ TERMINÉ"
- Ajouter timestamp de fin et durée
- Noter résultat/sortie de la tâche
- Mettre à jour progression globale
- Sauvegarder immédiatement dans le fichier plan

## 📊 Format de Suivi des Tâches
```markdown
### Phase X: [Nom de la Phase] [STATUT]
- [x] **T1.1** Description de la tâche
  - ⏱️ **Durée** : 00:02:15 (07:35:10 → 07:37:25)
  - ✅ **Résultat** : Description du résultat

- [ ] **T1.2** Tâche en cours [EN COURS 🔄]
  - ⏱️ **Début** : 07:42:40
  - 🔄 **Statut** : Description de l'état actuel...
  - 📋 **Sous-tâches** :
    - [x] Sous-tâche complétée
    - [ ] Sous-tâche en attente
```

## 🎛️ Commandes de Contrôle Disponibles
- `PAUSE` : Suspend l'exécution après la tâche actuelle
- `RESUME` : Reprend depuis la dernière tâche non terminée
- `STATUS` : Affiche progression détaillée
- `ROLLBACK [n]` : Annule les n dernières tâches
- `CHECKPOINT` : Crée un point de sauvegarde manuel

## 📈 Tableau de Bord Temps Réel
Afficher continuellement :
```
╔══════════════════════════════════════════════════════╗
║              📊 TABLEAU DE BORD EXÉCUTION            ║
║ Plan: [nom-du-fichier.md]                           ║
║ Progression: ████████░░░░ 60% (15/25)               ║
║ 🟢 Terminées: 15  🟡 En cours: 1  ⚪ En attente: 9 ║
║ ⏱️ Temps écoulé: 1h 45min                          ║
║ 🎯 Temps restant estimé: 32min                      ║
╚══════════════════════════════════════════════════════╝
```

## 🚨 Gestion d'Erreurs Spécialisée
```markdown
❌ **ERREUR DÉTECTÉE**
**Tâche** : [ID] - [Description]
**Timestamp** : 2025-05-27 HH:MM:SS
**Type d'erreur** : [Type]
**Détails** : [Message d'erreur complet]
**Actions automatiques tentées** : [Liste des tentatives]
**Action requise** : [Description de l'intervention nécessaire]
**Options** : [R]éessayer, [S]auter, [A]rrêter
```

## 📁 Références aux Scripts
- Scripts d'exécution : `tools/scripts/roadmap/`
- Modes opérationnels : `tools/scripts/roadmap/modes/`
- Utilitaires : `development/scripts/maintenance/`

---
*Fichier spécialisé pour l'exécution de plans de développement*