package conflict

import (
	"encoding/json"
	"io/ioutil"
	"os"
)

// SaveHistory saves ConflictHistory to a JSON file.
func (h *ConflictHistory) SaveHistory(path string) error {
	data, err := json.MarshalIndent(h, "", "  ")
	if err != nil {
		return err
	}
	return ioutil.WriteFile(path, data, 0o644)
}

// LoadHistory loads ConflictHistory from a JSON file.
func (h *ConflictHistory) LoadHistory(path string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()
	dec := json.NewDecoder(file)
	return dec.Decode(h)
}
