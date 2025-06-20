package conflict

// ExportHistory exports history to JSON.
func (h *ConflictHistory) ExportHistory(path string) error {
	return h.SaveHistory(path)
}

// ImportHistory imports history from JSON.
func (h *ConflictHistory) ImportHistory(path string) error {
	return h.LoadHistory(path)
}
