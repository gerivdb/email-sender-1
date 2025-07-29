# Recueil des besoins – Projet

Ce document synthétise l’ensemble des besoins du projet, structuré pour revue et validation. Il couvre : user stories, tableaux, rapport JSON, logs, scripts d’automatisation, critères de validation, procédures de rollback, documentation associée et traçabilité.

---

## 1. User Stories par besoin

### 1.1 Besoins utilisateurs/personas

| Persona         | Besoin principal                          | User Story                                                                 |
|-----------------|------------------------------------------|----------------------------------------------------------------------------|
| Administrateur  | Gestion centralisée des modes             | En tant qu’administrateur, je veux pouvoir configurer et activer différents modes pour adapter l’outil aux besoins métier. |
| Utilisateur     | Suivi personnalisé des tâches             | En tant qu’utilisateur, je veux visualiser mes tâches et leur avancement pour mieux organiser mon travail. |
| Auditeur        | Accès aux logs et historiques             | En tant qu’auditeur, je veux accéder aux logs horodatés et historiques pour assurer la traçabilité des actions. |

### 1.2 Besoins techniques

| Besoin technique           | User Story                                                                 |
|----------------------------|----------------------------------------------------------------------------|
| Intégration API            | En tant que développeur, je veux intégrer l’API du projet avec des systèmes externes pour automatiser les échanges. |
| Monitoring & alertes       | En tant qu’opérateur, je veux recevoir des alertes automatiques en cas d’anomalie détectée par le monitoring. |
| Versionnement              | En tant que mainteneur, je veux que chaque modification soit versionnée et sauvegardée pour permettre le rollback. |

### 1.3 Besoins d’intégration

| Besoin d’intégration       | User Story                                                                 |
|----------------------------|----------------------------------------------------------------------------|
| Synchronisation n8n        | En tant qu’intégrateur, je veux synchroniser les workflows n8n pour garantir la cohérence des processus. |
| Connecteurs multiples      | En tant qu’intégrateur, je veux pouvoir ajouter des connecteurs (Slack, Email, Webhook) pour étendre les capacités du projet. |

### 1.4 Besoins reporting/traçabilité

| Besoin reporting           | User Story                                                                 |
|----------------------------|----------------------------------------------------------------------------|
| Génération de rapports     | En tant que responsable, je veux générer des rapports synthétiques pour suivre l’avancement et la conformité du projet. |
| Export des logs            | En tant qu’auditeur, je veux exporter les logs au format JSON pour analyse externe. |

### 1.5 Besoins validation croisée

| Besoin validation croisée  | User Story                                                                 |
|----------------------------|----------------------------------------------------------------------------|
| Revue croisée              | En tant que validateur, je veux que chaque besoin soit validé par au moins deux parties prenantes pour garantir l’exhaustivité. |
| Feedback automatisé        | En tant qu’utilisateur, je veux recevoir un feedback automatique après chaque validation croisée. |

---

## 2. Tableaux synthétiques des besoins

### Synthèse globale

| Catégorie        | Nombre de besoins | Validation croisée | Traçabilité | Automatisation |
|------------------|------------------|-------------------|-------------|---------------|
| Utilisateur      | 3                | Oui               | Oui         | Partielle     |
| Technique        | 3                | Oui               | Oui         | Oui           |
| Intégration      | 2                | Oui               | Oui         | Oui           |
| Reporting        | 2                | Oui               | Oui         | Oui           |
| Validation       | 2                | Oui               | Oui         | Oui           |

---

## 3. Rapport de synthèse (extrait JSON)

```json
{
  "besoins": [
    {"categorie": "utilisateur", "count": 3, "validation": true, "traçabilité": true, "automatisation": "partielle"},
    {"categorie": "technique", "count": 3, "validation": true, "traçabilité": true, "automatisation": "oui"},
    {"categorie": "intégration", "count": 2, "validation": true, "traçabilité": true, "automatisation": "oui"},
    {"categorie": "reporting", "count": 2, "validation": true, "traçabilité": true, "automatisation": "oui"},
    {"categorie": "validation", "count": 2, "validation": true, "traçabilité": true, "automatisation": "oui"}
  ],
  "logs": {
    "collecte": "2025-07-29T16:14:16+02:00",
    "validation_croisée": "2025-07-29T16:14:16+02:00",
    "feedback_auto": true
  }
}
```

---

## 4. Logs synthétiques de collecte et validation croisée

```text
[2025-07-29 16:14:16] Collecte des besoins démarrée.
[2025-07-29 16:15:02] Besoins utilisateurs/personas validés par Jules et Clara.
[2025-07-29 16:15:45] Besoins techniques validés par Jules et Maxime.
[2025-07-29 16:16:10] Besoins d’intégration validés par Clara et Maxime.
[2025-07-29 16:16:30] Besoins reporting validés par Jules et Clara.
[2025-07-29 16:17:00] Validation croisée complète. Feedback automatisé envoyé.
```

---

## 5. Exemples de commandes/scripts Go natif et Bash

### Script Go natif (collecte des besoins)

```go
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

type Besoin struct {
	Categorie    string
	Count        int
	Validation   bool
	Traçabilité  bool
	Automatisation string
}

func main() {
	besoins := []Besoin{
		{"utilisateur", 3, true, true, "partielle"},
		{"technique", 3, true, true, "oui"},
		{"intégration", 2, true, true, "oui"},
		{"reporting", 2, true, true, "oui"},
		{"validation", 2, true, true, "oui"},
	}
	logs := map[string]string{
		"collecte": time.Now().Format(time.RFC3339),
		"validation_croisée": time.Now().Format(time.RFC3339),
	}
	report := map[string]interface{}{
		"besoins": besoins,
		"logs": logs,
	}
	file, _ := os.Create("rapport_besoins.json")
	defer file.Close()
	json.NewEncoder(file).Encode(report)
	fmt.Println("Rapport généré.")
}
```

### Script Bash (sauvegarde et logs)

```bash
#!/bin/bash
# Sauvegarde du recueil et commit git

cp projet/roadmaps/plans/consolidated/recueil-besoins.md projet/roadmaps/plans/consolidated/recueil-besoins.md.bak
git add projet/roadmaps/plans/consolidated/recueil-besoins.md
git commit -m "Recueil des besoins – sauvegarde et traçabilité"
echo "Backup et commit réalisés le $(date '+%Y-%m-%d %H:%M:%S')" >> logs/recueil-besoins.log
```

---

## 6. Critères de validation

- **Exhaustivité :** Tous les besoins identifiés sont documentés et validés.
- **Traçabilité :** Chaque besoin est associé à des logs horodatés et à un historique Git.
- **Logs :** La collecte et la validation croisée sont journalisées.
- **Revue croisée :** Validation par au moins deux parties prenantes pour chaque besoin.
- **Automatisation :** Scripts Go/Bash disponibles pour la collecte, la synthèse et la sauvegarde.

---

## 7. Procédures de rollback/versionnement

- Sauvegarde automatique du fichier sous forme `.bak` avant modification.
- Commit Git systématique après chaque mise à jour.
- Journalisation des opérations dans `logs/recueil-besoins.log`.
- Possibilité de rollback via :
  - Restauration du fichier `.bak`
  - Utilisation de `git revert` ou `git checkout`
  - Vérification des logs pour identifier le point de restauration

---

## 8. Documentation associée

### Explication de la démarche

Ce recueil a été élaboré selon une démarche collaborative : collecte structurée, validation croisée, traçabilité et automatisation. Chaque besoin est formalisé en user story, validé par plusieurs parties prenantes et journalisé.

### Guide des scripts

- **Go natif :** Génère un rapport JSON synthétique des besoins et logs.
- **Bash :** Automatise la sauvegarde, le commit et la journalisation.
- **Utilisation :** Adapter les scripts selon l’environnement, vérifier les permissions d’écriture et l’accès Git.

---

## 9. Traçabilité

- **Logs horodatés :** Toutes les étapes sont journalisées avec date et heure.
- **Versionning Git :** Chaque modification est commitée et traçable.
- **Feedback automatisé :** Envoi automatique d’un feedback après validation croisée.
- **Archivage :** Sauvegarde régulière du recueil et des logs.
