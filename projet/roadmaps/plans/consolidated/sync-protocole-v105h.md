# Protocole de synchronisation initial – Migration d’un mode custom Roo vers Kilo Code

## Objectif

Définir un protocole de test pour la migration d’un mode custom Roo (ex : Project Research, Documentation Writer, Mode Writer) vers Kilo Code, qui ne possède pas de modes custom. Ce protocole vise à valider la faisabilité et la robustesse de la synchronisation à petite échelle.

---

## Pré-requis

- Inventaire des modes custom Roo à migrer (nom, rôle, dépendances).
- Accès aux sources et configurations des deux environnements (Roo Code, Kilo Code).
- Outils de suivi des modifications (versioning, logs).
- Procédure de rollback documentée.

---

## Étapes du protocole

1. **Sélection du mode à migrer**
   - Choisir un mode custom Roo simple (ex : Documentation Writer).
   - Documenter ses fonctionnalités et points d’intégration.

2. **Analyse de compatibilité**
   - Vérifier la structure des modes Roo vs Kilo Code.
   - Identifier les écarts (API, hooks, gestion d’état).

3. **Préparation de l’environnement de test**
   - Cloner les deux environnements dans des espaces isolés.
   - Activer le suivi des modifications (commit, logs).

4. **Migration manuelle du mode**
   - Reproduire la logique du mode Roo dans Kilo Code (sans automatisation).
   - Adapter les points d’intégration si nécessaire.

5. **Points de contrôle intermédiaires**
   - Vérifier à chaque étape : intégrité du code, absence de conflits, non-interférence avec les modes natifs Kilo Code.
   - Documenter les écarts et adaptations.

6. **Validation**
   - Tester le mode migré dans Kilo Code (fonctionnalités, transitions, logs).
   - Comparer le comportement avec Roo Code.

7. **Rollback**
   - Si échec ou conflit majeur, restaurer l’état initial via la procédure de rollback.
   - Documenter la cause et les actions correctives.

---

## Points de vigilance et risques

- **Conflits de structure** : différences d’architecture entre modes Roo et Kilo Code.
- **Compatibilité API** : absence de points d’extension dans Kilo Code.
- **Non-interférence** : risque d’impact sur les modes natifs ou le fonctionnement global.
- **Perte de fonctionnalités** : certains hooks ou comportements Roo peuvent ne pas être transposables.
- **Rollback incomplet** : s’assurer que la restauration de l’état initial est fiable.

---

## Validation finale

- Le protocole est validé si le mode migré fonctionne dans Kilo Code sans conflit, avec traçabilité complète et possibilité de rollback.
- Les écarts et adaptations sont documentés pour préparer une migration à plus grande échelle.
