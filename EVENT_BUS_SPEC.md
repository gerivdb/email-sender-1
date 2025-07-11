# Spécification du Bus d'Événements

## Structure des Événements
- **ID**: Identifiant unique de l'événement (string)
- **Type**: Type d'événement (string)
- **Source**: Source de l'événement (string)
- **Payload**: Données de l'événement (string)
- **Timestamp**: Horodatage de l'événement (string)

## Canaux
- Le bus utilise un canal Go pour transmettre les événements.
- Capacité du canal: 100 événements.
