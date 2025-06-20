package conflict

import "fmt"

// Conflict represents a detected conflict in the system.
type Conflict struct {
	Type         ConflictType
	Severity     int
	Participants []string
	Metadata     map[string]interface{}
}

func (c Conflict) String() string {
	return fmt.Sprintf("Type: %s, Severity: %d, Participants: %v, Metadata: %v", c.Type, c.Severity, c.Participants, c.Metadata)
}
