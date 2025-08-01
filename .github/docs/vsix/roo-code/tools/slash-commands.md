---
description: Learn how to create and use custom slash commands in Roo Code to automate workflows and extend functionality with markdown-based definitions.
keywords: slash commands,custom commands,Roo Code commands,command automation,workflow automation,markdown commands,.roo/commands
image: /img/social-share.jpg
---

# Slash Commands


Create custom slash commands to automate repetitive tasks and extend Roo Code's functionality with simple markdown files.


Quick StartType / in the chat to see all available commands, or create your own by adding a markdown file to .roo/commands/ or ~/.roo/commands/!



## Overview​


Slash commands let you create reusable prompts and workflows that can be triggered instantly. Turn complex multi-step processes into single commands, standardize team practices, and automate repetitive tasks with simple markdown files.



Key Benefits:


- Workflow Automation: Turn complex multi-step processes into single commands
- Team Standardization: Share commands across your team for consistent practices
- Context Preservation: Include project-specific context in every command
- Quick Access: Fuzzy search and autocomplete for instant command discovery



## Creating Custom Commands​


Custom commands extend Roo Code's functionality by adding markdown files to specific directories:


- Project-specific: .roo/commands/ in your workspace root
- Global: ~/.roo/commands/ in your home directory


The filename becomes the command name. For example:


- review.md → /review
- test-api.md → /test-api
- deploy-check.md → /deploy-check


Command Name ProcessingWhen creating commands through the UI, command names are automatically processed:

- Converted to lowercase
- Spaces replaced with dashes
- Special characters removed
- Leading/trailing dashes removed

Example: "My Cool Command!" becomes my-cool-command


Basic Command Format


Create a simple command by adding a markdown file:



Advanced Command with Frontmatter


Add metadata using frontmatter for enhanced functionality:



Frontmatter Fields:


- description: Appears in the command menu to help users understand the command's purpose
- argument-hint: (Optional) Provides a hint about expected arguments when using the command. See Argument Hints for detailed information



## Command Management UI​


Roo Code provides a dedicated UI for managing custom commands.



Click the commands icon in the Roo Code panel to open the command manager


Creating a New Command:


1. Type your command name in the input field (e.g., "Sample command name")
2. Click the + button to create the command



1. A new file will be created and opened automatically (e.g., sample-command-name.md)




## Using Slash Commands​


Type / in the chat to see a unified menu containing both types of commands. The menu shows both custom workflow commands and mode-switching commands in the same interface.



1. Unified Menu: Both custom commands and mode-switching commands appear together
2. Autocomplete: Start typing to filter commands (e.g., /sam shows sample-command-name)
3. Fuzzy Search: Find commands even with partial matches
4. Description Preview: See command descriptions in the menu
5. Visual Indicators: Mode commands are distinguished from custom commands with special icons



## Argument Hints​


Argument hints provide instant help for slash commands, showing you what kind of information to provide when a command expects additional input.


When you type / to bring up the command menu, commands that expect arguments will display a light gray hint next to them. This hint tells you what kind of argument the command is expecting.


For example:


- /mode <mode_slug> - The hint <mode_slug> indicates you should provide a mode name like code or debug
- /api-endpoint <endpoint-name> <http-method> - Shows you need both an endpoint name and HTTP method


After selecting the command, it will be inserted into the chat input followed by a space. The hint is not inserted; it is only a visual guide to help you know what to type next. You must then manually type the argument after the command.


Adding Argument Hints to Custom Commands


You can add argument hints to your custom commands using the argument-hint field in the frontmatter:



This will display as /api-endpoint <endpoint-name> <http-method> in the command menu.


Best Practices for Argument Hints:


- Be Specific: Use descriptive placeholders like <file-path> instead of generic ones like <arg>
- Show Multiple Arguments: If your command needs multiple inputs, show them all: <source> <destination>
- Use Consistent Format: Always wrap placeholders in angle brackets: <placeholder>
- Keep It Concise: Hints should be brief and clear


Common Questions:


- "What if I don't provide the argument?" The command might not work as expected, or it might prompt you for more information. The hint is there to help you get it right the first time.
- "Do all commands have hints?" No, only commands that are designed to take arguments will have hints. Commands that work without additional input won't show hints.
- "Can I use a command without replacing the hint?" The hint text (like <mode_slug>) needs to be replaced with actual values. Leaving the hint text will likely cause the command to fail or behave unexpectedly.



## Examples and Use Cases​


Development Workflows


API Endpoint Generator



Database Migration Helper



Code Quality


Performance Analyzer



Refactoring Assistant



Documentation


README Generator



API Documentation



Testing


Test Generator



Test Coverage Analyzer




## Best Practices​


Command Naming:


- Use descriptive, action-oriented names
- Keep names concise but clear
- Use hyphens for multi-word commands
- Avoid generic names like help or test
- Note: Names are automatically slugified (lowercase, special characters removed)
- The .md extension is automatically added/removed as needed


Command Content:


- Start with a clear directive
- Use structured formats (lists, sections)
- Include specific requirements
- Reference project conventions
- Keep commands focused on a single task


Organization:


- Group related commands in subdirectories
- Use consistent naming patterns
- Document complex commands
- Version control your commands
- Share team commands in the project repository



## Troubleshooting​


Commands Not Appearing:


- Check file location: Ensure custom command files are in .roo/commands/ or ~/.roo/commands/
- Verify file extension: Custom commands must be .md files


Command Not Found:
When a slash command isn't found, the LLM will see:



Command Conflicts:


- Custom project commands override global custom commands with the same name
- Use unique names to avoid conflicts
- When creating duplicate names through the UI, numbers are appended (e.g., new-command-1, new-command-2)


About Mode CommandsThe slash menu includes mode-switching commands (like /code, /ask) that fundamentally change the AI's operational mode - they don't just inject text but switch the entire AI context. Custom modes you create also appear as slash commands (e.g., a mode with slug reviewer becomes /reviewer). These mode commands cannot be overridden by custom workflow commands. Learn more in Using Modes and Custom Modes.



## See Also​


- Using Modes - Learn about Roo Code's different operational modes
- Custom Instructions - Set persistent instructions for Roo Code
- Keyboard Shortcuts - Quick access to commands
- Task Management - Manage complex workflows