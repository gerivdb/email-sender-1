package plugins

import (
	"fmt"
	"plugin"
)

// Plugin interface
type Plugin interface {
	Init() error
	Run() error
	Close() error
}

// LoadPlugin loads a plugin from a file path
func LoadPlugin(path string) (Plugin, error) {
	plug, err := plugin.Open(path)
	if err != nil {
		return nil, err
	}

	sym, err := plug.Lookup("Plugin")
	if err != nil {
		return nil, err
	}

	var pl Plugin
	pl, ok := sym.(Plugin)
	if !ok {
		return nil, fmt.Errorf("unexpected type from module symbol: %T", sym)
	}

	return pl, nil
}
