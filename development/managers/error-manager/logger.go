package errormanager

import (
	"go.uber.org/zap"
)

var logger *zap.Logger

// InitializeLogger initializes the Zap logger in production mode
func InitializeLogger() error {
	var err error
	logger, err = zap.NewProduction()
	if err != nil {
		return err
	}
	return nil
}

// LogError logs an error with additional metadata
func LogError(err error, module string, code string) {
	if logger == nil {
		if initErr := InitializeLogger(); initErr != nil {
			panic("Failed to initialize logger: " + initErr.Error())
		}
	}
	logger.Error("Error occurred",
		zap.String("module", module),
		zap.String("code", code),
		zap.Error(err),
	)
}
