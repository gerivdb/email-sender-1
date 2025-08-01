# Guide d’usage – Outil de déplacement documentaire multifichier Roo Code

## 🚀 Scénarios types

### 1. Migration documentaire massive
- Préparer `file-moves.yaml` avec tous les déplacements à réaliser.
- Lancer le moteur Go ou le script CLI Roo avec l’option `--config file-moves.yaml`.
- Vérifier le rapport généré (`rapport-move-files.md` ou `.json`).

### 2. Simulation (dry-run)
- Activer `dry-run: true` sur les opérations à tester.
- Exécuter le moteur : aucun fichier n’est modifié, mais le rapport est produit.

### 3. Intégration CI/CD
- Ajouter le workflow `.github/workflows/move-files-ci.yml`.
- Déclencher le job sur chaque PR ou push.

## 📝 Pas-à-pas d’utilisation

1. Copier [`file-moves.schema.yaml`](file-moves.schema.yaml) et adapter [`file-moves.yaml`](file-moves.yaml).
2. Ajouter les hooks personnalisés dans [`file-moves.hooks.md`](file-moves.hooks.md) si besoin.
3. Lancer le moteur Go, CLI Roo ou script multiplateforme.
4. Consulter le rapport et la checklist de validation.
5. En cas d’erreur, consulter la section troubleshooting.

## ❓ FAQ

- **Comment ajouter une dépendance ?**  
  Utiliser le champ `dependances` pour spécifier les IDs à exécuter avant.

- **Puis-je annuler une opération ?**  
  Si `rollback.enabled: true`, le moteur tente un retour arrière automatique.

- **Comment valider la conformité ?**  
  Utiliser la checklist [`CHECKLIST.file-moves.md`](CHECKLIST.file-moves.md) et vérifier la conformité au schéma.

## 🛠️ Troubleshooting

- **Erreur de permission** : vérifier les droits sur les fichiers/dossiers.
- **Fichier non trouvé** : contrôler les chemins dans `file-moves.yaml`.
- **Rollback échoué** : consulter les logs détaillés du rapport.

## 🌟 Bonnes pratiques

- Toujours valider la configuration avec le schéma avant exécution.
- Utiliser `dry-run` pour tester sans risque.
- Documenter chaque opération avec des tags et des hooks explicites.
- Centraliser les rapports et logs pour audit.
