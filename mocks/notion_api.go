package mocks

import (
	"fmt"
	"strings"
	"time"
)

// MockNotionAPI simule l'API Notion pour LOT1 (contacts/venues)
// ROI: +8h développement sans quotas API
type MockNotionAPI struct {
	Contacts []Contact
	Venues   []Venue
	ApiDelay time.Duration
}

type Contact struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Email       string            `json:"email"`
	VenueID     string            `json:"venue_id"`
	Status      string            `json:"status"`
	LastContact time.Time         `json:"last_contact"`
	Metadata    map[string]string `json:"metadata"`
}

type Venue struct {
	ID       string            `json:"id"`
	Name     string            `json:"name"`
	Type     string            `json:"type"`
	Location string            `json:"location"`
	Capacity int               `json:"capacity"`
	Manager  Contact           `json:"manager"`
	Metadata map[string]string `json:"metadata"`
}

func NewMockNotionAPI() *MockNotionAPI {
	return &MockNotionAPI{
		Contacts: generateMockContacts(),
		Venues:   generateMockVenues(),
		ApiDelay: 50 * time.Millisecond,
	}
}

func (m *MockNotionAPI) GetContacts(filter string) ([]Contact, error) {
	time.Sleep(m.ApiDelay)
	
	if filter == "" {
		return m.Contacts, nil
	}
	
	// Simple filter simulation
	var filtered []Contact
	for _, contact := range m.Contacts {
		if strings.Contains(strings.ToLower(contact.Name), strings.ToLower(filter)) ||
		   strings.Contains(strings.ToLower(contact.Email), strings.ToLower(filter)) {
			filtered = append(filtered, contact)
		}
	}
	
	return filtered, nil
}

func (m *MockNotionAPI) GetVenues() ([]Venue, error) {
	time.Sleep(m.ApiDelay)
	return m.Venues, nil
}

func (m *MockNotionAPI) UpdateContactStatus(contactID, status string) error {
	time.Sleep(m.ApiDelay)
	
	for i, contact := range m.Contacts {
		if contact.ID == contactID {
			m.Contacts[i].Status = status
			m.Contacts[i].LastContact = time.Now()
			return nil
		}
	}
	
	return fmt.Errorf("contact not found: %s", contactID)
}

// Mock data generators pour tests réalistes
func generateMockContacts() []Contact {
	return []Contact{
		{
			ID: "c1", Name: "Alice Manager", Email: "alice@venue1.com", 
			VenueID: "v1", Status: "active",
			Metadata: map[string]string{"role": "manager", "priority": "high"},
		},
		{
			ID: "c2", Name: "Bob Director", Email: "bob@venue2.com", 
			VenueID: "v2", Status: "pending",
			Metadata: map[string]string{"role": "director", "priority": "medium"},
		},
		{
			ID: "c3", Name: "Carol Owner", Email: "carol@venue3.com", 
			VenueID: "v3", Status: "contacted",
			Metadata: map[string]string{"role": "owner", "priority": "high"},
		},
	}
}

func generateMockVenues() []Venue {
	return []Venue{
		{
			ID: "v1", Name: "Concert Hall Alpha", Type: "concert", 
			Location: "Paris", Capacity: 500,
			Metadata: map[string]string{"genre": "jazz", "booking": "available"},
		},
		{
			ID: "v2", Name: "Theater Beta", Type: "theater", 
			Location: "Lyon", Capacity: 200,
			Metadata: map[string]string{"genre": "drama", "booking": "busy"},
		},
		{
			ID: "v3", Name: "Club Gamma", Type: "club", 
			Location: "Marseille", Capacity: 150,
			Metadata: map[string]string{"genre": "electronic", "booking": "available"},
		},
	}
}
