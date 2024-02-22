# Initialize global variables
$currentDateTime = Get-Date -Format "yyyyMMddTHHmmss"
$outputFile = ".\" + $currentDateTime + "_tree.txt"
$lockedFiles = @()
$archiveFolder = ".\Archive"

function MoveTreeFilesToArchive {
    # Ensure the Archive folder exists
    if (-not (Test-Path -Path $archiveFolder)) {
        New-Item -ItemType Directory -Path $archiveFolder
    }

    # Find and move _tree.txt files to Archive
    Get-ChildItem -Path ".\" -Filter "*_tree.txt" | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $archiveFolder
    }
}

function DisplayTree {
    param (
        [string]$path,
        [string]$indent="",
        [bool]$isRoot=$false,
        [bool]$isLastChild=$false
    )

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
        # Skip directories named 'Archive'
        if ($dir.Name -eq "Archive") {
            continue
        }
        $count++
        $isLast = ($count -eq $total)
        $line = "${indent}${prefix} $($dir.Name)"
        Write-Host $line
        Add-Content -Path $outputFile -Value $line

        if ($dir.Name -eq "node_modules" -or $dir.Name -eq "build" -or $dir.Name -eq "amplify") {
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
        # Skip files with certain conditions
        if ($file.Name -match '^(nu|Nu|NU)' -or 
            $file.Name -match '_tree\.txt$' -or 
            $file.Name -eq 'README.md' -or 
            $file.Name -eq 'LICENSE' -or 
            $file.Extension -eq '.png' -or 
            $file.Name -eq 'reportWebVitals.js' -or 
            $file.Name -eq '.eslintrc.js' -or 
            $file.Extension -eq '.jpg') {
            continue
        }

        $count++
        $isLast = ($count -eq $total)
        $line = "${indent}${prefix} $($file.Name)"
        Write-Host $line
        Add-Content -Path $outputFile -Value $line
    }
}

# Move _tree.txt files to Archive before generating the new tree
MoveTreeFilesToArchive

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
