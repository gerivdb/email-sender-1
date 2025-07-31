# Règles de diagnostic et débogage Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les méthodologies, checklists et bonnes pratiques pour le diagnostic et la résolution des problèmes dans le projet Roo-Code.

---

## 1. Checklist de débogage

- [ ] Identifier le contexte et les conditions d’apparition du bug.
- [ ] Vérifier les logs et les métriques associées.
- [ ] Isoler le composant ou le manager concerné.
- [ ] Reproduire le problème avec des données minimales.
- [ ] Tester les hypothèses une à une.
- [ ] Documenter les solutions tentées et leurs effets.
- [ ] Valider la correction par des tests unitaires ou d’intégration.
- [ ] Mettre à jour la documentation si nécessaire.

---

## 2. Outils et conventions

- Utiliser les outils de log et de monitoring du projet (MonitoringManager, ErrorManager).
- Centraliser les rapports d’incident et les solutions dans `.github/docs/incidents/` ou équivalent.
- Ajouter des exemples de scénarios d’erreur et de résolution dans la documentation centrale.

---