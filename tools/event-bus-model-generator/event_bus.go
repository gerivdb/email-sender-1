package main

type Event struct {
	ID        string      `json:"id"`
	Type      string      `json:"type"`
	Source    string      `json:"source"`
	Target    string      `json:"target"`
	Timestamp int64       `json:"timestamp"`
	Priority  int         `json:"priority"`
	Payload   interface{} `json:"payload"`
}
