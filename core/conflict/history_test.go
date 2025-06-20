package conflict

import (
	"os"
	"testing"
	"time"
)

func TestConflictHistoryPersistence(t *testing.T) {
	h := &ConflictHistory{}
	rec := ConflictRecord{
		Conflict:  Conflict{Type: PathConflict},
		Resolved:  true,
		Timestamp: time.Now(),
		Metadata:  map[string]interface{}{"test": true},
	}
	h.Add(rec)
	tmp := "history_test.json"
	defer os.Remove(tmp)
	if err := h.SaveHistory(tmp); err != nil {
		t.Fatal(err)
	}
	h2 := &ConflictHistory{}
	if err := h2.LoadHistory(tmp); err != nil {
		t.Fatal(err)
	}
	if len(h2.Conflicts) != 1 || h2.Conflicts[0].Conflict.Type != PathConflict {
		t.Error("Persistence or recovery failed")
	}
}

func TestRollbackManager(t *testing.T) {
	h := &ConflictHistory{}
	h.Add(ConflictRecord{Resolved: true})
	rm := &RollbackManager{History: h}
	_ = rm.RollbackLast()
	if h.Conflicts[0].Resolved {
		t.Error("Rollback did not update resolved status")
	}
}
