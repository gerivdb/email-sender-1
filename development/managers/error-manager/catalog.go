package errormanager

import (
	"fmt"
	"go.uber.org/zap"
)

// CatalogError prepares and logs an error entry
func CatalogError(entry ErrorEntry) {
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	logger.Error("Error cataloged",
		zap.String("id", entry.ID),
		zap.Time("timestamp", entry.Timestamp),
		zap.String("message", entry.Message),
		zap.String("stack_trace", entry.StackTrace),
		zap.String("module", entry.Module),
		zap.String("error_code", entry.ErrorCode),
		zap.String("manager_context", entry.ManagerContext),
		zap.String("severity", entry.Severity),
	)

	fmt.Printf("Error cataloged: %+v\n", entry)
}
