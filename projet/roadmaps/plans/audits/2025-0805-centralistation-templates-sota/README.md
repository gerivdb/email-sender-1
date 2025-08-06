# Centralisation SOTA des templates – Projet 2025-0805-centralistation-templates-sota

## Objectif

Fournir un référentiel SOTA pour la centralisation, la gouvernance et l’harmonisation des templates de projet/documentation dans l’écosystème Roo-Code, en privilégiant le dossier `development/templates/` comme socle unique.

---

## Pourquoi centraliser ?

- **Éviter la divergence documentaire** : un seul point d’entrée pour tous les templates, quelle que soit l’équipe ou le domaine.
- **Assurer la cohérence** : chaque nouveau projet, roadmap, ou manager hérite d’une structure validée, maintenable et évolutive.
- **Faciliter l’automatisation** : scripts CLI, générateurs (Hygen, Go, PowerShell) et pipelines CI/CD peuvent pointer vers un socle unique.
- **Accélérer l’onboarding** : tout nouveau projet démarre avec la même qualité documentaire et structurelle.

---

## Emplacement SOTA

- **Dossier de référence** :  
  `development/templates/`
- **Organisation recommandée** :  
  - Par type de livrable (roadmap, journal, erreur, doc, etc.)
  - Par domaine si besoin (ex : `development/templates/roadmap/`, `development/templates/manager/`…)

---

## Bonnes pratiques d’utilisation

1. **Génération** :  
   Utiliser un script CLI ou Hygen pour initialiser tout nouveau projet à partir du template central.
2. **Validation** :  
   Les pipelines CI/CD doivent vérifier la conformité de chaque projet avec le template (sections obligatoires, structure, etc.).
3. **Évolution** :  
   Toute modification du template doit passer par une PR dédiée, revue croisée, et validation collective.
4. **Documentation** :  
   Chaque template doit inclure un README d’usage, une checklist de complétude, et des exemples d’intégration.
5. **Cluster projets** :  
   Tous les projets (même à l’état de brouillon) doivent être créés dans un cluster dédié, généré depuis le template central.

---

## Structure minimale recommandée pour un projet d’audit/template

```
projet/roadmaps/plans/audits/2025-0805-centralistation-templates-sota/
├── README.md
├── context/
│   └── contexte-projet.md
├── synthesis/
│   └── executive-summary.md
├── implementation/
│   └── technical-specifications.md
├── validation/
│   └── checklist-completude.md
```

---

## Checklist de conformité

- [x] Utilisation du template central `development/templates/`
- [x] README explicite et à jour
- [x] Dossiers context, synthesis, implementation, validation présents
- [ ] Checklist de complétude documentaire remplie
- [ ] Synchronisation régulière avec le template central

---

## Références croisées

- [plan-dev-v79-roadmap-template.md](../consolidated/plan-dev-v79-roadmap-template.md)
- [plan-dev-v4-base-connaissances.md](../consolidated/plan-dev-v4-base-connaissances.md)
- [plan-dev-v81-no-duplication-standards.md](../consolidated/plan-dev-v81-no-duplication-standards.md)
- [README Roo-Code](../../../.roo/rules/README.md)