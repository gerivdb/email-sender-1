# Documentation – Outils d’écriture/lecture robustes

## Fonction `writeFile`

```go
func writeFile(path, content string, onSuccess func(string)) error
```

- Écrit le contenu dans le fichier `path`.
- Ajoute des logs détaillés avant/après écriture.
- Déclenche un callback `onSuccess` si fourni, après écriture réussie.
- Si aucun callback n’est fourni, effectue une validation par attente contrôlée : jusqu’à 5 tentatives de lecture espacées de 100ms, avec logs à chaque étape.
- Retourne une erreur explicite si la validation échoue.

### Exemple d’utilisation

```go
// Avec callback
writeFile("output.txt", "data", func(path string) {
    fmt.Printf("Écriture terminée pour %s\n", path)
})

// Sans callback (validation automatique)
err := writeFile("output.txt", "data", nil)
if err != nil {
    log.Fatalf("Erreur d’écriture/validation : %v", err)
}
```

## Fonction `readFile`

```go
func readFile(path string) (string, error)
```

- Lit le contenu du fichier `path`.
- Retourne le contenu ou une erreur détaillée.

## Tests unitaires

- Les tests couvrent : écriture avec callback, validation par attente contrôlée, gestion des erreurs.

## Historique

- Correction de la boucle de validation (voir `.github/docs/incidents/incident-validation-ecriture-lecture.md`).
- Nouvelle stratégie validée par tests unitaires.
