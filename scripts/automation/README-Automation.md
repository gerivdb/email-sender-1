# Automation Directory Organization

## Overview
This directory contains all automation scripts and related files organized in a hierarchical, functional structure for better maintainability and functionality separation.

## Directory Structure

### `/core/`
**Production-ready automation scripts and modules**
- `Fix-PowerShellFunctionNames-Modular.ps1` - Main PowerShell function name fixing script
- `modules/` - Core reusable modules and libraries
  - `ModuleAnalyzer.psm1` - Core module analysis functionality
  - `FunctionNameValidator.psm1` - Function name validation logic
  - `ConfigManager.psm1` - Configuration management utilities

### `/agents/`
**AI and agent-based automation scripts**

#### `/agents/classification/`
- `Auto-ClassifyScripts.ps1` - Automatic script classification system

#### `/agents/segmentation/`
- `Initialize-AgentAutoSegmentation.ps1` - Initialize automatic segmentation
- `Segment-AgentAutoInput.ps1` - Process input segmentation
- `Test-InputSegmentation.ps1` - Test segmentation functionality

#### `/agents/monitoring/`
- `Register-InventoryWatcher.ps1` - Register file inventory monitoring

### `/ui/`
**User interface automation scripts**
- `automate-chat-buttons.ps1` - Chat interface button automation

### `/testing/`
**Test scripts and validation tools**
- `test-modules.ps1` - Module testing framework
- `test-script-with-violations.ps1` - Test script with known violations
- `compare-versions.ps1` - Version comparison utilities

### `/docs/`
**Documentation and planning files**
- `README-Modular.md` - Modular system documentation
- `RÉSUMÉ-MODULARISATION.md` - Modularization summary (French)
- `ARCHIVAGE-COMPLET.md` - Complete archiving documentation
- `PLAN-ORGANISATION-AVANCEE.md` - Advanced organization planning

### `/backups/`
**Backup files and historical versions**
- `Auto-ClassifyScripts.ps1.bak` - Backup of classification script
- `Initialize-AgentAutoSegmentation.ps1.bak` - Backup of segmentation script

### `/archive/`
**Legacy versions and archived files**
- Contains historical versions of scripts for reference

## Usage Guidelines

### For Core Scripts
```powershell
# Run the main fixing script
.\core\Fix-PowerShellFunctionNames-Modular.ps1

# Import core modules
Import-Module .\core\modules\ModuleAnalyzer.psm1
```

### For Agent Scripts
```powershell
# Classification
.\agents\classification\Auto-ClassifyScripts.ps1

# Segmentation workflow
.\agents\segmentation\Initialize-AgentAutoSegmentation.ps1
.\agents\segmentation\Segment-AgentAutoInput.ps1
```

### For Testing
```powershell
# Run module tests
.\testing\test-modules.ps1

# Compare versions
.\testing\compare-versions.ps1
```

## Development Workflow

1. **Core Development**: Add production scripts to `/core/`
2. **Agent Development**: Add AI/automation scripts to appropriate `/agents/` subdirectory
3. **Testing**: Use `/testing/` for all test and validation scripts
4. **Documentation**: Update files in `/docs/` when making changes
5. **Backups**: Historical versions go in `/backups/`

## File Organization Rules

- **Functional Separation**: Scripts are organized by their primary function
- **Hierarchical Structure**: Related functionality is grouped in subdirectories
- **Clear Naming**: Directory and file names clearly indicate their purpose
- **Documentation**: Each major component has corresponding documentation
- **Version Control**: Backups and archives preserve historical versions

## Migration Notes

This structure consolidates automation scripts from:
- Original `scripts/automation/` directory
- `development/scripts/automation/` directory
- Various scattered automation files

All scripts maintain their functionality while being organized for better discoverability and maintenance.

## Next Steps

1. **Path Updates**: Update any hardcoded paths in scripts to reflect new organization
2. **Module Imports**: Verify all module import statements work with new structure
3. **Testing**: Run comprehensive tests to ensure all moved scripts function correctly
4. **Documentation**: Keep this README updated as new scripts are added

---
*Last Updated: 2025-05-24*
*Organization Version: 2.0 - Advanced Functional Structure*
*Status: ✅ COMPLETED - All scripts successfully reorganized and tested*
