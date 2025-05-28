package debug

type EmailSenderComponent int

const (
    RAGEngine EmailSenderComponent = iota
    N8NWorkflow
    NotionAPI
    GmailProcessing
    PowerShellScript
    ConfigFiles
)

type EmailSenderError struct {
    Type      string
    Message   string
    File      string
    Line      int
    Component EmailSenderComponent
    Severity  int
}
