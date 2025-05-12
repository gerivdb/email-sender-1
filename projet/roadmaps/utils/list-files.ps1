Write-Host "Listing files in projet\roadmaps\json:"
Get-ChildItem -Path "..\..\roadmaps\json" -File | ForEach-Object {
    Write-Host "- $($_.Name) ($($_.Length) bytes)"
}

Write-Host "`nListing files in projet\roadmaps\examples:"
Get-ChildItem -Path "..\..\roadmaps\examples" -File | ForEach-Object {
    Write-Host "- $($_.Name) ($($_.Length) bytes)"
}

Write-Host "`nListing files in projet\roadmaps\tests:"
Get-ChildItem -Path "..\..\roadmaps\tests" -File | ForEach-Object {
    Write-Host "- $($_.Name) ($($_.Length) bytes)"
}

Write-Host "`nListing files in projet\roadmaps\reports:"
Get-ChildItem -Path "..\..\roadmaps\reports" -File | ForEach-Object {
    Write-Host "- $($_.Name) ($($_.Length) bytes)"
}
