---
description: Access Roo Code's AI assistance directly in your editor with Code Actions. Get instant fixes, explanations, and improvements through VSCode's lightbulb system.
keywords: code actions,quick fixes,lightbulb menu,AI assistance,VSCode integration,code improvements,error fixes
image: /img/social-share.jpg
---

# Code Actions


Code Actions provide instant access to Roo Code's AI assistance directly within your code editor through VSCode's lightbulb (quick fix) system. This context-aware feature automatically detects relevant code situations and offers appropriate AI-powered actions without requiring you to switch to the chat interface.



## What are Code Actions?​


Code Actions appear as a lightbulb icon (💡) in the editor gutter (the area to the left of the line numbers). They can also be accessed via the right-click context menu, or via keyboard shortcut. They are triggered when:


- You select a range of code.
- Your cursor is on a line with a problem (error, warning, or hint).
- You invoke them via command.


Clicking the lightbulb, right-clicking and selecting "Roo Code", or using the keyboard shortcut (Ctrl+. or Cmd+. on macOS, by default), displays a menu of available actions.



## Roo Code's Code Actions​


Roo Code provides 5 code actions, though their availability varies by context:


### Context Menu Actions (Right-Click)​


- Add to Context: Quickly adds the selected code to your chat with Roo, including the filename and line numbers so Roo knows exactly where the code is from. It's listed first in the menu for easy access.
- Explain Code: Asks Roo Code to explain the selected code.
- Improve Code: Asks Roo Code to suggest improvements to the selected code.


### Additional Actions​


- Fix Code: Available through the lightbulb menu and command palette (but not the right-click menu). Asks Roo Code to fix problems in the selected code.
- New Task: Creates a new task with the selected code. Available through the command palette.


### Context-Aware Actions​


The lightbulb menu intelligently shows different actions based on your code's current state:


For Code with Problems (when VSCode shows red/yellow squiggles):


- Fix Code - Get step-by-step guidance to resolve the specific error or warning
- Add to Context - Add the problematic code to Roo's context for discussion


For Clean Code (no diagnostics):


- Explain Code - Get detailed explanations of what the code does
- Improve Code - Receive optimization suggestions and best practices
- Add to Context - Add the code to Roo's context for further work


For more details on how diagnostics are integrated with Code Actions, see Diagnostics Integration.


### Add to Context Deep Dive​


The Add to Context action is listed first in the Code Actions menu so you can quickly add code snippets to your conversation. When you use it, Roo Code includes the filename and line numbers along with the code.


This helps Roo understand the exact context of your code within the project, allowing it to provide more relevant and accurate assistance.


Example Chat Input:



(Where @myFile.js:15:25 represents the code added via "Add to Context")



## Using Code Actions​


There are three main ways to use Roo Code's Code Actions:


### 1. From the Lightbulb (💡)​


1. Select Code: Select the code you want to work with. You can select a single line, multiple lines, or an entire block of code.
2. Look for the Lightbulb: A lightbulb icon will appear in the gutter next to the selected code (or the line with the error/warning).
3. Click the Lightbulb: Click the lightbulb icon to open the Code Actions menu.
4. Choose an Action: Select the desired Roo Code action from the menu.
5. Review and Approve: Roo Code will propose a solution in the chat panel. Review the proposed changes and approve or reject them.


### 2. From the Right-Click Context Menu​


1. Select Code: Select the code you want to work with.
2. Right-Click: Right-click on the selected code to open the context menu.
3. Choose "Roo Code": Select the "Roo Code" option from the context menu. A submenu will appear with the available Roo Code actions.
4. Choose an Action: Select the desired action from the submenu.
5. Review and Approve: Roo Code will propose a solution in the chat panel. Review the proposed changes and approve or reject them.


### 3. From the Command Palette​


1. Select Code: Select the code you want to work with.
2. Open the Command Palette: Press Ctrl+Shift+P (Windows/Linux) or Cmd+Shift+P (macOS).
3. Type a Command: Type "Roo Code" to filter the commands, then choose the relevant code action (e.g., "Roo Code: Explain Code"). The action will apply in the most logical context (usually the current active chat task, if one exists).
4. Review and Approve: Roo Code will propose a solution in the chat panel. Review the proposed changes and approve or reject them.



## Terminal Actions​


Roo Code also provides similar actions for terminal output:


- Terminal: Add to Context: Adds selected terminal output to your chat
- Terminal: Fix Command: Asks Roo Code to fix a failed terminal command
- Terminal: Explain Command: Asks Roo Code to explain terminal output or commands


These actions are available when you select text in the terminal and right-click.



## Disabling/Enabling Code Actions​


You can control Code Actions through VSCode settings:


### Enable/Disable Code Actions​


- Setting: roo-cline.enableCodeActions
- Default: Enabled
- Description: Controls whether Roo Code quick fix options appear in the editor


To access this setting:


1. Open VSCode Settings (Ctrl/Cmd + ,)
2. Search for "enableCodeActions"
3. Toggle the checkbox to enable or disable



## Customizing Code Action Prompts​


You can customize the prompts used for each Code Action by modifying the "Support Prompts" in the Prompts tab. This allows you to fine-tune the instructions given to the AI model and tailor the responses to your specific needs.


1. Open the Prompts Tab: Click the  icon in the Roo Code top menu bar.
2. Find "Support Prompts": You will see the support prompts, including "Enhance Prompt", "Explain Code", "Improve Code", and "Fix Code".
3. Edit the Prompts: Modify the text in the text area for the prompt you want to customize. The prompts use placeholders in the format ${placeholder}:

${filePath} - The path of the current file
${selectedText} - The currently selected text
${diagnostics} - Any error or warning messages (for Fix Code) - see Diagnostics Integration for details


4. Click "Done": Save your changes.


### Example Prompt Template​



By using Roo Code's Code Actions, you can quickly get AI-powered assistance directly within your coding workflow. This can save you time and help you write better code.



## Related Features​


- Diagnostics Integration - Learn how Roo Code integrates with VSCode's Problems panel
- Context Mentions - Discover other ways to provide context to Roo Code