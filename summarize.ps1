# Define the output file path
$outputFile = "project_summary.txt"

# Get the full path of the script itself so we can exclude it
$scriptPath = $MyInvocation.MyCommand.Definition

# Define a list of file extensions to EXCLUDE.
$excludedExtensions = @(
    # Godot Specific Binaries & Metadata
    ".scn",       # Binary Scene (we want .tscn)
    ".res",       # Binary Resource (we want .tres)
    ".pck",       # Packed Data
    ".import",    # Godot Internal Import Settings
    ".uid",       # Godot 4 UID Cache
    
    # 3D Models & Assets
    ".glb", ".gltf", ".obj", ".fbx", ".blend", ".dae",
    
    # Images & Textures
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".tga", ".svg", ".ico", ".psd", ".webp",
    
    # Audio
    ".wav", ".ogg", ".mp3", ".flac",
    
    # General Binaries / Misc
    ".zip", ".gz", ".tar", ".exe", ".dll", ".so", ".a", ".lib", ".pdf", 
    ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", 
    ".ttf", ".otf", ".woff", ".woff2", ".eot", ".DS_Store"
)

# Initialize an array to hold all the file content
$allContent = @()

# Get all files recursively
Get-ChildItem -Recurse -File | Where-Object {
    
    # 1. EXCLUDE SELF AND OUTPUT FILE
    $_.FullName -ne $scriptPath -and
    $_.Name -ne $outputFile -and

    # 2. Exclude internal cache folders (.godot, .import) and Git
    $_.DirectoryName -notmatch "\\\.godot" -and 
    $_.DirectoryName -notmatch "\\\.import" -and
    $_.DirectoryName -notmatch "\\\.git" -and
    
    # 3. Check if the file's extension is NOT in the exclusion list
    $_.Extension -notin $excludedExtensions

} | ForEach-Object {
    
    # Read the entire content of the file
    $content = Get-Content $_.FullName -Raw

    # Trim whitespace
    if ($null -ne $content) {
        $content = $content.Trim()
    }

    # Ensure the content is not empty
    if (-not [string]::IsNullOrWhiteSpace($content)) {
        $allContent += "--- START FILE: $($_.FullName) ---"
        $allContent += $content
        $allContent += "--- END FILE: $($_.FullName) ---`n`n"
    }
}

# Write to output file using UTF-8
$allContent | Set-Content -Encoding UTF8 -Path $outputFile

Write-Host "Processing complete."
Write-Host "Ignored script: $scriptPath"
Write-Host "Output saved to: $outputFile"