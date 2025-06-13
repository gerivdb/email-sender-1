# Configuration du mode hybride pour Qdrant

*Généré le 2025-05-20*

## Collection: roadmap_tasks_test_vector_update

### Configuration actuelle

- **on_disk**: true
- **Quantification**: true
- **Type de quantification**: int8
- **always_ram**: true

## Avantages du mode hybride

Le mode hybride combine les avantages de la quantification et du stockage sur disque:

1. **Réduction de l'empreinte mémoire**: Les vecteurs originaux sont stockés sur disque
2. **Performances de recherche optimales**: Les vecteurs quantifiés sont maintenus en RAM
3. **Précision préservée**: Possibilité d'utiliser le rescoring avec les vecteurs originaux

## Recommandations d'utilisation

- Pour les collections de grande taille (>1M vecteurs), le mode hybride est fortement recommandé
- Pour les vecteurs de grande dimension (>500), le mode hybride offre un excellent compromis
- Surveiller l'utilisation de la mémoire et ajuster les paramètres si nécessaire

## Configuration recommandée

```json
{
    "hnsw_config": {
        "on_disk": true
    },
    "quantization_config": {
        "scalar": {
            "type": "int8",
            "always_ram": true,
            "quantile": 0.99,
            "rescore": true
        }
    }
}
```plaintext