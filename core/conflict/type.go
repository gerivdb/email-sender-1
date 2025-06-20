package conflict

// ConflictType represents the type of conflict encountered.
type ConflictType int

const (
	PathConflict ConflictType = iota
	ContentConflict
	VersionConflict
	PermissionConflict
)

func (ct ConflictType) String() string {
	switch ct {
	case PathConflict:
		return "Path"
	case ContentConflict:
		return "Content"
	case VersionConflict:
		return "Version"
	case PermissionConflict:
		return "Permission"
	default:
		return "Unknown"
	}
}
