---
description: Explore Roo Code's experimental features including concurrent file edits and power steering. Enable advanced capabilities that are still under development.
keywords: experimental features,Roo Code beta,advanced features,concurrent file edits,power steering,feature flags
image: /img/social-share.jpg
---

# Experimental Features


Roo Code includes experimental features that are still under development. These features may be unstable, change significantly, or be removed in future versions. Use them with caution and be aware that they may not work as expected.


Warning: Experimental features may have unexpected behavior, including potential data loss or security vulnerabilities. Enable them at your own risk.



## Enabling Experimental Features​


To enable or disable experimental features:


1. Open the Roo Code settings (<Codicon name="gear" /> icon in the top right corner).
2. Go to the "Advanced Settings" section.
3. Find the "Experimental Features" section.



## Current Experimental Features​


The following experimental features are currently available:


- Concurrent File Edits - Edit multiple files in a single operation
- Power Steering - Enhanced consistency in AI responses
- Background Editing - Work uninterrupted while Roo edits files in the background



## Providing Feedback​


If you encounter any issues with experimental features, or if you have suggestions for improvements, please report them on the Roo Code GitHub Issues page.


Your feedback is valuable and helps us improve Roo Code!

---
sidebar_label: Multi-File Edits
description: Speed up refactoring and multi-file changes with Roo Code's experimental Concurrent File Edits feature. Edit multiple files in a single operation with batch approval.
keywords: concurrent file edits,multi-file edits,batch editing,refactoring,Roo Code experimental features,apply_diff,batch approval
image: /img/social-share.jpg
---

# Concurrent File Edits (AKA Multi-File Edits)


Edit multiple files in a single operation, dramatically speeding up refactoring and multi-file changes.



## What It Does​



Concurrent File Edits allows Roo to modify multiple files in your workspace within a single request. Instead of approving each file edit individually, you review and approve all changes at once through a unified batch approval interface.



## Why Use It​


Traditional approach: Sequential file edits requiring individual approvals


- Edit file A → Approve
- Edit file B → Approve
- Edit file C → Approve


With Concurrent File Edits: All changes presented together


- Review all proposed changes across files A, B, and C
- Approve once to apply all changes


This reduces interruptions and speeds up complex tasks like:


- Refactoring functions across multiple files
- Updating configuration values throughout your codebase
- Renaming components and their references
- Applying consistent formatting or style changes



## How to Enable​


Experimental FeatureMulti-File Edits is an experimental feature and must be enabled in settings.

1. Open Roo Code settings (click the gear icon in Roo Code)
2. Navigate to Roo Code > Experimental Settings
3. Enable the Enable multi-file edits option



## Using the Feature​


When enabled, Roo automatically uses concurrent edits when appropriate. You'll see a "Batch Diff Approval" interface showing:


- All files to be modified
- Proposed changes for each file
- Options to approve all changes or review individually


### Example Workflow​


1. Ask Roo to "Update all API endpoints to use the new authentication method"
2. Roo analyzes your codebase and identifies all affected files
3. You receive a single batch approval request showing changes across:

src/api/users.js
src/api/products.js
src/api/orders.js
src/middleware/auth.js


4. Review all changes in the unified diff view
5. Approve to apply all changes simultaneously



## Technical Details​


This feature leverages the apply_diff tool's experimental multi-file capabilities. For detailed information about the implementation, XML format, and how the MultiFileSearchReplaceDiffStrategy works, see the apply_diff documentation.



## Best Practices​


### When to Enable​


- Using capable AI models (Claude 3.5 Sonnet, GPT-4, etc.)
- Comfortable reviewing multiple changes at once


### When to Keep Disabled​


- Working with less capable models that might struggle with complex multi-file contexts
- Prefer reviewing each change individually



## Limitations​


- Experimental: This feature is still being refined and may have edge cases
- Model dependent: Works best with more capable AI models
- Token usage: Initial requests may use more tokens due to larger context
- Complexity: Very large batch operations might be harder to review



## Troubleshooting​


### Changes Not Batching​


- Verify the experimental flag is enabled in settings
- Check that your model supports multi-file operations
- Ensure files aren't restricted by .rooignore


### Approval UI Not Appearing​


- Update to the latest version of Roo Code
- Check VS Code's output panel for errors
- Try disabling and re-enabling the feature


### Performance Issues​


- For very large batches, consider breaking the task into smaller chunks
- Monitor token usage if working with limited API quotas



## See Also​


- apply_diff Tool Documentation - Detailed technical information
- Experimental Features - Other experimental capabilities
- .rooignore Configuration - File access restrictions

---
sidebar_label: Power Steering
description: Improve Roo Code's response consistency with Power Steering. This experimental feature reinforces mode definitions and custom instructions for better adherence to assigned roles.
keywords: power steering,LLM consistency,mode adherence,custom instructions,experimental feature,token optimization,role definition
image: /img/social-share.jpg
---

# Power Steering (Experimental Feature)


The "Power Steering" experimental feature (POWER_STEERING) is designed to enhance the consistency of Roo Code's responses by more frequently reminding the underlying Large Language Model (LLM) about its current mode definition and any custom instructions.



## How It Works​


When Power Steering is enabled, Roo Code constantly reinforces the LLM's understanding of its assigned role (e.g., "You are a helpful coding assistant") and any specific guidelines provided by the user (e.g., "Always provide code examples in Python").


This is achieved by explicitly including the modeDetails.roleDefinition and modeDetails.customInstructions within the information sent to the LLM with each interaction.


Goal:
The primary goal is to ensure the LLM adheres more strictly to its defined persona and follows user-specific instructions more consistently. If you find Roo deviating from its role or overlooking custom rules, Power Steering can help maintain its focus.


Trade-off:
These frequent reminders consume additional tokens in each message sent to the LLM. This means:


- Increased token usage per message.
- Potentially higher operational costs.
- The context window may be filled more quickly.


It's a balance between stricter adherence to instructions and resource consumption.


Default Status: Disabled.



## Technical Details​


- Experiment ID: powerSteering
- Mechanism:

The feature's status is checked by the getEnvironmentDetails function.
If enabled, the current mode's roleDefinition and customInstructions are added to the details sent to the LLM.
These details are wrapped in <environment_details> tags and become part of the context for each LLM interaction.


- Impact: By frequently including the role definition and custom instructions, the LLM is steered to generate responses more aligned with these parameters.



## Enabling This Feature​


Power Steering is managed within the "Experimental Features" section of Roo Code's Advanced Settings.


1. Open Roo Code settings ( icon in the top right corner).
2. Navigate to "Advanced Settings".
3. Locate the "Experimental Features" area.
4. Toggle the "Power Steering" option.
5. Save your changes.



For general information on experimental features, see Experimental Features Overview.



## Feedback​


Please report any issues or suggestions regarding this feature on the Roo Code GitHub Issues page. Your feedback is crucial for improving Roo Code.

---
description: Learn about the experimental Background Editing setting that allows uninterrupted coding while Roo Code makes file edits in the background.
keywords: experimental features,editor focus,diff views,background editing,workflow optimization,uninterrupted coding
image: /img/social-share.jpg
---

# Background Editing


Work without interruption while Roo Code edits files in the background—no more losing focus from automatic diff views.


Experimental FeatureThis is an experimental feature that changes how file edits are displayed. While it can significantly improve workflow, you'll need to manually review changes through source control or file history.



## Overview​


The "Background Editing" setting is an experimental feature that disables automatic diff view displays when Roo Code edits files. Instead of switching your editor focus to show diffs, Roo works silently in the background, allowing you to continue coding without interruption. This feature affects all file editing operations including write, apply diff, search/replace, insert content, and multi-file apply diff tools.


### Key Benefits​


- Uninterrupted Focus: Stay in your current file while Roo makes changes
- Smoother Workflow: No context switching between files
- Background Processing: File edits happen silently
- Reduced Distractions: Maintain your coding flow
- Performance: Faster file operations without UI updates
- Batch Operations: Ideal for large refactoring or multiple file updates


### Trade-offs​


- No Visual Confirmation: You won't see diffs as changes are made
- Manual Review Required: Check changes through Git or file history
- Less Immediate Feedback: Changes aren't immediately visible
- Silent Changes: Files change without visual notification - check Git status regularly
- Limited Environment Context: Roo won't see recently edited files as open tabs in its environment details since they're not visually opened



## Enabling the Feature​


To enable Background Editing:


1. Open Roo Code settings (gear icon in the top right)
2. Navigate to the "Experimental" tab
3. Find "Background editing" in the list
4. Toggle the setting to enable it




## How It Works​


### Default Behavior (Feature Disabled)​


Without this feature, when Roo edits a file:


1. The file opens in your editor
2. A diff view appears showing changes
3. Your focus shifts to the modified file
4. You review and potentially adjust changes


### With Feature Enabled​


When enabled, Roo's file edits:


1. Happen silently in the background
2. Don't open new editor tabs
3. Don't show diff views
4. Don't interrupt your current work
5. Still open files in memory for diagnostic detection (not visible)


### What Still Happens​


Even with the feature enabled:


- Files are still modified on disk
- Changes appear in source control
- File watchers and build tools detect changes
- Roo's chat shows what files were edited
- Error detection and diagnostics continue to work normally
- Files are opened in memory for diagnostic purposes (not visible in editor)
- Write delays for diagnostic detection are still respected



## Best Use Cases​


This feature is particularly beneficial for:


- Large Refactoring Operations: When Roo needs to update many files
- Batch File Updates: Making similar changes across multiple files
- Performance-Sensitive Tasks: When UI updates would slow down operations
- Focused Coding Sessions: When you want to avoid context switches
- Automated Workflows: Running multiple file operations in sequence



## Best Practices​


When using this feature:


1. Use Version Control: Regularly check Git status to track changes
2. Review Periodically: Don't let too many changes accumulate without review
3. Enable Selectively: Consider enabling for specific task types
4. Monitor Chat: Pay attention to Roo's messages about file modifications
5. Check Diagnostics: Ensure your editor's problems panel stays visible



## FAQ​


Q: Can I still see what files Roo edited?
A: Yes, Roo's chat messages list all modified files, and changes appear in source control.


Q: What if I need to see a specific change immediately?
A: You can manually open the file and use source control to view the diff.


Q: Does this affect Roo's ability to edit files?
A: No, Roo can still make all the same edits; only the display behavior changes. All file editing tools (write, apply diff, search/replace, insert content, and multi-file apply diff) respect this setting.


Q: Can I enable this for specific projects only?
A: Currently, this is a global setting that affects all projects.


Q: What happens to approval dialogs?
A: File edit approvals still appear if you haven't auto-approved them; only the diff display is suppressed.


Q: Do diagnostics and error detection still work?
A: Yes, files are opened in memory for diagnostic detection, so error checking continues to function normally even though files aren't displayed.


Q: How does this feature appear in the settings?
A: In the Experimental tab, it's labeled as "Background editing" with a description about preventing editor focus disruption.