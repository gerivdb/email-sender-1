package debug

// Used for "fmt.Sprintf" later in code
// "strings" was removed - unused import

func ComponentToString(c EmailSenderComponent) string {
	switch c {
	case RAGEngine:
		return "RAGEngine"
	case N8NWorkflow:
		return "N8NWorkflow"
	case NotionAPI:
		return "NotionAPI"
	case GmailProcessing:
		return "GmailProcessing"
	case PowerShellScript:
		return "PowerShellScript"
	case ConfigFiles:
		return "ConfigFiles"
	default:
		return "Unknown"
	}
}

func GetComponentIcon(c EmailSenderComponent) string {
	switch c {
	case RAGEngine:
		return "⚙️"
	case N8NWorkflow:
		return "🌊"
	case NotionAPI:
		return "📝"
	case GmailProcessing:
		return "📧"
	case PowerShellScript:
		return "⚡"
	case ConfigFiles:
		return "🏗️"
	default:
		return "❓"
	}
}
