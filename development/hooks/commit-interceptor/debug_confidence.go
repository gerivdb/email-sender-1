package commitinterceptor

// DebugConfidence provides debugging for confidence levels
func DebugConfidence(confidence float64) string {
	if confidence > 0.9 {
		return "High confidence"
	} else if confidence > 0.6 {
		return "Medium confidence"
	} else {
		return "Low confidence"
	}
}
