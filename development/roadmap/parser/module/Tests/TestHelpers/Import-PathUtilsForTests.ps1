<#
.SYNOPSIS
    Helper script to import path utility functions for testing.

.DESCRIPTION
    This script imports all the path utility functions needed for testing.
    It's designed to be dot-sourced in test scripts.

.NOTES
    Author: RoadmapParser Team
    Version: 1.0
    Date: 2025-04-25
#>

# Get the module root path
$modulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent

# Define paths to the function files
$pathPermissionHelperPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\PathUtils\PathPermissionHelper.ps1"
$pathResolverPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\PathUtils\PathResolver.ps1"
$pathUtilsPublicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\PathUtils.ps1"

# Check if the files exist
if (-not (Test-Path -Path $pathPermissionHelperPath)) {
    throw "PathPermissionHelper.ps1 not found at: $pathPermissionHelperPath"
}

if (-not (Test-Path -Path $pathResolverPath)) {
    throw "PathResolver.ps1 not found at: $pathResolverPath"
}

if (-not (Test-Path -Path $pathUtilsPublicPath)) {
    throw "PathUtils.ps1 not found at: $pathUtilsPublicPath"
}

# Import the functions
. $pathPermissionHelperPath
. $pathResolverPath
. $pathUtilsPublicPath

# Export the functions for testing
Export-ModuleMember -Function Test-PathPermissions, Test-ReadAccess, Test-WriteAccess, Test-ExecuteAccess
Export-ModuleMember -Function Resolve-RelativePath, Resolve-AbsolutePath, Normalize-Path, Find-ProjectRoot
Export-ModuleMember -Function Initialize-Paths, Test-Paths, Repair-Paths, Get-AbsolutePath, Get-RelativePath
