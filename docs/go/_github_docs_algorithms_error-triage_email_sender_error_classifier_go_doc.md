# Package main

## Types

### ClassificationResult

### EmailSenderComponent

#### Methods

##### EmailSenderComponent.String

```go
func (c EmailSenderComponent) String() string
```

### EmailSenderErrorClass

### ErrorTypeResult

## Variables

### EmailSenderErrorClasses

```go
var EmailSenderErrorClasses = []EmailSenderErrorClass{

	{Type: "RAG_IMPORT_MISSING", Pattern: `cannot find package.*qdrant|vector|embedding`, Severity: 1, AutoFix: true, Component: RAGEngine},
	{Type: "RAG_TYPE_ERROR", Pattern: `cannot use .* as .* in.*vector|embedding`, Severity: 1, AutoFix: false, Component: RAGEngine},
	{Type: "RAG_UNDEFINED_VAR", Pattern: `undefined:.*vector|qdrant|embedding`, Severity: 2, AutoFix: false, Component: RAGEngine},

	{Type: "CONFIG_MISSING", Pattern: `config.*missing|yaml.*syntax|json.*syntax`, Severity: 1, AutoFix: true, Component: ConfigFiles},
	{Type: "ENV_VAR_MISSING", Pattern: `environment variable.*not set|NOTION_API_KEY|GMAIL_CREDENTIALS`, Severity: 1, AutoFix: false, Component: ConfigFiles},

	{Type: "N8N_WORKFLOW_ERROR", Pattern: `workflow.*undefined|missing node|n8n.*error`, Severity: 1, AutoFix: false, Component: N8NWorkflow},
	{Type: "N8N_NODE_ERROR", Pattern: `node.*not found|invalid node type`, Severity: 2, AutoFix: false, Component: N8NWorkflow},

	{Type: "NOTION_API_ERROR", Pattern: `notion.*unauthorized|api.*error|notion.*invalid`, Severity: 2, AutoFix: false, Component: NotionAPI},
	{Type: "GMAIL_API_ERROR", Pattern: `gmail.*oauth|credential.*error|gmail.*unauthorized`, Severity: 2, AutoFix: false, Component: GmailProcessing},

	{Type: "POWERSHELL_SYNTAX_ERROR", Pattern: `powershell.*syntax|PowerShell.*error`, Severity: 3, AutoFix: true, Component: PowerShellScript},
	{Type: "POWERSHELL_UNDEFINED_VAR", Pattern: `undefined variable.*powershell|variable.*not defined`, Severity: 3, AutoFix: true, Component: PowerShellScript},

	{Type: "GO_UNDEFINED_VAR", Pattern: `undefined:`, Severity: 2, AutoFix: false, Component: RAGEngine},
	{Type: "GO_TYPE_MISMATCH", Pattern: `cannot use .* as .* in`, Severity: 2, AutoFix: false, Component: RAGEngine},
	{Type: "GO_UNUSED_VAR", Pattern: `declared and not used`, Severity: 4, AutoFix: true, Component: RAGEngine},
	{Type: "GO_IMPORT_ERROR", Pattern: `cannot find package`, Severity: 1, AutoFix: true, Component: RAGEngine},
}
```

