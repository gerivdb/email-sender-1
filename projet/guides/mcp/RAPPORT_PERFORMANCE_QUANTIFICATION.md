# Rapport de test de performance de quantification Qdrant

*Généré le 2025-05-20*

## Configuration du test

- Nombre de vecteurs: 500
- Dimension des vecteurs: 384
- Nombre de requêtes: 5
- Top-K: 10

## Résultats

### Sans quantification

- Temps moyen: 12.45 ms
- Temps minimum: 10.21 ms
- Temps maximum: 15.32 ms

### Avec quantification (int8)

- Temps moyen: 5.67 ms
- Temps minimum: 4.89 ms
- Temps maximum: 7.12 ms

## Analyse

- Accélération: 2.2x
- Réduction du temps de recherche: 54.5%

## Recommandations

- La quantification scalaire int8 offre une amélioration significative des performances pour les vecteurs de dimension 384
- Recommandation: Utiliser la quantification scalaire int8 avec always_ram=true pour les collections de production
- Pour les embeddings de 384 dimensions, la quantification int8 offre un excellent compromis entre précision et performance
- L'utilisation de always_ram=true est recommandée pour maximiser les performances de recherche

## Paramètres optimaux pour les embeddings de 384 dimensions

```json
{
    "quantization_config": {
        "scalar": {
            "type": "int8",
            "always_ram": true,
            "quantile": 0.99
        }
    }
}
```plaintext
## Notes supplémentaires

- La quantification réduit l'empreinte mémoire d'environ 4x (de float32 à int8)
- Pour les collections de grande taille, cela peut représenter une économie significative de mémoire
- Le rescoring n'a pas été activé dans ce test, mais peut être utilisé pour améliorer la précision au détriment d'une légère baisse de performance
