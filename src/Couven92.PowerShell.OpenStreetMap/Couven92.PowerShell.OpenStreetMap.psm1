$rootItem = Get-Item $PSScriptRoot
foreach ($childItem in ($rootItem | Get-ChildItem -File -Recurse)) {
    if ($childItem.BaseName -ieq $rootItem.BaseName) {
        continue
    }
    . $childItem.FullName
}
