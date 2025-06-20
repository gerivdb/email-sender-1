package conflict

import (
	"reflect"
	"testing"
	"time"
)

func TestConflictTypeString(t *testing.T) {
	cases := []struct {
		ct       ConflictType
		expected string
	}{
		{PathConflict, "Path"},
		{ContentConflict, "Content"},
		{VersionConflict, "Version"},
		{PermissionConflict, "Permission"},
	}
	for _, c := range cases {
		if c.ct.String() != c.expected {
			t.Errorf("expected %s, got %s", c.expected, c.ct.String())
		}
	}
}

func TestConflictStruct(t *testing.T) {
	c := Conflict{
		Type:         PathConflict,
		Severity:     2,
		Participants: []string{"user1", "user2"},
		Metadata:     map[string]interface{}{"key": "value"},
	}
	if c.Type != PathConflict || c.Severity != 2 || !reflect.DeepEqual(c.Participants, []string{"user1", "user2"}) {
		t.Error("Conflict struct fields not set correctly")
	}
}

func TestResolutionStruct(t *testing.T) {
	timeNow := time.Now()
	r := Resolution{
		Status:    "resolved",
		Strategy:  "auto",
		AppliedAt: timeNow,
		Rollback:  false,
	}
	if r.Status != "resolved" || r.Strategy != "auto" || !r.AppliedAt.Equal(timeNow) || r.Rollback != false {
		t.Error("Resolution struct fields not set correctly")
	}
}

func TestConflictManager(t *testing.T) {
	cm := NewConflictManager()
	c := Conflict{Type: ContentConflict}
	cm.AddConflict(c)
	if len(cm.ListConflicts()) != 1 {
		t.Error("ConflictManager did not add conflict correctly")
	}
}
