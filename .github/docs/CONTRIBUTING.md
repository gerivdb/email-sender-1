# 🤝 Guide de Contribution Documentaire

Ce guide explique comment contribuer efficacement à la documentation de l’écosystème Email Sender.

---

## 1. Processus de contribution

1. Forker le dépôt ou créer une branche dédiée
2. Rédiger ou améliorer la documentation (guides, workflows, intégrations…)
3. Respecter les conventions rédactionnelles et la structure documentaire
4. Ajouter des exemples, schémas, checklists si pertinent
5. Soumettre une Pull Request (PR) détaillée

---

## 2. Checklist de contribution

- [ ] Le guide ou la section modifiée est à jour et cohérente
- [ ] Les exemples sont testés et fonctionnels
- [ ] Les schémas mermaid sont lisibles
- [ ] Les liens internes sont valides
- [ ] La PR inclut un résumé des changements

---

## 3. Validation & revue

- Toute PR est relue par un membre de l’équipe ou un contributeur externe
- Les retours sont intégrés avant merge
- La checklist de couverture documentaire est mise à jour si besoin

---

## 4. Guides d’intégration par profil

- **Développeur** : Suivre les guides techniques, conventions de code, workflows
- **IA** : Consulter les schémas, API, guides d’intégration
- **Management** : Lire les synthèses, reporting, index documentaire

---

## 5. Ressources

- [Index documentaire](DOC_INDEX.md)
- [Onboarding](onboarding/README.md)
- [FAQ](FAQ.md)

---

## ⚠️ Note critique pour toute documentation Go, scripts, ou automatisation

Pour toute documentation, guide technique, ou script d’intégration concernant Go :

- **Ne jamais recommander ou documenter l’utilisation de `GOPROXY=off`** sauf cas d’exception (offline total).
- Toujours rappeler que :
  - `GOPROXY=https://proxy.golang.org,direct`
  - `GOSUMDB=sum.golang.org`

- Toute documentation, exemple, ou snippet CLI/IA doit inclure l’export de ces variables AVANT toute commande Go.
- Toute exception (modules privés, proxy d’entreprise, etc.) doit être explicitement documentée.

Exemple à inclure dans les guides :
```bash
export GOPROXY="https://proxy.golang.org,direct"
export GOSUMDB="sum.golang.org"
```
