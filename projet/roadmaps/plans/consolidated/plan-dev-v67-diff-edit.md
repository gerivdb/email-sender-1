# Plan de Développement v67 - Intégration de la méthode diff Edit (Cline)

## Objectif

Mettre en place une méthode de modification ciblée et robuste des fichiers (markdown, code, config) basée sur le principe diff Edit : patch SEARCH/REPLACE appliqué directement sur le fichier, pour fiabiliser et accélérer les modifications, même en solo.

---

## 1. Analyse et Spécifications

- [x] Recenser les cas d’usage : checklist, code, doc, config, batch multi-fichiers.
- [x] Définir le format standardisé des blocs diff Edit (SEARCH/REPLACE).
- [x] Identifier les contraintes d’encodage, de format, et de compatibilité (UTF-8, CRLF/LF, etc.).

---

## Exemples concrets de bloc diff Edit

### Exemple simple (Markdown)

Avant :

```markdown
# Titre
Ancien contenu à remplacer.
```

Bloc diff Edit :

```
------- SEARCH
Ancien contenu à remplacer.
=======
Nouveau contenu inséré par diff Edit.
+++++++ REPLACE
```

Après application :

```markdown
# Titre
Nouveau contenu inséré par diff Edit.
```

### Exemple avec contexte (code Go)

Avant :

```go
func Addition(a, b int) int {
    return a + b // ancienne implémentation
}
```

Bloc diff Edit :

```
------- SEARCH
return a + b // ancienne implémentation
=======
return a + b // nouvelle implémentation diff Edit
+++++++ REPLACE
```

---

## 2. Prototype CLI/Script

- [ ] Écrire un script Python/Node.js minimal :
  - [ ] Lecture du fichier cible.
  - [ ] Recherche du bloc SEARCH exact.
  - [ ] Remplacement par le bloc REPLACE si correspondance stricte.
  - [ ] Gestion des erreurs (SEARCH non trouvé, encodage, etc.).
  - [ ] Log des modifications appliquées.
  - [ ] Option `--dry-run` pour prévisualiser le diff sans appliquer la modification.
  - [ ] Génération automatique d’un backup avant modification.
- [ ] Tester sur un fichier markdown réel (ex : plan v65B).

---

## 3. Intégration VS Code (optionnel)

- [ ] Créer un snippet ou une commande personnalisée pour générer le squelette diff Edit depuis la sélection.
- [ ] (Avancé) Développer une extension VS Code ou un script externe pour automatiser l’application du patch.
- [ ] Fournir un exemple de snippet prêt à l’emploi :

```json
{
  "Diff Edit Block": {
    "prefix": "diffedit",
    "body": [
      "------- SEARCH",
      "$TM_SELECTED_TEXT",
      "=======",
      "${1:Texte de remplacement}",
      "+++++++ REPLACE"
    ],
    "description": "Bloc diff Edit pour patch ciblé"
  }
}
```

---

## 4. Workflow et Validation

- [ ] Définir la procédure d’utilisation :
  - [ ] Génération du bloc diff Edit (snippet/script).
  - [ ] Application du patch (script CLI ou extension).
  - [ ] Validation du diff dans Git/VS Code avant commit.
- [ ] Documenter les bonnes pratiques (contexte, rollback, logs).
- [ ] Ajouter une checklist avant application :
  - [ ] Vérifier que le bloc SEARCH est unique dans le fichier.
  - [ ] Vérifier l’encodage du fichier (UTF-8 sans BOM recommandé).
  - [ ] Faire un backup du fichier cible.
  - [ ] Inclure 1-2 lignes de contexte avant/après dans le bloc SEARCH si possible.

---

## 5. Automatisation et Sécurité

- [ ] Ajouter une option de prévisualisation du diff avant application (`--dry-run`).
- [ ] Implémenter un mode rollback/undo (restauration du backup ou patch inverse).
- [ ] (Avancé) Support multi-fichiers et batch.
- [ ] Log détaillé (avant/après, timestamp, user).

---

## 6. Documentation et Partage

- [ ] Rédiger un README détaillé (usage, exemples, limitations, rollback).
- [ ] Ajouter des exemples concrets (avant/après, markdown, code Go, etc.).
- [ ] Préparer un template de prompt diff Edit pour usage quotidien.
- [ ] Ajouter un tableau de cas d’usage :

| Type de fichier      | Exemple SEARCH           | Exemple REPLACE                | Remarque                        |
|----------------------|-------------------------|--------------------------------|---------------------------------|
| Markdown             | Ancien contenu          | Nouveau contenu                | Simple remplacement             |
| Code Go              | return a + b            | return a + b // modifié        | Avec contexte                   |
| Config JSON          | "key": "old"            | "key": "new"                   | Attention aux espaces           |
| Batch multi-fichiers | Bloc commun dans plusieurs fichiers | Bloc modifié         | Gérer les erreurs partielles    |

---

## Pièges et limites connus

- Bloc SEARCH non unique dans le fichier (risque de remplacer la mauvaise occurrence)
- Encodage : attention à l’UTF-8 BOM, CRLF/LF (Windows/Linux)
- Fichiers binaires ou très volumineux : non supportés ou à manipuler avec précaution
- Conflits d’équipe : plusieurs diff Edit appliqués en parallèle sur le même fichier
- Plugins VS Code ou auto-formatters pouvant modifier le contenu entre génération et application du patch

---

## Mode dry-run et rollback

- Ajouter une option `--dry-run` au script pour prévisualiser le diff sans appliquer la modification
- Toujours générer un backup du fichier avant modification pour permettre un rollback facile
- Documenter comment restaurer le fichier (backup, patch inverse, Git)

---

## Intégration CI/CD

- Intégrer le script diff Edit dans la pipeline CI pour valider automatiquement les patchs
- Ajouter une étape de validation du diff (dry-run) avant merge
- Automatiser le rollback en cas d’échec

---

## Gestion des conflits en équipe

- Travailler sur des branches distinctes pour chaque diff Edit
- Instaurer une convention de verrouillage ou de notification lors de l’édition d’un fichier critique
- Toujours valider le diff dans Git/VS Code avant merge
- Utiliser des hooks ou scripts pour détecter les conflits potentiels avant application

---

## 7. Automatisation complète et activation zéro-intervention

- [x] Vérifier que le hook Git `pre-commit-diffedit.sh` est bien activé (`.git/hooks/pre-commit`).
- [x] S’assurer que les tâches VS Code sont bindées à des raccourcis ou à l’enregistrement de fichiers.
- [x] Intégrer le script diffedit dans la CI pour appliquer/valider les patchs à chaque push ou PR.
- [x] Fournir un script d’installation automatique pour activer tous les outils d’un coup.
- [x] Ajouter un check de conformité de l’automatisation sur le repo.
- [x] Générer un rapport d’état de l’automatisation (ce qui reste à activer).

---

## 8. Optimisation des ressources et intégration avec les managers système

- [x] Optimiser l’utilisation des processus, du processeur, de la mémoire et du cache lors de l’application des diff Edit.
- [x] Collaborer avec les managers responsables (process manager, memory manager, cache manager, etc.) pour garantir performance et robustesse.
- [x] Monitorer l’impact sur les ressources système lors de batchs ou de gros patchs.
- [x] Adapter dynamiquement le comportement du script selon la charge système (ex : throttling, gestion de files d’attente).
- [x] Documenter les points d’intégration avec l’écosystème de managers.

---

## 9. Structure et évolutivité du plan

- [x] Structurer le plan pour faciliter l’ajout de nouveaux modules (ex : support d’autres formats, intégration avec d’autres outils d’automatisation).
  - Voir la section "Modules et extensions" et le fichier `MODULES_EXTENSIONS.md` pour la procédure d’ajout, le template, et les exemples.
- [x] Prévoir une section “FAQ / Problèmes fréquents” pour centraliser les retours d’expérience.
  - Voir le fichier `FAQ_PROBLEMES.md` pour la centralisation des problèmes courants et solutions.
- [ ] Mettre à jour régulièrement la documentation selon les retours d’usage et l’évolution des outils.
  - Utiliser le script Go `go/update_doc.go` pour générer l’historique des mises à jour.
  - Ajouter toute évolution dans les fichiers concernés et référencer dans le changelog.

---

## 10. Optimisation parsing & diff-edit pour gros fichiers (2500+ lignes)

- [ ] Générer automatiquement un index des sections/titres pour navigation rapide (table des matières dynamique, liens internes).
- [ ] Utiliser un parseur qui construit un arbre de sections pour accélérer les recherches et modifications ciblées.
- [ ] Découper les plans très longs en modules/fichiers thématiques et automatiser l’assemblage final.
- [ ] Appliquer diff-edit sur des sous-ensembles pour limiter la charge mémoire et accélérer les patchs.
- [ ] Utiliser des expressions régulières ou des parseurs structurés pour cibler précisément les blocs à modifier.
- [ ] Ajouter un mode “fuzzy” ou tolérant pour les blocs SEARCH (gestion des espaces, indentation, variantes).
- [ ] Lire et traiter les fichiers volumineux en streaming (ligne par ligne ou bloc par bloc) pour limiter la consommation mémoire.
- [ ] Appliquer les patchs en pipeline (lecture, modification, écriture sans tout charger en RAM).
- [ ] Mettre en cache les index, positions des blocs, ou résultats de parsing pour accélérer les opérations répétées.
- [ ] Utiliser un cache partagé avec les managers pour éviter les re-parsings inutiles.
- [ ] Logger précisément les temps de parsing, d’application de patch, et les éventuels ralentissements.
- [ ] Intégrer des alertes si un patch ou un parsing dépasse un seuil de temps ou de ressources.
- [ ] Paralléliser le parsing et l’application des patchs sur différentes sections/fichiers.
- [ ] Utiliser des pools de workers adaptés à la puissance CPU/RAM disponible (feedback du process manager).
- [ ] Simuler l’application de plusieurs patchs en “dry-run” pour détecter les conflits ou les lenteurs avant exécution réelle.
- [ ] Générer un rapport de “diff coverage” pour visualiser l’impact des patchs sur le plan.
- [ ] Exposer des hooks/API pour que les managers système puissent piloter ou monitorer le parsing/patching.
- [ ] Adapter dynamiquement le comportement selon les priorités ou la charge globale de l’écosystème.
- [ ] Proposer une interface de navigation rapide (arborescence, recherche par titre, jump-to-section).
- [ ] Ajouter des outils de visualisation des diff et de l’état d’avancement (progress bar, heatmap des modifications).

---

**Livrables** :

- Script CLI diff Edit prêt à l’emploi
- Snippet/template VS Code
- Documentation d’utilisation et d’intégration
- Exemples réels sur fichiers du projet
- Scripts d’automatisation et de monitoring des ressources

**Bénéfices attendus** :

- Modifications ultra-fiables, traçables, rapides
- Zéro effet de bord, rollback facile
- Compatible solo ou équipe, markdown ou code
- Automatisation complète, monitoring et optimisation des ressources
- Intégration fluide avec l’écosystème de managers système
