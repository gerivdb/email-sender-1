//go:build unit

package automatisation_doc

import (
	"context"
	"errors"
	"testing"
	"time"

	"gopkg.in/yaml.v3"
)

type dummyPlugin struct {
	result string
	err    error
}

func (d *dummyPlugin) Name() string { return "dummy" }
func (d *dummyPlugin) Apply(ctx context.Context, input interface{}) (interface{}, error) {
	return d.result, d.err
}

func TestFallbackManager_ApplyFallback_Retry(t *testing.T) {
	fm := &FallbackManager{}
	strat := FallbackStrategy{
		Type:   FallbackRetry,
		Config: map[string]interface{}{"max_attempts": 2},
	}
	attempts := 0
	f := func(ctx context.Context, input interface{}) (interface{}, error) {
		attempts++
		if attempts < 2 {
			return nil, errors.New("fail")
		}
		return "ok", nil
	}
	res, err := fm.ApplyFallback(context.Background(), []FallbackStrategy{strat}, f, nil)
	if err != nil || res != "ok" || attempts != 2 {
		t.Errorf("retry failed: got %v, err %v, attempts %d", res, err, attempts)
	}
}

func TestFallbackManager_ApplyFallback_Alternate(t *testing.T) {
	fm := &FallbackManager{}
	strat := FallbackStrategy{
		Type:   FallbackAlternate,
		Config: map[string]interface{}{"alternate_value": "alt"},
	}
	f := func(ctx context.Context, input interface{}) (interface{}, error) {
		return nil, errors.New("fail")
	}
	res, err := fm.ApplyFallback(context.Background(), []FallbackStrategy{strat}, f, nil)
	if err != nil || res != "alt" {
		t.Errorf("alternate failed: got %v, err %v", res, err)
	}
}

func TestFallbackManager_ApplyFallback_Skip(t *testing.T) {
	fm := &FallbackManager{}
	strat := FallbackStrategy{Type: FallbackSkip}
	f := func(ctx context.Context, input interface{}) (interface{}, error) {
		return nil, errors.New("fail")
	}
	res, err := fm.ApplyFallback(context.Background(), []FallbackStrategy{strat}, f, nil)
	if err != nil || res != nil {
		t.Errorf("skip failed: got %v, err %v", res, err)
	}
}

func TestFallbackManager_ApplyFallback_Plugin(t *testing.T) {
	fm := NewFallbackManager()
	plugin := &dummyPlugin{result: "plugin-ok", err: nil}
	_ = fm.RegisterPlugin(plugin)
	strat := FallbackStrategy{
		Type:   FallbackPluginType,
		Config: map[string]interface{}{"plugin_name": "dummy"},
	}
	f := func(ctx context.Context, input interface{}) (interface{}, error) {
		return nil, errors.New("fail")
	}
	res, err := fm.ApplyFallback(context.Background(), []FallbackStrategy{strat}, f, nil)
	if err != nil || res != "plugin-ok" {
		t.Errorf("plugin failed: got %v, err %v", res, err)
	}
}

func TestFallbackManager_ApplyFallback_PluginNotFound(t *testing.T) {
	fm := NewFallbackManager()
	strat := FallbackStrategy{
		Type:   FallbackPluginType,
		Config: map[string]interface{}{"plugin_name": "notfound"},
	}
	f := func(ctx context.Context, input interface{}) (interface{}, error) {
		return nil, errors.New("fail")
	}
	_, err := fm.ApplyFallback(context.Background(), []FallbackStrategy{strat}, f, nil)
	if err == nil {
		t.Errorf("expected error for plugin not found")
	}
}

func TestFallbackManager_LoadFromYAML(t *testing.T) {
	yamlData := `
- type: retry
  config:
    max_attempts: 2
- type: alternate
  config:
    alternate_value: "foo"
`
	var strategies []FallbackStrategy
	if err := yaml.Unmarshal([]byte(yamlData), &strategies); err != nil {
		t.Fatalf("YAML unmarshal failed: %v", err)
	}
	if len(strategies) != 2 || strategies[0].Type != FallbackRetry || strategies[1].Type != FallbackAlternate {
		t.Errorf("YAML strategies not loaded correctly: %+v", strategies)
	}
}

func TestFallbackManager_Concurrency(t *testing.T) {
	fm := NewFallbackManager()
	plugin := &dummyPlugin{result: "ok", err: nil}
	_ = fm.RegisterPlugin(plugin)
	done := make(chan struct{})
	go func() {
		for i := 0; i < 100; i++ {
			_ = fm.RegisterPlugin(plugin)
		}
		close(done)
	}()
	for i := 0; i < 100; i++ {
		_, _ = fm.plugins["dummy"]
	}
	select {
	case <-done:
	case <-time.After(1 * time.Second):
		t.Error("concurrency test timeout")
	}
}
