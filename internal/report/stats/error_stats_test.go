package stats

import (
	"testing"
	"time"
)

func TestErrorStats(t *testing.T) {
	t.Run("Test recording and retrieving errors", func(t *testing.T) {
		es := NewErrorStats(time.Hour, 3)  // 1 hour window, keep top 3 errors
		
		// Record some errors
		es.RecordError("TypeError", "undefined is not a function")
		es.RecordError("TypeError", "cannot read property 'x' of undefined")
		es.RecordError("SyntaxError", "unexpected token {")
		es.RecordError("TypeError", "object is not a function")
		es.RecordError("ReferenceError", "x is not defined")
		
		// Test total count
		if total := es.GetTotalErrors(); total != 5 {
			t.Errorf("GetTotalErrors() = %v, want %v", total, 5)
		}
		
		// Test top errors
		topErrors := es.GetTopErrors()
		if len(topErrors) != 3 { // We set topN = 3
			t.Errorf("GetTopErrors() returned %v errors, want %v", len(topErrors), 3)
		}
		
		// TypeError should be first with count = 3
		if topErrors[0].Type != "TypeError" || topErrors[0].Count != 3 {
			t.Errorf("First top error type = %v count = %v, want TypeError count = 3", 
				topErrors[0].Type, topErrors[0].Count)
		}
	})

	t.Run("Test error expiration", func(t *testing.T) {
		es := NewErrorStats(time.Millisecond*100, 3)  // Very short window
		
		es.RecordError("OldError", "old error")
		time.Sleep(time.Millisecond * 150)  // Wait for error to expire
		es.RecordError("NewError", "new error")
		
		topErrors := es.GetTopErrors()
		for _, err := range topErrors {
			if err.Type == "OldError" {
				t.Error("Found expired error in top errors")
			}
		}
	})
	
	t.Run("Test error rate calculation", func(t *testing.T) {
		es := NewErrorStats(time.Hour, 3)
		
		// Record 5 errors
		for i := 0; i < 5; i++ {
			es.RecordError("TestError", "test error")
		}
		
		// Get error rate over 10 seconds
		rate := es.GetErrorRate(10 * time.Second)
		expectedRate := float64(5) / 10.0  // 5 errors / 10 seconds
		
		if rate != expectedRate {
			t.Errorf("GetErrorRate() = %v, want %v", rate, expectedRate)
		}
	})
}
