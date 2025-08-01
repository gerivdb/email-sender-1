---
description: Discover and install community-contributed MCP servers and custom modes from the Roo Code Marketplace to extend your AI coding assistant's capabilities.
keywords: Roo Code Marketplace,MCP servers,custom modes,extensions,community tools,AI integrations
image: /img/social-share.jpg
---

# Roo Code Marketplace





## Overview​


The Roo Code Marketplace is a central hub for discovering and installing community-contributed extensions, known as MCPs (Model Context Protocol) and Modes. It allows you to easily extend the functionality of Roo Code to fit your specific needs and workflows.


### Key Features​


- Discoverability: Browse a curated list of MCPs and Modes.
- Simple Installation: Install and remove items with a single click.
- Community-Driven: Access a growing collection of extensions from the Roo Code community.
- Project & Global Scopes: Install items for a specific project or for all your projects.



## Getting Started​


The Roo Code Marketplace is available directly within the Roo Code extension in VS Code. Access it by clicking the marketplace icon  in the top menu bar.



## Marketplace Items​


The marketplace offers two types of items:


### MCPs (Model Context Protocol)​


MCPs allow Roo Code to connect to and interact with various AI models, APIs, and other external tools. By installing an MCP, you can configure Roo Code to use different language models (like those from OpenAI, Anthropic, or others) or to integrate with other services. Learn more about What is MCP? and how to use MCP in Roo Code.



### Modes​


Modes are custom sets of instructions and rules that tailor Roo Code's behavior for specific tasks. For example, you might find a "React Component" mode that is optimized for creating React components, or a "Documentation Writer" mode for writing technical documentation. Learn more about using modes and creating custom modes.




## Installation Scope​


When you install an item from the marketplace, you can choose to install it at the project level or the global level.


### Project Installation​


- Scope: The item is only available within the current VS Code workspace (your project).
- Configuration File:

MCPs: .roo/mcp.json in the root of your project.
Modes: .roomodes in the root of your project.


- Use Case: This is useful when an item is specific to a particular project's needs or when you want to share a project-specific configuration with your team.


### Global Installation​


- Scope: The item is available across all your VS Code workspaces.
- Configuration File:

MCPs: mcp_settings.json in the Roo Code extension's global settings directory.
Modes: custom_modes.yaml in the Roo Code extension's global settings directory.


- Use Case: This is ideal for items that you want to use in all your projects, such as a favorite Mode or a commonly used MCP.



## Using the Marketplace​


### Browsing and Filtering​


You can browse all available items in the marketplace view. To find specific items:


- Search: Use the search bar to find items by name or description.
- Filter by Type: Show only MCPs or only Modes.
- Filter by Tags: Find items related to specific technologies or tasks.


### Installing an Item​


1. Find the item you want to install.
2. Click the "Install" button.
3. Choose whether to install it for the current Project or Globally.


#### Installing MCPs​



For MCPs, you may also need to:


- Select an installation method (NPX or Docker)
- Provide additional parameters when prompted (see Parameterized MCPs)


#### Installing Modes​



For Modes, simply select the installation scope and click Install.


1. Roo Code automatically adds the item to the appropriate configuration file. If the file doesn't exist, Roo Code will create it for you. The file is then opened for your review.


### Removing an Item​


1. Find the installed item in the marketplace view (installed items show a "Remove" button).
2. Click the "Remove" button.
3. If the item is installed in both scopes, choose to remove from the current project or remove globally.
4. Roo Code removes the item from the corresponding configuration file.


Note: The "Remove" button is context-aware. If an item is installed in only one scope (e.g., just for the project), it will be a single-action button. The dropdown menu with "Remove from Project" and "Remove Globally" options only appears if the item is installed in both scopes.


Important: The removal is immediate after you click the button or select an option from the dropdown. There is no additional confirmation prompt.


### Parameterized MCPs​



Some MCPs require specific information during installation, such as API keys or URLs. When installing these "parameterized" MCPs, you'll be prompted to:


- Review any prerequisites (like creating accounts or obtaining API keys)
- Enter required configuration values
- Select the installation method if applicable


This keeps sensitive information secure and makes configuration more flexible.



## Troubleshooting​


### Installation Errors​


- Invalid YAML/JSON: The configuration file (.roomodes, .roo/mcp.json, etc.) has a syntax error. To prevent data loss, Roo Code will not modify a corrupted configuration file. Please fix the syntax error before installing or removing items.
- File Not Found: Rare error - Roo Code automatically creates necessary configuration files.


### Item Not Working​


If an installed item isn't working:


1. Check the configuration file: Verify the item was added correctly.
2. Restart VS Code: New configurations sometimes require a restart.
3. Check prerequisites: Review the item's description for any requirements.
4. Check Roo Code logs: Look for error messages in the Roo Code output panel.



## Related Documentation​


### For MCPs​


- MCP Overview - Comprehensive guide to Model Context Protocol
- What is MCP? - Understanding the fundamentals
- Using MCP in Roo Code - Detailed configuration and usage guide
- Recommended MCP Servers - Curated list of tested servers


### For Modes​


- Using Modes - Learn about built-in modes and how to switch between them
- Custom Modes - Create and configure your own specialized modes