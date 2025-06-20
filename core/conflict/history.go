package conflict

import "time"

// ConflictHistory structure with timestamps and metadata.
type ConflictHistory struct {
	Conflicts []ConflictRecord
}

type ConflictRecord struct {
	Conflict  Conflict
	Resolved  bool
	Timestamp time.Time
	Metadata  map[string]interface{}
}

func (h *ConflictHistory) Add(record ConflictRecord) {
	h.Conflicts = append(h.Conflicts, record)
}

func (h *ConflictHistory) Filter(resolved bool) []ConflictRecord {
	var out []ConflictRecord
	for _, r := range h.Conflicts {
		if r.Resolved == resolved {
			out = append(out, r)
		}
	}
	return out
}
