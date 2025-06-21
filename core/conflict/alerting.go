package conflict

// AlertingSystem with configurable thresholds.
type AlertingSystem struct {
	Threshold int
	Alerts    chan string
}

func NewAlertingSystem(threshold int) *AlertingSystem {
	return &AlertingSystem{
		Threshold: threshold,
		Alerts:    make(chan string, 10),
	}
}

func (a *AlertingSystem) Check(value int) {
	if value > a.Threshold {
		a.Alerts <- "Threshold exceeded"
	}
}
