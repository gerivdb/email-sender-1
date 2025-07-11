package eventbus

type Event struct {
	ID        string `json:"id"`
	Type      string `json:"type"`
	Source    string `json:"source"`
	Payload   string `json:"payload"`
	Timestamp string `json:"timestamp"`
}

type EventBus struct {
	Events chan Event
}

func NewEventBus() *EventBus {
	return &EventBus{
		Events: make(chan Event, 100),
	}
}
