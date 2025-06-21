# Configuration and Customization Documentation

## Composants

- **AppConfig** : Structure de configuration YAML/JSON
- **HotReloadConfig** : Hot-reload sans redémarrage
- **ProfileConfig** : Profils par environnement
- **CLI** : Gestion de configuration (cmd/configcli)
- **API REST** : Exposition dynamique (cmd/configapi)
- **Validation JSON Schema** : Validation avancée

## Exemple d'utilisation

```go
cfg, _ := LoadConfigYAML("config.yaml")
profile := NewProfileConfig("dev", cfg)
```

## Tests

Chargement, hot-reload, validation testés dans `config_test.go`.
