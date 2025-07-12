// cmd/auto-roadmap-runner/qdrant_search.go
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
)

func SearchQdrant(vector []float64, endpoint string) error {
	query := map[string]interface{}{
		"vector": vector,
		"top":    5,
	}
	body, err := json.Marshal(query)
	if err != nil {
		return err
	}
	resp, err := http.Post(endpoint, "application/json", bytes.NewBuffer(body))
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	respBody, _ := ioutil.ReadAll(resp.Body)
	fmt.Printf("Résultats Qdrant : %s\n", string(respBody))
	return nil
}
