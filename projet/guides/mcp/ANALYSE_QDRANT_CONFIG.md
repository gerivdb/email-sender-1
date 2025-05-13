# Analyse de la configuration Qdrant
*Générée le 2025-05-20*

## Configuration actuelle

Collection: **roadmap_tasks_test_vector_update**

### Paramètres des vecteurs
- **Dimension**: 384
- **Distance**: Cosine
- **Payload sur disque**: false

### Configuration HNSW
- **m**: 16
- **ef_construct**: 100
- **full_scan_threshold**: 10000
- **on_disk**: false

### Configuration de quantification
Non configurée

### Configuration d'optimisation
- **default_segment_number**: 0
- **indexing_threshold**: 20000

## Recommandations

### HNSW
- Activer on_disk pour réduire l'utilisation de la mémoire avec des vecteurs de grande dimension

### Quantification
- Activer la quantification scalaire pour réduire l'empreinte mémoire et accélérer les recherches
- Utiliser la quantification scalaire de type int8 pour la distance Cosine

### Optimisation
- Configurer default_segment_number en fonction du nombre de cœurs CPU disponibles pour optimiser la parallélisation

## Configuration recommandée

```json
{
    "vectors": {
        "size": 384,
        "distance": "Cosine",
        "on_disk": true
    },
    "quantization_config": {
        "scalar": {
            "type": "int8",
            "always_ram": true
        }
    },
    "hnsw_config": {
        "m": 16,
        "ef_construct": 100,
        "on_disk": false
    },
    "optimizer_config": {
        "default_segment_number": 8
    }
}
```
