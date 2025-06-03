package panels

import "errors"

// Panel management errors
var (
	ErrPanelNotFound         = errors.New("panel not found")
	ErrMaxPanelsReached      = errors.New("maximum number of panels reached")
	ErrManagerNotInitialized = errors.New("manager not initialized")
	ErrInvalidLayout         = errors.New("invalid layout configuration")
	ErrPanelExists           = errors.New("panel with this ID already exists")
	ErrMinSizeViolation      = errors.New("panel size below minimum allowed")
	ErrInvalidOperation      = errors.New("invalid operation for current panel state")
	ErrStateNotFound         = errors.New("state file not found")
	ErrCorruptedState        = errors.New("corrupted state file")
	ErrResizeNotAllowed      = errors.New("panel is not resizable")
	ErrSizeTooSmall          = errors.New("panel size is too small")
)
