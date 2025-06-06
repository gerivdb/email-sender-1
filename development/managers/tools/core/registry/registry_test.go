// Manager Toolkit - Registry Test
// Tests the registry functionality

package registry

import (
	"github.com/email-sender/tools/core/registry"
	"context"
	"fmt"
	"testing"
)

func TestToolRegistry(t *testing.T) {
	fmt.Println("Testing tool registry system...")
	registry := GetGlobalRegistry()
	if registry == nil {
		t.Fatal("Global registry is nil")
	}
	
	ops := registry.ListOperations()
	fmt.Printf("Found %d registered operations\n", len(ops))
	
	for i, op := range ops {
		tool, err := registry.GetTool(op)
		if err != nil {
			t.Errorf("%d. %s - ERROR: %v", i+1, op, err)
			continue
		}
		fmt.Printf("%d. %s - Tool: %s\n", i+1, op, tool.String())
		
		// Test String() method
		if tool.String() == "" {
			t.Errorf("Tool %s has empty String() result", op)
		}
		
		// Test GetDescription() method
		if tool.GetDescription() == "" {
			t.Errorf("Tool %s has empty GetDescription() result", op)
		}
		
		// Test metrics collection
		metrics := tool.CollectMetrics()
		if metrics == nil {
			t.Errorf("Tool %s returned nil metrics", op)
		} else if _, ok := metrics["tool"]; !ok {
			t.Errorf("Tool %s does not include 'tool' key in metrics", op)
		}
		
		// Stop method should not crash
		err = tool.Stop(context.Background())
		if err != nil {
			t.Errorf("Tool %s Stop() returned error: %v", op, err)
		}
	}
}


