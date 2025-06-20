package conflict

import (
	"os/exec"
)

// Versioning resolutions with Git integration.
func (h *ConflictHistory) CommitResolution(message string) error {
	cmd := exec.Command("git", "add", ".")
	if err := cmd.Run(); err != nil {
		return err
	}
	cmd = exec.Command("git", "commit", "-m", message)
	return cmd.Run()
}
