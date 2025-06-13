# Conventions de nommage pour EMAIL_SENDER_1

*Version 1.0 - 2025-05-15*

Ce document définit les conventions de nommage standardisées pour le projet EMAIL_SENDER_1. Ces conventions s'appliquent à tous les langages et technologies utilisés dans le projet, avec des spécificités pour chaque langage.

## Principes généraux

### Lisibilité et clarté

- Utiliser des noms descriptifs qui expliquent clairement le but de l'élément
- Éviter les abréviations sauf si elles sont très courantes et claires
- Préférer la clarté à la concision

### Cohérence

- Utiliser les mêmes termes pour les mêmes concepts dans tout le projet
- Suivre les conventions spécifiques à chaque langage
- Maintenir la cohérence entre les différents modules et composants

### Spécificité

- Éviter les noms génériques comme `data`, `temp`, `obj`, etc.
- Utiliser des noms spécifiques qui décrivent précisément le contenu ou le but
- Inclure des informations sur le type ou la nature de l'élément quand c'est pertinent

## Conventions pour PowerShell

### Fonctions et cmdlets

#### Verbes approuvés

Toutes les fonctions doivent commencer par un verbe approuvé par PowerShell. Voici les principaux verbes à utiliser :

| Verbe | Utilisation | Exemple |
|-------|-------------|---------|
| `New` | Créer un nouvel objet | `New-EmailTemplate` |
| `Get` | Récupérer des informations | `Get-EmailStatus` |
| `Set` | Définir une propriété ou un état | `Set-EmailConfig` |
| `Add` | Ajouter quelque chose à un objet existant | `Add-EmailAttachment` |
| `Remove` | Supprimer quelque chose d'un objet | `Remove-EmailAttachment` |
| `Start` | Démarrer un processus ou une opération | `Start-EmailSender` |
| `Stop` | Arrêter un processus ou une opération | `Stop-EmailSender` |
| `Import` | Importer des données | `Import-EmailContacts` |
| `Export` | Exporter des données | `Export-EmailStats` |
| `Test` | Tester ou valider | `Test-EmailConnection` |
| `Convert` | Convertir d'un format à un autre | `Convert-EmailToHtml` |
| `Send` | Envoyer quelque chose | `Send-Email` |
| `Invoke` | Exécuter une opération | `Invoke-EmailWorkflow` |

> **📖 Documentation complète** : Pour la liste exhaustive des verbes approuvés, leurs descriptions détaillées, les correspondances avec les verbes non approuvés, et des exemples pratiques, consultez le **[Guide des Verbes Approuvés PowerShell](./PowerShell-Verbes-Approuves.md)**.

Pour la liste complète des verbes approuvés, utiliser la commande `Get-Verb` dans PowerShell.

#### Format des noms de fonctions

Les noms de fonctions doivent suivre le format `Verbe-Nom` en utilisant le PascalCase :

```powershell
function Get-EmailTemplate { ... }
function Send-NotificationEmail { ... }
function Test-SmtpConnection { ... }
```plaintext
#### Paramètres

Les paramètres doivent utiliser le PascalCase et être descriptifs :

```powershell
function Send-Email {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Recipient,

        [Parameter(Mandatory = $true)]
        [string]$Subject,

        [Parameter(Mandatory = $true)]
        [string]$Body,

        [Parameter(Mandatory = $false)]
        [string[]]$Attachments,

        [Parameter(Mandatory = $false)]
        [switch]$IsHtml
    )
    # ...

}
```plaintext
### Variables

#### Variables globales et de script

- Utiliser le PascalCase pour les variables globales et de script
- Préfixer les variables de script avec `$script:`
- Préfixer les variables globales avec `$global:`

```powershell
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$global:EmailSenderVersion = "1.0.0"
```plaintext
#### Variables locales

- Utiliser le camelCase pour les variables locales
- Utiliser des noms descriptifs qui indiquent le contenu ou le but

```powershell
$emailTemplate = Get-EmailTemplate -Name "Welcome"
$recipientList = Import-Csv -Path $RecipientPath
$isValidEmail = Test-EmailAddress -Email $email
```plaintext
#### Constantes

- Utiliser MAJUSCULES_AVEC_UNDERSCORES pour les constantes
- Préfixer les constantes de script avec `$script:`

```powershell
$script:DEFAULT_SENDER = "noreply@example.com"
$script:MAX_RETRY_COUNT = 3
$script:EMAIL_TYPES = @("Notification", "Newsletter", "Transactional")
```plaintext
#### Variables spéciales

Utiliser des préfixes spécifiques pour certains types de variables :

| Préfixe | Type | Exemple |
|---------|------|---------|
| `is`, `has`, `should` | Booléens | `$isValid`, `$hasAttachments`, `$shouldRetry` |
| `temp` | Variables temporaires | `$tempFile`, `$tempResult` |
| `_` | Variables privées dans une fonction | `$_config`, `$_state` |

#### Collections

- Utiliser des noms au pluriel pour les collections
- Utiliser des noms au singulier pour les éléments d'itération

```powershell
$emails = Get-PendingEmails
foreach ($email in $emails) {
    Send-Email -Email $email
}
```plaintext
## Conventions pour Python

### Fonctions et méthodes

- Utiliser snake_case pour les noms de fonctions et méthodes
- Commencer par un verbe qui décrit l'action

```python
def send_email(recipient, subject, body):
    # ...

def get_email_status(email_id):
    # ...

def validate_email_address(email):
    # ...

```plaintext
### Classes

- Utiliser PascalCase pour les noms de classes
- Utiliser des noms descriptifs qui représentent ce que la classe modélise

```python
class EmailSender:
    # ...

class EmailTemplate:
    # ...

class SmtpConnection:
    # ...

```plaintext
### Variables et attributs

- Utiliser snake_case pour les variables et attributs
- Utiliser des noms descriptifs

```python
recipient_email = "user@example.com"
email_subject = "Welcome to our service"
is_valid_email = validate_email_address(recipient_email)
```plaintext
### Constantes

- Utiliser MAJUSCULES_AVEC_UNDERSCORES pour les constantes

```python
DEFAULT_SENDER = "noreply@example.com"
MAX_RETRY_COUNT = 3
EMAIL_TYPES = ["Notification", "Newsletter", "Transactional"]
```plaintext
## Conventions pour JavaScript/TypeScript

### Fonctions et méthodes

- Utiliser camelCase pour les noms de fonctions et méthodes
- Commencer par un verbe qui décrit l'action

```javascript
function sendEmail(recipient, subject, body) {
    // ...
}

function getEmailStatus(emailId) {
    // ...
}

function validateEmailAddress(email) {
    // ...
}
```plaintext
### Classes et composants React

- Utiliser PascalCase pour les noms de classes et composants React
- Utiliser des noms descriptifs

```javascript
class EmailSender {
    // ...
}

function EmailTemplate(props) {
    // ...
}

const EmailList = () => {
    // ...
};
```plaintext
### Variables

- Utiliser camelCase pour les variables
- Utiliser des noms descriptifs

```javascript
const recipientEmail = "user@example.com";
const emailSubject = "Welcome to our service";
const isValidEmail = validateEmailAddress(recipientEmail);
```plaintext
### Constantes

- Utiliser MAJUSCULES_AVEC_UNDERSCORES pour les constantes globales
- Utiliser camelCase pour les constantes locales

```javascript
const DEFAULT_SENDER = "noreply@example.com";
const MAX_RETRY_COUNT = 3;
const EMAIL_TYPES = ["Notification", "Newsletter", "Transactional"];
```plaintext
## Conventions pour les fichiers et dossiers

### Fichiers PowerShell

- Utiliser PascalCase pour les noms de fichiers de module (`.psm1`, `.psd1`)
- Utiliser le format `Verbe-Nom` pour les noms de fichiers de script (`.ps1`), identique au nom de la fonction principale qu'ils contiennent
- Utiliser l'extension `.ps1` pour les scripts, `.psm1` pour les modules et `.psd1` pour les manifestes

```plaintext
EmailSender.psm1
Send-BulkEmail.ps1
EmailSender.psd1
```plaintext
### Fichiers Python

- Utiliser snake_case pour les noms de fichiers
- Utiliser l'extension `.py`

```plaintext
email_sender.py
smtp_connection.py
email_template.py
```plaintext
### Fichiers JavaScript/TypeScript

- Utiliser kebab-case pour les noms de fichiers
- Utiliser l'extension `.js` pour JavaScript et `.ts` pour TypeScript
- Utiliser l'extension `.jsx` pour les composants React en JavaScript et `.tsx` pour les composants React en TypeScript

```plaintext
email-sender.js
email-template.tsx
smtp-connection.ts
```plaintext
### Dossiers

- Utiliser kebab-case pour les noms de dossiers
- Utiliser des noms descriptifs qui indiquent le contenu ou le but

```plaintext
email-templates/
smtp-connections/
email-logs/
```plaintext
## Exemples pratiques

### Exemple PowerShell

```powershell
function Send-NotificationEmail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Recipient,

        [Parameter(Mandatory = $true)]
        [string]$Subject,

        [Parameter(Mandatory = $true)]
        [string]$Body,

        [Parameter(Mandatory = $false)]
        [string[]]$Attachments,

        [Parameter(Mandatory = $false)]
        [switch]$IsHtml
    )

    $smtpConfig = Get-SmtpConfig
    $isValidEmail = Test-EmailAddress -Email $Recipient

    if (-not $isValidEmail) {
        throw "Invalid email address: $Recipient"
    }

    $emailParams = @{
        From = $script:DEFAULT_SENDER
        To = $Recipient
        Subject = $Subject
        Body = $Body
        IsHtml = $IsHtml
    }

    if ($Attachments) {
        $emailParams.Attachments = $Attachments
    }

    Send-MailMessage @emailParams -SmtpServer $smtpConfig.Server -Port $smtpConfig.Port
}
```plaintext
### Exemple Python

```python
class EmailSender:
    def __init__(self, smtp_config):
        self.smtp_config = smtp_config
        self.default_sender = "noreply@example.com"
        self.max_retry_count = 3

    def send_notification_email(self, recipient, subject, body, attachments=None, is_html=False):
        if not self._validate_email_address(recipient):
            raise ValueError(f"Invalid email address: {recipient}")

        email_message = self._create_email_message(recipient, subject, body, is_html)

        if attachments:
            for attachment_path in attachments:
                self._add_attachment(email_message, attachment_path)

        return self._send_email(email_message)

    def _validate_email_address(self, email):
        # Validation logic

        return True

    def _create_email_message(self, recipient, subject, body, is_html):
        # Create email message

        return {}

    def _add_attachment(self, email_message, attachment_path):
        # Add attachment

        pass

    def _send_email(self, email_message):
        # Send email

        return True
```plaintext
### Exemple JavaScript

```javascript
class EmailSender {
    constructor(smtpConfig) {
        this.smtpConfig = smtpConfig;
        this.defaultSender = "noreply@example.com";
        this.maxRetryCount = 3;
    }

    async sendNotificationEmail(recipient, subject, body, attachments = [], isHtml = false) {
        if (!this.validateEmailAddress(recipient)) {
            throw new Error(`Invalid email address: ${recipient}`);
        }

        const emailMessage = this.createEmailMessage(recipient, subject, body, isHtml);

        if (attachments.length > 0) {
            for (const attachmentPath of attachments) {
                this.addAttachment(emailMessage, attachmentPath);
            }
        }

        return await this.sendEmail(emailMessage);
    }

    validateEmailAddress(email) {
        // Validation logic
        return true;
    }

    createEmailMessage(recipient, subject, body, isHtml) {
        // Create email message
        return {};
    }

    addAttachment(emailMessage, attachmentPath) {
        // Add attachment
    }

    async sendEmail(emailMessage) {
        // Send email
        return true;
    }
}
```plaintext