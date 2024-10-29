# Define the URLs for the MSI files and the ZIP file
$komorebiUrl = "https://github.com/LGUG2Z/komorebi/releases/download/nightly/komorebi-nightly-x86_64.msi"
$whkdApiUrl = "https://api.github.com/repos/LGUG2Z/whkd/releases/latest"
$yasbApiUrl = "https://api.github.com/repos/amnweb/yasb/releases/latest"
$dotfilesUrl = "https://github.com/amnweb/dotfiles/archive/refs/heads/main.zip"

# Fetch the latest release information for yasb and whkd
Write-Host "Fetching yasb release info..." -ForegroundColor Cyan -NoNewline
$yasbReleaseInfo = Invoke-RestMethod -Uri $yasbApiUrl -Headers @{ "User-Agent" = "PowerShell" }
Write-Host " OK" -ForegroundColor Cyan

Write-Host "Fetching whkd release info..." -ForegroundColor Cyan -NoNewline
$whkdReleaseInfo = Invoke-RestMethod -Uri $whkdApiUrl -Headers @{ "User-Agent" = "PowerShell" }
Write-Host " OK" -ForegroundColor Cyan

# Extract the download URLs for the MSI files
$yasbUrl = $yasbReleaseInfo.assets | Where-Object { $_.name -like "*.msi" } | Select-Object -ExpandProperty browser_download_url
$whkdUrl = $whkdReleaseInfo.assets | Where-Object { $_.name -like "*x86_64.msi" } | Select-Object -ExpandProperty browser_download_url

# Define the destination folder as the user's temporary directory
$destinationFolder = [System.IO.Path]::GetTempPath()

# Define the source folder inside the destination folder
$sourceFolder = Join-Path -Path $destinationFolder -ChildPath "source"

# Create the source folder if it doesn't exist, without outputting to the console
if (-Not (Test-Path -Path $sourceFolder)) {
    Write-Host "Creating source folder..." -ForegroundColor Yellow -NoNewline
    New-Item -ItemType Directory -Path $sourceFolder -Force > $null
    Write-Host " OK" -ForegroundColor Yellow
}

# Define the destination file paths inside the source folder
$komorebiFilePath = Join-Path -Path $sourceFolder -ChildPath "komorebi-nightly-x86_64.msi"
$yasbFilePath = Join-Path -Path $sourceFolder -ChildPath "yasb-latest-win64.msi"
$whkdFilePath = Join-Path -Path $sourceFolder -ChildPath "whkd-latest-x86_64.msi"
$dotfilesZipPath = Join-Path -Path $sourceFolder -ChildPath "dotfiles.zip"
$dotfilesExtractPath = Join-Path -Path $sourceFolder -ChildPath "dotfiles"

# Download the MSI files and the ZIP file
Write-Host "Downloading komorebi..." -ForegroundColor Green -NoNewline
Invoke-WebRequest -Uri $komorebiUrl -OutFile $komorebiFilePath
Write-Host " OK" -ForegroundColor Green

Write-Host "Downloading yasb..." -ForegroundColor Green -NoNewline
Invoke-WebRequest -Uri $yasbUrl -OutFile $yasbFilePath
Write-Host " OK" -ForegroundColor Green

Write-Host "Downloading whkd..." -ForegroundColor Green -NoNewline
Invoke-WebRequest -Uri $whkdUrl -OutFile $whkdFilePath
Write-Host " OK" -ForegroundColor Green

Write-Host "Downloading dotfiles..." -ForegroundColor Green -NoNewline
Invoke-WebRequest -Uri $dotfilesUrl -OutFile $dotfilesZipPath
Write-Host " OK" -ForegroundColor Green

# Extract the ZIP file to the dotfiles directory
Write-Host "Extracting dotfiles..." -ForegroundColor Magenta -NoNewline
Expand-Archive -Path $dotfilesZipPath -DestinationPath $dotfilesExtractPath -Force
Write-Host " OK" -ForegroundColor Magenta

# Copy all files from dotfiles/Pictures to the user's Pictures folder
$dotfilesPicturesPath = Join-Path -Path $dotfilesExtractPath -ChildPath "dotfiles-main\Pictures"
$userPicturesPath = Join-Path -Path $env:USERPROFILE -ChildPath "Pictures"
Write-Host "Copying pictures..." -ForegroundColor Blue -NoNewline
Copy-Item -Path "$dotfilesPicturesPath\*" -Destination $userPicturesPath -Recurse -Force
Write-Host " OK" -ForegroundColor Blue

# Copy the .config folder to the user's home directory
$dotfilesConfPath = Join-Path -Path $dotfilesExtractPath -ChildPath "dotfiles-main\.config"
$userConfPath = Join-Path -Path $env:USERPROFILE -ChildPath ".config"

# Ensure the .config directory exists
if (-Not (Test-Path -Path $userConfPath)) {
    New-Item -ItemType Directory -Path $userConfPath -Force > $null
}

Write-Host "Copying .config..." -ForegroundColor Blue -NoNewline
Copy-Item -Path "$dotfilesConfPath\*" -Destination $userConfPath -Recurse -Force
Write-Host " OK" -ForegroundColor Blue

# Set the wallpaper to forest_dark_winter.jpg
$wallpaperPath = Join-Path -Path $userPicturesPath -ChildPath "forest_dark_winter.jpg"
if (Test-Path $wallpaperPath) {
    Write-Host "Setting wallpaper..." -ForegroundColor Green -NoNewline
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@
    $null = [Wallpaper]::SystemParametersInfo(0x0014, 0, $wallpaperPath, 0x0001)
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host "Wallpaper forest_dark_winter.jpg not found in Pictures folder" -ForegroundColor Red
}

# Close the yasb.exe process if it is running
$yasbProcess = Get-Process -Name "yasb" -ErrorAction SilentlyContinue
if ($yasbProcess) {
    Write-Host "Stopping yasb process..." -ForegroundColor Yellow -NoNewline
    Stop-Process -Name "yasb" -Force > $null 2>&1
    Write-Host " OK" -ForegroundColor Yellow
}

# Run komorebic stop --whkd if komorebic exists
if (Get-Command "komorebic" -ErrorAction SilentlyContinue) {
    try {
        Write-Host "Stopping komorebic..." -ForegroundColor Yellow -NoNewline
        & komorebic stop --whkd > $null 2>&1
        Write-Host " OK" -ForegroundColor Yellow
    } catch {
        Write-Host "Failed to stop komorebic: $_" -ForegroundColor Red
    }
}

# Install the MSI files using msiexec
Write-Host "Installing komorebi..." -ForegroundColor Green -NoNewline
Start-Process msiexec.exe -ArgumentList "/i `"$komorebiFilePath`" /quiet /norestart" -NoNewWindow -Wait
Write-Host " OK" -ForegroundColor Green

Write-Host "Installing yasb..." -ForegroundColor Green -NoNewline
Start-Process msiexec.exe -ArgumentList "/i `"$yasbFilePath`" /quiet /norestart" -NoNewWindow -Wait
Write-Host " OK" -ForegroundColor Green

Write-Host "Installing whkd..." -ForegroundColor Green -NoNewline
Start-Process msiexec.exe -ArgumentList "/i `"$whkdFilePath`" /quiet /norestart" -NoNewWindow -Wait
Write-Host " OK" -ForegroundColor Green

# Set KOMOREBI_CONFIG_HOME environment variable for the current session
Write-Host "Setting Komorebi config location..." -ForegroundColor DarkGreen -NoNewline
$komorebiConfigHome = Join-Path -Path $env:USERPROFILE -ChildPath ".config"
$env:KOMOREBI_CONFIG_HOME = $komorebiConfigHome
[System.Environment]::SetEnvironmentVariable("KOMOREBI_CONFIG_HOME", $komorebiConfigHome, [System.EnvironmentVariableTarget]::User)
Write-Host " OK" -ForegroundColor DarkGreen

# Run komorebic start --whkd
if (Get-Command "komorebic" -ErrorAction SilentlyContinue) {
    try {
        Write-Host "Starting Komorebi with WHKD..." -ForegroundColor Green -NoNewline
        & komorebic start --whkd > $null 2>&1
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host "Failed to start komorebic: $_" -ForegroundColor Red
    }
}

# Run yasb
$yasbShortcutPath = Join-Path -Path $env:APPDATA -ChildPath "Microsoft\Windows\Start Menu\Programs\Yasb.lnk"
if (Test-Path $yasbShortcutPath) {
    Write-Host "Starting Yasb..." -ForegroundColor Green -NoNewline
    Start-Process -FilePath $yasbShortcutPath > $null 2>&1
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host "Yasb shortcut not found at $yasbShortcutPath" -ForegroundColor Red
}
