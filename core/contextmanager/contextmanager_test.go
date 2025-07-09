package core

import (
	"fmt"
	"sync"
	"testing"
	"time"
)

func TestNewContextManager(t *testing.T) {
	cm := NewContextManager()

	if cm == nil {
		t.Fatal("NewContextManager returned nil")
	}
	if cm.history == nil {
		t.Error("history map is nil")
	}
	if cm.globalContext == nil {
		t.Error("globalContext map is nil")
	}
}

func TestStoreAndGetDialogueHistory(t *testing.T) {
	cm := NewContextManager()
	persona1 := "sales_agent"
	persona2 := "support_bot"

	// Test basic storage and retrieval
	cm.StoreDialogueHistory(persona1, "Hello, I'm interested in your product.")
	cm.StoreDialogueHistory(persona1, "Can you tell me more about pricing?")
	cm.StoreDialogueHistory(persona2, "Hi, how can I help you?")

	history1 := cm.GetDialogueContext(persona1, 100)
	if len(history1) != 2 || history1[0] != "Hello, I'm interested in your product." || history1[1] != "Can you tell me more about pricing?" {
		t.Errorf("Incorrect history for persona1: %v", history1)
	}

	history2 := cm.GetDialogueContext(persona2, 100)
	if len(history2) != 1 || history2[0] != "Hi, how can I help you?" {
		t.Errorf("Incorrect history for persona2: %v", history2)
	}

	// Test getting last N messages
	cm.StoreDialogueHistory(persona1, "What are the payment options?")
	history1_lastN := cm.GetDialogueContext(persona1, 2)
	if len(history1_lastN) != 2 || history1_lastN[0] != "Can you tell me more about pricing?" || history1_lastN[1] != "What are the payment options?" {
		t.Errorf("Incorrect last N history for persona1: %v", history1_lastN)
	}

	// Test empty history
	history3 := cm.GetDialogueContext("non_existent_persona", 100)
	if len(history3) != 0 {
		t.Errorf("History for non-existent persona should be empty, got: %v", history3)
	}
}

func TestUpdateAndGetGlobalContext(t *testing.T) {
	cm := NewContextManager()

	// Test basic update and retrieval
	cm.UpdateGlobalContext("product_name", "AwesomeApp")
	cm.UpdateGlobalContext("user_id", 12345)

	globalCtx := cm.GetGlobalContext()
	if globalCtx["product_name"] != "AwesomeApp" || globalCtx["user_id"] != 12345 {
		t.Errorf("Incorrect global context: %v", globalCtx)
	}

	// Test immutability of retrieved map
	globalCtx["product_name"] = "BadApp"
	if cm.GetGlobalContext()["product_name"] == "BadApp" {
		t.Error("Global context was modified externally")
	}
}

func TestClearDialogueHistory(t *testing.T) {
	cm := NewContextManager()
	cm.StoreDialogueHistory("personaA", "msg1")
	cm.StoreDialogueHistory("personaB", "msg2")
	cm.StoreDialogueHistory("personaA", "msg3")

	// Clear history for a specific persona
	cm.ClearDialogueHistory("personaA")
	if len(cm.GetDialogueContext("personaA", 100)) != 0 {
		t.Error("History for personaA was not cleared")
	}
	if len(cm.GetDialogueContext("personaB", 100)) != 1 {
		t.Error("History for personaB should not be affected")
	}

	// Clear all history
	cm.ClearDialogueHistory("")
	if len(cm.GetDialogueContext("personaA", 100)) != 0 || len(cm.GetDialogueContext("personaB", 100)) != 0 {
		t.Error("All history was not cleared")
	}
}

func TestConcurrency(t *testing.T) {
	cm := NewContextManager()
	var wg sync.WaitGroup
	numGoroutines := 100
	numOperationsPerGoroutine := 1000

	// Test concurrent StoreDialogueHistory
	for i := 0; i < numGoroutines; i++ {
		wg.Add(1)
		go func(g int) {
			defer wg.Done()
			persona := fmt.Sprintf("persona_%d", g)
			for j := 0; j < numOperationsPerGoroutine; j++ {
				cm.StoreDialogueHistory(persona, fmt.Sprintf("message_%d_%d", g, j))
			}
		}(i)
	}
	wg.Wait()

	for i := 0; i < numGoroutines; i++ {
		persona := fmt.Sprintf("persona_%d", i)
		history := cm.GetDialogueContext(persona, numOperationsPerGoroutine+10) // +10 for safety
		if len(history) != numOperationsPerGoroutine {
			t.Errorf("Concurrent StoreDialogueHistory failed for persona %s: expected %d, got %d", persona, numOperationsPerGoroutine, len(history))
		}
	}

	// Test concurrent UpdateGlobalContext
	wg.Add(1)
	go func() {
		defer wg.Done()
		for i := 0; i < numOperationsPerGoroutine; i++ {
			cm.UpdateGlobalContext("counter", i)
		}
	}()
	wg.Wait()

	// The final value of "counter" depends on goroutine scheduling, so we just check it exists
	globalCtx := cm.GetGlobalContext()
	if _, ok := globalCtx["counter"]; !ok {
		t.Error("Concurrent UpdateGlobalContext failed, 'counter' not found")
	}

	// Test concurrent GetGlobalContext and StoreDialogueHistory
	wg.Add(numGoroutines)
	for i := 0; i < numGoroutines; i++ {
		go func(g int) {
			defer wg.Done()
			for j := 0; j < 10; j++ {
				cm.GetGlobalContext()
				cm.StoreDialogueHistory(fmt.Sprintf("read_persona_%d", g), "read_message")
			}
		}(i)
	}
	wg.Wait()

	// A short delay to ensure all goroutines finish writing
	time.Sleep(100 * time.Millisecond)

	// Check if history is consistent after concurrent reads/writes
	for i := 0; i < numGoroutines; i++ {
		persona := fmt.Sprintf("read_persona_%d", i)
		history := cm.GetDialogueContext(persona, 20)
		if len(history) != 10 {
			t.Errorf("Concurrent read/write history failed for persona %s: expected %d, got %d", persona, 10, len(history))
		}
	}
}
