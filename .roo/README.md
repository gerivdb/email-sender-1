# Dossier `.roo` – Structure documentaire Roo-Code

Ce dossier centralise **toutes les règles, outils, statuts et scripts** nécessaires à la gouvernance documentaire du projet Roo-Code.

## 📚 Rôle et usage

- Point d’entrée pour la validation, la maintenance et l’extension documentaire.
- Référence unique pour les standards, workflows, plugins et outils internes.
- Support des modes Roo-Code (ex : `plandev-engineer`, orchestrator, debug…).

## 🗂️ Structure du dossier

- **rules/** : Règles transverses, standards, conventions ([`rules.md`](rules/rules.md))
- **rules-plandev-engineer/** : Spécifications et workflow du mode PlanDev Engineer ([`plandev-engineer-reference.md`](rules-plandev-engineer/plandev-engineer-reference.md))
- **overrides/** : Prompts système personnalisés par mode
- **config/** : Fichiers de configuration documentaire
- **scripts/** : Scripts d’automatisation et de maintenance
- **tools/** : Outils CLI, validateurs, générateurs, documentation technique
- **tests/** : Jeux de tests et scénarios d’écriture
- **roo-structure-status.json** : Statut exhaustif de la structure documentaire (généré automatiquement)
- **personas.md** : Personas et profils utilisateurs du projet

## 🔗 Liens utiles

- [AGENTS.md](../AGENTS.md) : Liste centrale des managers et interfaces Roo
- [Guide d’organisation des règles](rules/README.md)
- [Registre des outils Roo](rules/tools-registry.md)
- [Matrice des workflows Roo](rules/workflows-matrix.md)
- [Plan de migration Roo-Code](plan-migration-roo-code.md)

## 🛠️ Conventions Roo-Code

- **Traçabilité** : Toute évolution doit être reflétée dans [`roo-structure-status.json`](roo-structure-status.json)
- **Validation** : Respecter les standards décrits dans [`rules.md`](rules/rules.md)
- **Extension** : Ajouter de nouveaux modes ou plugins via PluginInterface et documenter dans le registre

## 🤝 Contribution

- Toute modification doit respecter la structure et les conventions Roo-Code.
- Documenter les ajouts dans le présent README et dans les fichiers de référence concernés.
- Utiliser les outils de validation et de test présents dans `tools/` et `scripts/`.

---

## 📑 Inventaire dynamique des modes Roo

L’inventaire des modes Roo-Code est généré automatiquement pour garantir la traçabilité, la cohérence et la maintenabilité documentaire.

### Principe de génération automatique

- L’inventaire des modes Roo est produit par le script [`scripts/generate-modes-inventory.ts`](../scripts/generate-modes-inventory.ts:1).
- Ce script analyse la configuration et les fichiers de modes, puis génère :
  - Un inventaire **Markdown** : [`modes-inventory.md`](modes-inventory.md)
  - Un inventaire **JSON** : [`modes-inventory.json`](modes-inventory.json)
- Les fichiers générés sont placés à la racine du dossier `.roo/` pour une consultation et une intégration faciles dans la documentation centrale.

### Workflow d’ajout ou de recensement d’un mode Roo

1. **Déclarer le nouveau mode** dans la configuration ou le répertoire approprié selon les conventions Roo-Code.
2. **Documenter** le mode (fiche, spécificités, overrides) dans les fichiers de règles concernés.
3. **Exécuter le script** [`scripts/generate-modes-inventory.ts`](../scripts/generate-modes-inventory.ts:1) pour régénérer l’inventaire :
   - En ligne de commande :
     ```bash
     node scripts/generate-modes-inventory.ts
     ```
4. **Valider** la génération des fichiers [`modes-inventory.md`](modes-inventory.md) et [`modes-inventory.json`](modes-inventory.json).
5. **Intégrer** les liens ou extraits dans la documentation centrale si nécessaire.

### Liens directs vers les inventaires générés

- 📄 [Inventaire Markdown des modes Roo](modes-inventory.md)
- 🗂️ [Inventaire JSON des modes Roo](modes-inventory.json)

> **À noter** : Toute évolution des modes doit être suivie d’une régénération de l’inventaire pour garantir la cohérence documentaire.

*Pour toute question, consulter la documentation centrale du projet ou contacter l’équipe documentaire Roo.*

## 🚦 Restrictions par mode Roo-Code

Cette section synthétise, pour chaque mode Roo, les restrictions, exceptions et points d’extension :  
Consultez les fiches détaillées et le [registre des outils Roo](rules/tools-registry.md) pour les règles complètes.

| Mode | Restrictions | Exceptions | Points d’extension |
|------|--------------|------------|--------------------|
| **Ask** | Accès limité aux outils système, pas d’édition de fichiers | Peut consulter la documentation centrale | Extension via navigation web limitée |
| **Code** | Édition, création et suppression de code source, accès aux outils CLI | Peut manipuler tout type de fichier sauf restrictions système | Extension via PluginInterface, outils CLI |
| **Architect** | Édition uniquement des fichiers Markdown (.md) | Peut générer des todo lists séquencées | Extension via documentation, prompts personnalisés |
| **Debug** | Accès aux outils de diagnostic, édition limitée aux fichiers de debug | Peut utiliser les outils de log et monitoring | Extension via ErrorManager, outils de test |
| **Orchestrator** | Coordination multi-modes, pas d’accès direct à l’édition de fichiers | Peut déléguer des tâches à d’autres modes | Extension via workflows, plugins |
| **Project Research** | Lecture, analyse, onboarding, accès aux outils système | Peut consulter l’ensemble de la documentation | Extension via API externes, navigation web |
| **Documentation Writer** | Édition et création de documentation, accès restreint aux outils système | Peut enrichir la documentation centrale | Extension via modèles, prompts |
| **Mode Writer** | Création et modification de modes personnalisés | Peut éditer tous les fichiers de mode | Extension via PluginInterface, prompts |
| **User Story Creator** | Création de user stories, édition de fichiers de spécification | Peut structurer les besoins fonctionnels | Extension via modèles, prompts |
| **PlanDev Engineer** | Accès complet à tous les fichiers et dossiers, sans restriction d’extension | Peut générer, déplacer, supprimer tout type de fichier | Extension via PluginInterface, export roadmap |
| **DevOps** | Édition des fichiers CI/CD, scripts, manifestes d’infrastructure | Peut documenter et automatiser les procédures critiques | Extension via outils CLI, monitoring |

> Pour les restrictions détaillées par outil, consultez le [registre des outils Roo](rules/tools-registry.md) et les fiches modes dans [`rules.md`](rules/rules.md).

---