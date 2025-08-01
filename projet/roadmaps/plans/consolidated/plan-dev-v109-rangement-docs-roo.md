# Plan de développement v109 — Rangement documentaire Roo-Code

## Objectif

Structurer et optimiser le dossier `.github/docs/vsix/roo-code` pour garantir :  
- Clarté et modularité documentaire  
- Traçabilité des outils/actions  
- Facilité d’onboarding et de contribution  
- Alignement avec les standards Roo-Code

---

## 1. Analyse du contexte et des besoins

- Dossier actuel : guides, outils, prompts, configs, actions mélangés.
- Besoin : séparation stricte par usage, centralisation des outils, documentation croisée.
- Références : [`tools-registry.md`](../../../../.roo/rules/tools-registry.md), [`rules-documentation.md`](../../../../.roo/rules/rules-documentation.md), [`plan-dev-v107-rules-roo.md`](plan-dev-v107-rules-roo.md:1).

---

## 2. Contraintes et dépendances

- Respect des conventions Roo-Code (modularité, nomenclature, liens croisés).
- Mise à jour du registre central [`tools-registry.md`](../../../../.roo/rules/tools-registry.md:1) à chaque ajout/modification d’outil.
- Maintien d’un `README.md` racine synthétique.
- Conservation de l’historique documentaire (`CHANGELOG.md`).

---

## 3. Structuration cible (arborescence)

```
.github/docs/vsix/roo-code/
│
├── README.md
├── CHANGELOG.md
├── tools-registry.md
├── guides/
│   └── (guides pratiques, FAQ, conseils)
├── tools/
│   └── (fiches détaillées outils/actions Roo)
├── actions/
│   └── (modèles d’actions, prompts, templates)
├── config/
│   └── (fichiers de configuration documentaire)
└── prompts/
    └── (prompts spécialisés, modèles avancés)
```

---

## 4. Étapes séquencées

1. **Inventaire initial**
   - Lister tous les fichiers et sous-dossiers existants dans `.github/docs/vsix/roo-code`.
   - Identifier la typologie de chaque fichier (guide, outil, config, prompt…).

2. **Préparation des sous-dossiers**
   - Créer les sous-dossiers : `guides/`, `tools/`, `actions/`, `config/`, `prompts/` si absents.
   - Créer/mettre à jour `README.md` et `CHANGELOG.md` à la racine.

3. **Rangement thématique**
   - Déplacer chaque fichier dans le sous-dossier approprié selon sa typologie :
     - Guides → `guides/`
     - Fiches outils/actions → `tools/`
     - Prompts et modèles d’action → `actions/` ou `prompts/`
     - Configurations → `config/`
   - Mettre à jour les liens internes et index dans `README.md`.

4. **Centralisation et documentation croisée**
   - Ajouter un lien vers [`tools-registry.md`](../../../../.roo/rules/tools-registry.md:1) dans chaque fiche outil/action.
   - Mettre à jour le registre central à chaque ajout/modification.

5. **Validation collaborative**
   - Relire la structure avec les parties prenantes.
   - Recueillir les retours et ajuster si besoin.

6. **Export et intégration**
   - Exporter la structure validée dans la roadmap documentaire.
   - Synchroniser avec les outils de suivi (ex : RoadmapManager).

---

## 5. Critères d’acceptation

- Arborescence conforme à la structuration cible.
- Tous les fichiers rangés dans le bon sous-dossier.
- Registre central à jour et liens croisés présents.
- Documentation claire, indexée, facilement navigable.
- Validation collaborative documentée.

---

## 6. Cas limites / exceptions

- Fichiers hybrides (multi-usages) : privilégier le dossier principal, ajouter des liens croisés.
- Fichiers orphelins : signaler et proposer une intégration ou suppression.
- Conflit de typologie : arbitrer en réunion documentaire.

---

## 7. Suivi et évolutivité

- Mettre à jour ce plan à chaque évolution documentaire majeure.
- Documenter toute exception ou adaptation dans le `CHANGELOG.md`.
- Synchroniser la structure avec les autres référentiels Roo (AGENTS.md, workflows-matrix.md…).

---

## 8. Liens utiles

- [tools-registry.md](../../../../.roo/rules/tools-registry.md)
- [rules-documentation.md](../../../../.roo/rules/rules-documentation.md)
- [plan-dev-v107-rules-roo.md](plan-dev-v107-rules-roo.md)
- [workflows-matrix.md](../../../../.roo/rules/workflows-matrix.md)

---

*Plan généré selon les standards Roo-Code, prêt pour validation collaborative et intégration roadmap.*