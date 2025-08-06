# Qdrant Cloud — Clusters

## Présentation

Qdrant Cloud permet de créer et gérer des clusters vectoriels pour l’indexation, la recherche et la modularisation documentaire Roo Code.  
Ce document centralise : bonnes pratiques, limitations, FAQ et liens utiles pour l’usage Roo Code.

---

## Limitation du nombre de clusters gratuits

> **Règle officielle Qdrant Cloud (2024-2025) :**
>
> - **Un seul cluster cloud gratuit (« free cluster ») est autorisé par compte utilisateur Qdrant Cloud.**
> - Pour créer un nouveau cluster gratuit (ex : nouvelle démo), il faut d’abord supprimer le cluster gratuit existant.
> - Cette restriction ne s’applique pas aux offres payantes (« Standard », « Enterprise »), qui permettent plusieurs clusters en parallèle.

### Capacités du cluster gratuit

- **1GB RAM**
- Environ **1 million de vecteurs** (dimension 768)
- **Aucune carte bancaire requise** pour l’inscription

### Cas d’usage Roo Code

- Pour tester plusieurs environnements gratuits simultanément (ex : dev + staging), il faut utiliser plusieurs comptes Qdrant Cloud distincts.
- Pour des besoins multi-environnements professionnels, privilégier une offre payante.

### Sources officielles et guides

- [Documentation Qdrant Cloud — Créer un cluster](https://qdrant.tech/documentation/cloud/create-cluster/)
- [Page de tarification Qdrant](https://qdrant.tech/pricing/)
- [Guide d’utilisation du free tier (Gatling)](https://gatling.io/blog/analyzing-grpc-performance-with-gatling-on-qdrant-free-tier)
- [Superlinked — Qdrant en production](https://docs.superlinked.com/run-in-production/index-1/qdrant)
- [Annonce LinkedIn Qdrant](https://www.linkedin.com/posts/qdrant_how-much-can-qdrant-clouds-free-tier-activity-7303806597024133120-OUIw)

---

## FAQ / Limitations

- **Combien de clusters gratuits puis-je créer ?**  
  → **1 cluster gratuit actif par compte**. Pour en créer un nouveau, supprimer l’existant.
- **Puis-je avoir plusieurs environnements gratuits ?**  
  → Non, sauf à utiliser plusieurs comptes.
- **Cette limitation s’applique-t-elle aux offres payantes ?**  
  → Non, les offres payantes permettent plusieurs clusters.

---

## Références croisées

- [cloud-organizations.md](cloud-organizations.md)
- [cloud-api-keys.md](cloud-api-keys.md)
- [cloud-rbac.md](cloud-rbac.md)

---

*Pour toute évolution, vérifier la [documentation officielle Qdrant](https://qdrant.tech/documentation/cloud/cloud-clusters/) et la page de tarification.*
