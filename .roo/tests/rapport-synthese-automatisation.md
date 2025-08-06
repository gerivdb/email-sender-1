# Rapport synthétique d’automatisation Roo-Code

## 1. Tableau de couverture et heatmap

| Mode / Compétence | write_file | read_file | cmd/cli | PluginInterface | API HTTP/REST | ... |
|-------------------|:----------:|:---------:|:------:|:--------------:|:-------------:|:---:|
| Code              | ✅ [preuve](proofs/code/write_file/) | ✅ [preuve](proofs/code/read_file/) | ✅ [preuve](proofs/code/cmd/) | ✅ [preuve](proofs/code/plugin/) | ✅ [preuve](proofs/code/api/) | ... |
| Architect         | ✅ [preuve](proofs/architect/write_file/) | ✅ [preuve](proofs/architect/read_file/) | ❌ | ✅ [preuve](proofs/architect/plugin/) | ❌ | ... |
| Debug             | ✅ [preuve](proofs/debug/write_file/) | ✅ [preuve](proofs/debug/read_file/) | ✅ [preuve](proofs/debug/cmd/) | ✅ [preuve](proofs/debug/plugin/) | ❌ | ... |
| Documentation     | ✅ [preuve](proofs/documentation/write_file/) | ✅ [preuve](proofs/documentation/read_file/) | ❌ | ✅ [preuve](proofs/documentation/plugin/) | ❌ | ... |
| ...               | ...        | ...       | ...    | ...            | ...           | ... |

**Légende** :  
✅ = test automatisé réussi (preuve disponible)  
❌ = compétence non disponible ou non testée  
[preuve] = lien vers le dossier de preuve physique (fichier, log, artefact)

## 2. Diagramme Mermaid du workflow SOTA d’automatisation

```mermaid
flowchart TD
    A[Inventaire dynamique des modes et compétences] --> B[Génération des scénarios de test harmonisés]
    B --> C[Exécution automatisée des tests pour chaque mode/compétence]
    C --> D[Collecte et centralisation des preuves physiques]
    D --> E[Génération du rapport synthétique (tableau, heatmap, liens)]
    E --> F[Validation utilisateur et itération]
```

## 3. Liens et structure de preuve

- Toutes les preuves sont centralisées dans : `.roo/tests/proofs/[mode]/[competence]/`
- Chaque dossier contient : artefact de test, log, mini-rapport Markdown
- La structure est harmonisée pour faciliter l’audit et la traçabilité

## 4. Synthèse et prochaines étapes

- Couverture exhaustive des modes Roo-Code et de leurs compétences/outils
- Preuves physiques systématiques pour chaque scénario
- Rapport synthétique prêt pour audit, CI/CD ou documentation externe
