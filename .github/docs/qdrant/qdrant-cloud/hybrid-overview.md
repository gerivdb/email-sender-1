# Qdrant Cloud & Local : Vue d’ensemble de l’architecture hybride

## Définition

Un **cluster hybride** combine des ressources locales (on-premises : serveurs physiques, VM, private cloud) et des ressources cloud (Qdrant Cloud, AWS, Azure, etc.), orchestrées pour fonctionner de façon fluide et unifiée.

- **Local** : stockage/traitement sur vos propres serveurs (contrôle, confidentialité, conformité).
- **Cloud** : scalabilité, élasticité, puissance à la demande, allègement des ressources locales.

## Illustration

- Données sensibles stockées localement, traitements intensifs délégués au cloud.
- Déplacement dynamique des charges selon les besoins.
- Orchestration Roo Code : gestion multi-clusters, routage, indexation hiérarchique.

![Schéma hybride](https://github.com/qdrant/landing_page/raw/master/qdrant-landing/content/documentation/hybrid-cloud/hybrid-cloud-arch.png)

## Avantages

- Sécurité, conformité, performance, coûts maîtrisés, disponibilité, résilience, scalabilité.
- Compartimentation : cloisonnement des données/process critiques.

## Références

- [IBM - Hybrid Cloud](https://www.ibm.com/fr-fr/topics/hybrid-cloud-architecture)
- [Qdrant Hybrid Cloud Doc](https://github.com/qdrant/landing_page/tree/master/qdrant-landing/content/documentation/hybrid-cloud)
- [Qdrant Private Cloud Doc](https://github.com/qdrant/landing_page/tree/master/qdrant-landing/content/documentation/private-cloud)