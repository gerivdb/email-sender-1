# Plan de gouvernance et synchronisation des personas/modes multi-extensions VSIX

## 1. Contexte

La multiplication des extensions VSIX (Kilo Code, Roomodes, Copilot, Cline, etc.) a conduit à une fragmentation des concepts de persona et de mode, générant des incohérences, des redondances et des difficultés de synchronisation. Plusieurs plans existants abordent partiellement ces enjeux, notamment :

- [`plan-dev-v63-jan-cline-copilot.md`](plan-dev-v63-jan-cline-copilot.md:30) : intégration Cline/Copilot.
- [`plan-dev-v86-meta-roadmap-harmonisation.md`](plan-dev-v86-meta-roadmap-harmonisation.md:51) : harmonisation des roadmaps et des référentiels.
- [`plan-dev-v92-unification-modes-roomodes.md`](plan-dev-v92-unification-modes-roomodes.md:1) : convergence Roomodes/Kilo Code.
- [`plan-dev-v99-gouvernance-modes-personas.md`](plan-dev-v99-gouvernance-modes-personas.md:1) : gouvernance des modes/personas.

## 2. Objectifs

- Unifier la gestion des personas et modes entre toutes les extensions VSIX.
- Garantir la cohérence, la non-redondance et la traçabilité des mappings.
- Permettre la synchronisation automatique et la gouvernance centralisée.
- Fournir un référentiel unique, actionnable et extensible.

## 3. État de l’art

### 3.1. Plans existants

- **Cline/Copilot** : mapping partiel, absence de référentiel central ([`plan-dev-v63-jan-cline-copilot.md`](plan-dev-v63-jan-cline-copilot.md:30)).
- **Harmonisation roadmap** : recommandations de convergence, mais peu d’automatisation ([`plan-dev-v86-meta-roadmap-harmonisation.md`](plan-dev-v86-meta-roadmap-harmonisation.md:51)).
- **Roomodes/Kilo Code** : début de mutualisation des modes, mais gouvernance perfectible ([`plan-dev-v92-unification-modes-roomodes.md`](plan-dev-v92-unification-modes-roomodes.md:1)).
- **Gouvernance modes/personas** : principes de gouvernance, manque d’outillage ([`plan-dev-v99-gouvernance-modes-personas.md`](plan-dev-v99-gouvernance-modes-personas.md:1)).

### 3.2. Limites actuelles

- Multiplicité des sources de vérité.
- Absence de mapping exhaustif et dynamique.
- Synchronisation manuelle, sujette à erreur.
- Difficulté d’extension à de nouvelles extensions ou modes.

## 4. Analyse des besoins

- **Centralisation** : référentiel unique des modes/personas et de leurs équivalences.
- **Traçabilité** : historique des évolutions, liens vers les plans sources.
- **Interopérabilité** : format standard (YAML/JSON), API d’accès.
- **Automatisation** : synchronisation bidirectionnelle, détection des divergences.
- **Gouvernance** : processus de validation, gestion des conflits, documentation.

## 5. Architecture cible

- **Référentiel central** (ex : `personas-modes-mapping.yaml`) versionné.
- **Schemas d’équivalence** entre extensions (ex : Kilo Code ↔ Roomodes ↔ Copilot ↔ Cline).
- **API ou scripts** pour synchronisation et validation.
- **Documentation** intégrée et liens vers les plans existants.

## 6. Workflow de synchronisation

1. **Définition/édition** des modes/personas dans le référentiel central.
2. **Mapping automatique** vers les formats spécifiques de chaque extension.
3. **Validation** des mappings (tests, lint, CI).
4. **Propagation** automatisée vers les extensions concernées.
5. **Audit régulier** des divergences et génération de rapports.

## 7. Mapping d’équivalences (exemple YAML)

```yaml
# personas-modes-mapping.yaml
- canonical: "Orchestrator"
  kilo_code: "Orchestrator"
  roomodes: "Orchestrator"
  copilot: "Orchestrator"
  cline: "Orchestrator"
  description: "Pilote la coordination multi-modes et la synthèse des résultats."
- canonical: "Debug"
  kilo_code: "Debug"
  roomodes: "Debug"
  copilot: "Debugger"
  cline: "Debug"
  description: "Analyse et résolution des bugs complexes."
- canonical: "Documentation Writer"
  kilo_code: "Documentation Writer"
  roomodes: "Documentalist"
  copilot: "DocWriter"
  cline: "Documentation"
  description: "Production et structuration de la documentation technique."
# ...
```

## 8. Gouvernance

- **Comité de gouvernance** multi-extensions (représentants de chaque extension).
- **Processus de proposition/validation** des évolutions (PR, RFC, vote).
- **Historisation** des décisions et des mappings.
- **Audit de cohérence** périodique (outillage automatisé).

## 9. Automatisation

- **Scripts de synchronisation** (ex : Node.js, Python) pour générer/valider les mappings.
- **CI/CD** pour tester la cohérence et propager les changements.
- **Alertes** en cas de divergence ou de conflit détecté.
- **Documentation générée** automatiquement à partir du référentiel YAML.

## 10. Recommandations

- **Adopter le référentiel YAML centralisé** comme source unique de vérité.
- **Automatiser la synchronisation** via scripts et pipelines CI.
- **Documenter chaque mapping** et ses évolutions, avec liens vers les plans sources.
- **Mettre en place un audit régulier** et un processus de gouvernance transparent.
- **Favoriser l’extensibilité** pour intégrer de nouvelles extensions ou modes.

---

## Résumé des actions à engager

- Créer et versionner le référentiel YAML centralisé des modes/personas.
- Mettre en place les scripts de synchronisation et de validation.
- Instaurer un comité de gouvernance multi-extensions.
- Documenter le workflow et les processus de validation.
- Planifier des audits réguliers et automatisés.
- Référencer systématiquement les plans existants et maintenir la traçabilité.