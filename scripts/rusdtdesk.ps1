$ErrorActionPreference = "Continue"

# 1. Setup Variables
$url = "https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.exe"
$installerPath = "$env:TEMP\rustdesk.exe"
$installFolder = "C:\Program Files\RustDesk"
$programExe = "$installFolder\rustdesk.exe"
$logFile = "$env:GITHUB_WORKSPACE\RustDesk_Credentials.txt"

# 2. Download
Write-Host "[+] Downloading RustDesk..."
Invoke-WebRequest -Uri $url -OutFile $installerPath

# 3. Install
Write-Host "[+] Installing RustDesk..."
Start-Process -FilePath $installerPath -ArgumentList "--silent-install"

# 4. Wait for installation
Write-Host "[+] Waiting for installation to finish..."
$timeout = 0
while (-not (Test-Path $programExe)) {
    Start-Sleep -Seconds 2
    $timeout++
    if ($timeout -gt 30) {
        Write-Host "[!] Timed out waiting for RustDesk install"
        break
    }
}

if (Test-Path $programExe) {

    Write-Host "[+] RustDesk binary detected"
    Start-Sleep -Seconds 5

    # 6. Launch app
    Write-Host "[+] Launching RustDesk..."
    Start-Process -FilePath $programExe -WorkingDirectory $installFolder

    Write-Host "[+] Waiting 15 seconds for network..."
    Start-Sleep -Seconds 15

    # 7. Set password
    $randomPassword = -join ((48..57)+(65..90)+(97..122) | Get-Random -Count 12 | ForEach-Object {[char]$_})
    Write-Host "[+] Setting password..."
    Start-Process -FilePath $programExe `
        -ArgumentList "--password", $randomPassword `
        -WorkingDirectory $installFolder `
        -Wait `
        -WindowStyle Hidden

    # 8. Get ID
    Write-Host "[+] Retrieving RustDesk ID..."
    $rustDeskID = "Unknown"

    for ($i=1; $i -le 5; $i++) {
        $raw = & $programExe --get-id 2>&1 | Out-String
        $raw = $raw.Trim()
        Write-Host "[DEBUG] Output attempt $i: $raw"

        if ($raw -match "\d{6,}") {
            $rustDeskID = [regex]::Match($raw, "\d{6,}").Value
            break
        }
        Start-Sleep -Seconds 2
    }

    # 9. Print results
    Write-Host "========================================"
    Write-Host " RUSTDESK RESULT"
    Write-Host "========================================"
    Write-Host " ID       : $rustDeskID"
    Write-Host " Password : $randomPassword"
    Write-Host "========================================"

    # Save file
    "RustDesk ID: $rustDeskID" | Out-File $logFile
    "Password: $randomPassword" | Out-File $logFile -Append
    "Date: $(Get-Date)" | Out-File $logFile -Append

    Write-Host "[+] Credentials saved to $logFile"

} else {
    Write-Host "[!] Installation failed — rustdesk.exe not found"
}

# Cleanup
Remove-Item $installerPath -ErrorAction SilentlyContinue
