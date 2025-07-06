# Procédure de revue croisée automatisée des rapports d’audit

## Objectif
Garantir la validation humaine et la traçabilité des audits générés automatiquement.

---

## Étapes

1. **Collecte automatique des rapports**
   - Script : `bash development/managers/audit-tools/collect_audit_reports.sh`
   - Livrable : tous les rapports `.md` dans `projet/roadmaps/audit-reports/`

2. **Notification automatique à l’équipe**
   - Script/commande : 
     - En local : `echo "Nouveaux rapports d’audit disponibles" | mail -s "Audit Reports" team@example.com`
     - En CI/CD : job de notification (Slack, email, GitHub comment)

3. **Attribution des rapports à relire**
   - Méthode : assignation manuelle ou script d’attribution (ex : round-robin)
   - Livrable : tableau d’attribution (Markdown ou CSV)

4. **Validation croisée**
   - Action : chaque reviewer lit le rapport, coche la case dans le tableau, ajoute un commentaire ou ouvre une issue si besoin
   - Livrable : tableau de validation (Markdown), issues ouvertes si anomalies

5. **Archivage et traçabilité**
   - Script : copie des rapports validés dans un dossier `audit-reports/validated/`
   - Commande : `cp rapport.md audit-reports/validated/`
   - Historique : suivi via git

---

## Exemple de tableau de validation

| Rapport                  | Reviewer      | Statut   | Commentaire / Issue |
|--------------------------|--------------|----------|---------------------|
| audit_inventory.md       | Alice        | [ ]      |                     |
| standards_inventory.md   | Bob          | [ ]      |                     |
| audit_gap_report.md      | Charlie      | [ ]      |                     |
| duplication_report.md    | Alice        | [ ]      |                     |

---

## Critères de validation

- Rapport lu et compris
- Pas d’anomalie majeure détectée
- Feedback ajouté si besoin
- Case cochée dans le tableau

---

## Traçabilité

- Historique des validations dans le tableau
- Issues ouvertes pour chaque anomalie
- Archivage des rapports validés
