# ExtensibleManagerType

## Rôle

Manager extensible via plugins ou stratégies.

## Interfaces principales

- `RegisterPlugin(plugin PluginInterface) error`
- `UnregisterPlugin(name string) error`
- `ListPlugins() []PluginInfo`
- `GetPlugin(name string) (PluginInterface, error)`

## Utilisation

Ajout dynamique de fonctionnalités ou de stratégies (ex : plugins documentaires, extensions de logique).

## Entrée/Sortie

Plugins, stratégies, informations sur les plugins, erreurs éventuelles.

## Corrélations

- Voir [doc-manager.md](doc-manager.md)
- Voir [../ARCHITECTURE/integrated-manager.md](../ARCHITECTURE/integrated-manager.md)
- Voir [../ARCHITECTURE/ecosystem-overview.md](../ARCHITECTURE/ecosystem-overview.md)
