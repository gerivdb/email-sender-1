---
description: Discover how Roo Code's Fast Edits feature uses diffs for faster, safer file modifications. Learn about match precision and configuration options.
keywords: fast edits,diff editing,file modifications,apply diff,match precision,editing efficiency,truncation prevention
image: /img/social-share.jpg
---

# Diff/Fast Edits


Default SettingFast Edits (using the "Enable editing through diffs" setting) is enabled by default in Roo Code. You typically don't need to change these settings unless you encounter specific issues or want to experiment with different diff strategies.


Roo Code offers an advanced setting to change how it edits files, using diffs (differences) instead of rewriting entire files. Enabling this feature provides significant benefits.


Per-Provider SettingDiff editing configuration is set per API Configuration Profile, allowing you to customize editing behavior for different providers and models.



## Enable Editing Through Diffs​


Open the Roo Code pane settings by clicking the gear icon . The Providers section will be visible. Select the specific API Configuration Profile you want to configure.


When Enable editing through diffs is checked:



1. Faster File Editing: Roo modifies files more quickly by applying only the necessary changes.
2. Prevents Truncated Writes: The system automatically detects and rejects attempts by the AI to write incomplete file content, which can happen with large files or complex instructions. This helps prevent corrupted files.


Disabling Fast EditsIf you uncheck Enable editing through diffs, Roo will revert to writing the entire file content for every edit using the write_to_file tool, instead of applying targeted changes with apply_diff. This full-write approach is generally slower for modifying existing files and leads to higher token usage.



## Match Precision​


This slider controls how closely the code sections identified by the AI must match the actual code in your file before a change is applied.



- 100% (Default): Requires an exact match. This is the safest option, minimizing the risk of incorrect changes.
- Lower Values (80%-99%): Allows for "fuzzy" matching. Roo can apply changes even if the code section has minor differences from what the AI expected. This can be useful if the file has been slightly modified, but increases the risk of applying changes in the wrong place.


Use values below 100% with extreme caution. Lower precision might be necessary occasionally, but always review the proposed changes carefully.


Internally, this setting adjusts a fuzzyMatchThreshold used with algorithms like Levenshtein distance to compare code similarity.