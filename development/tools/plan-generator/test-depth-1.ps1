# Test script for task depth 1
$goplangen = ".\goplangen.exe"
$depth = 1
$version = "depth-$depth"
$title = "Plan avec profondeur $depth"
$description = "Test profondeur $depth"
$phases = 2

Write-Host "Testing plan generation with depth $depth..."
& $goplangen -version $version -title $title -description $description -taskDepth $depth -phases $phases

Write-Host "Done!"
