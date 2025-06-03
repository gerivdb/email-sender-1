package navigation

import "time"

// TransitionOptions defines parameters for advanced mode switching.
type TransitionOptions struct {
	Trigger        TransitionTrigger
	PreserveState  bool
	AnimationType  string
	Duration       time.Duration
	BeforeCallback string
	AfterCallback  string
}
