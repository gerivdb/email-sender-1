package conflict

// Search and filter in history.
func (h *ConflictHistory) SearchByType(t ConflictType) []ConflictRecord {
	var out []ConflictRecord
	for _, r := range h.Conflicts {
		if r.Conflict.Type == t {
			out = append(out, r)
		}
	}
	return out
}
