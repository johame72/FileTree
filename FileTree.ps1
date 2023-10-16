# Initialize global variables
$currentDateTime = Get-Date -Format "yyyyMMddTHHmmss"
$outputFile = ".\" + $currentDateTime + "_tree.txt"
$lockedFiles = @()

function DisplayTree {
    param (
        [string]$path,
        [string]$indent="",
        [bool]$isRoot=$false,
        [bool]$isLastChild=$false
    )

    # Max retries and delay settings
    $maxRetries = 5
    $delayInSeconds = 1

    # Prefix for the current line based on position in the tree
    $prefix = if ($isLastChild) { "\---" } else { "+---" }

    # Display and write the root directory if this is the first call to the function
    if ($isRoot) {
        try {
            $rootName = (Get-Item $path).Name
            Write-Host $rootName
            Add-Content -Path $outputFile -Value $rootName
        } catch {
            Write-Host "Error accessing ${path}: $_"
            $lockedFiles += $path
        }
    }

    # Display and write directories
    $directories = @(Get-ChildItem -Directory $path -ErrorAction SilentlyContinue)
    $count = 0
    $total = $directories.Length
    foreach ($dir in $directories) {
        $count++
        $isLast = ($count -eq $total)
        $line = "${indent}${prefix} $($dir.Name)"
        Write-Host $line
        Add-Content -Path $outputFile -Value $line

        if ($dir.Name -eq "node_modules") {
            continue
        }

        $newIndent = if ($isLast) { "${indent}    " } else { "${indent}|   " }
        DisplayTree -path $dir.FullName -indent $newIndent -isLastChild $isLast
    }

    # Display and write files
    $files = @(Get-ChildItem -File $path -ErrorAction SilentlyContinue)
    $count = 0
    $total = $files.Length
    foreach ($file in $files) {
        $count++
        $isLast = ($count -eq $total)
        $line = "${indent}${prefix} $($file.Name)"
        Write-Host $line
        Add-Content -Path $outputFile -Value $line
    }
}

# Clear existing content if the output file already exists
if (Test-Path $outputFile) {
    Clear-Content -Path $outputFile
}

# Run the function to generate the tree and save it to the file
DisplayTree -path ".\" -isRoot $true

# Display locked or unavailable files
if ($lockedFiles.Count -gt 0) {
    Write-Host "Locked or Unavailable Files:"
    $lockedFiles | ForEach-Object {
        Write-Host $_
    }
}
