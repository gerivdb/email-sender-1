---
description: Learn how to use custom instructions to tailor Roo Code's behavior to your preferences, coding style, and project requirements.
keywords: custom instructions,personalization,AI customization,coding preferences,project rules
image: /img/social-share.jpg
---

# Custom Instructions


Custom Instructions allow you to personalize how Roo behaves, providing specific guidance that shapes responses, coding style, and decision-making processes.


Instruction File LocationsYou can provide custom instructions using global rules (applied across all projects), workspace rules (project-specific), or through the Prompts tab interface.

Global Rules Directory: Apply to all projects automatically.

- Linux/macOS: ~/.roo/rules/ and ~/.roo/rules-{modeSlug}/
- Windows: %USERPROFILE%\.roo\rules\ and %USERPROFILE%\.roo\rules-{modeSlug}\

Workspace Rules: Apply only to the current project, can override global rules.

- Preferred Method: Directory (.roo/rules/)
.├── .roo/│   └── rules/          # Workspace-wide rules│       ├── 01-general.md│       └── 02-coding-style.txt└── ... (other project files)

- Fallback Method: Single File (.roorules)
.├── .roorules           # Workspace-wide rules (single file)└── ... (other project files)


Mode-Specific Instructions: Apply only to a specific mode (e.g., code).

- Preferred Method: Directory (.roo/rules-{modeSlug}/)
.├── .roo/│   └── rules-code/     # Rules for "code" mode│       ├── 01-js-style.md│       └── 02-ts-style.md└── ... (other project files)

- Fallback Method: Single File (.roorules-{modeSlug})
.├── .roorules-code      # Rules for "code" mode (single file)└── ... (other project files)


Rules are loaded in order: Global rules first, then workspace rules (which can override global rules). See Global Rules Directory for details.



## What Are Custom Instructions?​


Custom Instructions define specific behaviors, preferences, and constraints beyond Roo's basic role definition. Examples include coding style, documentation standards, testing requirements, and workflow guidelines.



## Setting Custom Instructions​


### Global Custom Instructions​


These instructions apply across all workspaces and maintain your preferences regardless of which project you're working on.


How to set them:



1. Open Prompts Tab: Click the  icon in the Roo Code top menu bar
2. Find Section: Find the "Custom Instructions for All Modes" section
3. Enter Instructions: Enter your instructions in the text area
4. Save Changes: Click "Done" to save your changes


### Global Rules Directory​


The Global Rules Directory feature provides reusable rules and custom instructions that automatically apply across all your projects. This system supports both global configurations and project-specific overrides.


#### Key Benefits​


Without Global Rules: You had to maintain separate rule files in each project:


- Copy the same rules to every new project
- Update rules manually across multiple projects
- No consistency between projects


With Global Rules: Create rules once and use them everywhere:


- Set up your preferred coding standards globally
- Override specific rules per project when needed
- Maintain consistency across all your work
- Easy to update rules for all projects at once


#### Directory Structure​


The global rules directory location is fixed and cannot be customized:


Linux/macOS:



Windows:



#### Setting Up Global Rules​


1. 
Create Global Rules Directory:
# Linux/macOSmkdir -p ~/.roo/rules# Windowsmkdir %USERPROFILE%\.roo\rules

2. 
Add General Rules (~/.roo/rules/coding-standards.md):
# Global Coding Standards1. Always use TypeScript for new projects2. Write unit tests for all new functions3. Use descriptive variable names4. Add JSDoc comments for public APIs

3. 
Add Mode-Specific Rules (~/.roo/rules-code/typescript-rules.md):
# TypeScript Code Mode Rules1. Use strict mode in tsconfig.json2. Prefer interfaces over type aliases for object shapes3. Always specify return types for functions



#### Available Rule Directories​


DirectoryPurpose`rules/`General rules applied to all modes`rules-code/`Rules specific to Code mode`rules-docs-extractor/`Rules for documentation extraction`rules-architect/`Rules for system architecture tasks`rules-debug/`Rules for debugging workflows`rules-{mode}/`Rules for any custom mode
#### Rule Loading Order​


Rules are loaded in this order:


1. Global Rules (from ~/.roo/)
2. Project Rules (from project/.roo/) - can override global rules
3. Legacy Files (.roorules, .clinerules - for backward compatibility)


Within each level, mode-specific rules are loaded before general rules.


### Workspace-Level Instructions​


These instructions only apply within your current workspace, allowing you to customize Roo Code's behavior for specific projects.


#### Workspace-Wide Instructions via Files/Directories​


Workspace-wide instructions apply to all modes within the current project and can be defined using files:


- Preferred Method: Directory-Based (.roo/rules/)

Create a directory named .roo/rules/ in your workspace root.
Place instruction files (e.g., .md, .txt) inside. Roo Code reads files recursively, appending their content to the system prompt in alphabetical order based on filename.
This method takes precedence if the directory exists and contains files.


- Fallback Method: File-Based (.roorules)

If .roo/rules/ doesn't exist or is empty, Roo Code looks for a single .roorules file in the workspace root.
If found, its content is loaded.




#### Mode-Specific Instructions​


Mode-specific instructions can be set in two independent ways that can be used simultaneously:


1. 
Using the Prompts Tab:



Open Tab: Click the  icon in the Roo Code top menu bar


Select Mode: Under the Modes heading, click the button for the mode you want to customize


Enter Instructions: Enter your instructions in the text area under "Mode-specific Custom Instructions (optional)"


Save Changes: Click "Done" to save your changes
Global Mode RulesIf the mode itself is global (not workspace-specific), any custom instructions you set for it will also apply globally for that mode across all workspaces.



2. 
Using Rule Files/Directories: Provide mode-specific instructions via files:

Preferred Method: Directory-Based (.roo/rules-{modeSlug}/)

Create a directory named .roo/rules-{modeSlug}/ (e.g., .roo/rules-docs-writer/) in your workspace root.
Place instruction files inside (recursive loading). Files are read and appended to the system prompt in alphabetical order by filename.
This method takes precedence over the fallback file method for the specific mode if the directory exists and contains files.


Fallback Method: File-Based (.roorules-{modeSlug})

If .roo/rules-{modeSlug}/ doesn't exist or is empty, Roo Code looks for a single .roorules-{modeSlug} file (e.g., .roorules-code) in the workspace root.
If found, its content is loaded for that mode.






Instructions from the Prompts tab, global rules, workspace rules, and mode-specific rules are all combined. See the section below for the exact order.



## How Instructions are Combined​


Instructions are placed in the system prompt in this exact format:



Note: Global rules load first, followed by workspace rules that can override them. Mode-specific rules appear before general rules within each level, and directory-based rules take precedence over file-based fallbacks.



## Rules about .rules files​


- File Location: The preferred method uses directories within .roo/ (.roo/rules/ and .roo/rules-{modeSlug}/). The fallback method uses single files (.roorules and .roorules-{modeSlug}) located directly in the workspace root.
- Empty Files: Empty or missing rule files are silently skipped
- Source Headers: Each rule file's contents are included with a header indicating its source
- Rule Interaction: Mode-specific rules complement global rules rather than replacing them



## Examples of Custom Instructions​


- "Always use spaces for indentation, with a width of 4 spaces"
- "Use camelCase for variable names"
- "Write unit tests for all new functions"
- "Explain your reasoning before providing code"
- "Focus on code readability and maintainability"
- "Prioritize using the most common library in the community"
- "When adding new features to websites, ensure they are responsive and accessible"


Pro Tip: Team StandardizationFor team environments, consider these approaches:

Project Standards: Use workspace .roo/rules/ directories under version control to standardize Roo's behavior for specific projects. This ensures consistent code style and development workflows across team members.

Organization Standards: Use global rules (~/.roo/rules/) to establish organization-wide coding standards that apply to all projects. Team members can set up identical global rules for consistency across all work.

Hybrid Approach: Combine global rules for organization standards with project-specific workspace rules for project-specific requirements. Workspace rules can override global rules when needed.

The directory-based approach offers better organization than single .roorules files and supports both global and project-level customization.



## Combining with Custom Modes​


For advanced customization, combine with Custom Modes to create specialized environments with specific tool access, file restrictions, and tailored instructions.