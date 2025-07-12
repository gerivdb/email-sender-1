// cmd/auto-roadmap-runner/qdrant_integration.go
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
)

func SendToQdrant(roadmap Roadmap, endpoint string) error {
	payload := map[string]interface{}{
		"id":      roadmap.ID,
		"payload": roadmap,
		"vector":  roadmap.Embeddings,
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	resp, err := http.Post(endpoint, "application/json", bytes.NewBuffer(body))
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	respBody, _ := ioutil.ReadAll(resp.Body)
	fmt.Printf("Qdrant response: %s\n", string(respBody))
	return nil
}
