# Conflict History and Rollback Documentation

## Structures et gestion

- **ConflictHistory** : Historique des conflits avec timestamps et metadata
- **Persistence** : Sauvegarde/chargement JSON
- **RollbackManager** : Annulation de résolutions
- **Git integration** : Commit des résolutions
- **Recherche/filtrage** : Par type, statut
- **Export/Import** : JSON

## Exemple d'utilisation

```go
h := &ConflictHistory{}
h.Add(ConflictRecord{Conflict: Conflict{Type: PathConflict}, Resolved: true, Timestamp: time.Now()})
h.SaveHistory("history.json")
h.LoadHistory("history.json")
```

## Tests

Persistence, récupération, rollback testés dans `history_test.go`.
