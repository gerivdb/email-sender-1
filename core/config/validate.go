package config

import (
	"encoding/json"

	"github.com/xeipuuv/gojsonschema"
)

// ValidateConfigWithSchema validates config with JSON Schema.
func ValidateConfigWithSchema(cfg *AppConfig, schemaPath string) (bool, error) {
	loader := gojsonschema.NewReferenceLoader("file://" + schemaPath)
	// Convert cfg to map
	jsonData, _ := json.Marshal(cfg)
	docLoader := gojsonschema.NewBytesLoader(jsonData)
	result, err := gojsonschema.Validate(loader, docLoader)
	if err != nil {
		return false, err
	}
	return result.Valid(), nil
}
