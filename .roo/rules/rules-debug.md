# Règles de diagnostic et débogage Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les méthodologies, checklists et bonnes pratiques pour le diagnostic et la résolution des problèmes dans le projet Roo-Code.

---

## 1. Principes généraux

- Toujours commencer par la reproduction du problème dans un environnement contrôlé.
- Documenter chaque étape du diagnostic : symptômes, hypothèses, tests réalisés, résultats.
- Utiliser des logs structurés et centralisés (voir ErrorManager).
- Privilégier la traçabilité et la reproductibilité des scénarios d’erreur.

---

## 2. Checklist de débogage

- [ ] Identifier le contexte et les conditions d’apparition du bug.
- [ ] Vérifier les logs et les métriques associées.
- [ ] Isoler le composant ou le manager concerné.
- [ ] Reproduire le problème avec des données minimales.
- [ ] Tester les hypothèses une à une.
- [ ] Documenter les solutions tentées et leurs effets.
- [ ] Valider la correction par des tests unitaires ou d’intégration.
- [ ] Mettre à jour la documentation si nécessaire.

---

## 3. Outils et conventions

- Utiliser les outils de log et de monitoring du projet (MonitoringManager, ErrorManager).
- Centraliser les rapports d’incident et les solutions dans `.github/docs/incidents/` ou équivalent.
- Ajouter des exemples de scénarios d’erreur et de résolution dans la documentation centrale.

---

## 4. Overrides et modes spécifiques

- Si un mode Roo-Code nécessite une méthodologie de debug particulière (ex : mode debug), ajouter une section dédiée et référencer le prompt système concerné.
- Les prompts système doivent indiquer explicitement les adaptations ou exceptions à ces règles.

---

## 5. Maintenance

- Mettre à jour ce fichier à chaque évolution des outils ou des pratiques de diagnostic.
- Documenter les nouveaux cas d’usage ou outils dans la documentation centrale.

---