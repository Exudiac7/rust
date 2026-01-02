# 1. Setup Variables
$url = "https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.exe"
$installerPath = "$env:TEMP\rustdesk.exe"
$installFolder = "C:\Program Files\RustDesk"
$programExe = "$installFolder\rustdesk.exe"
$logFile = "$env:USERPROFILE\Desktop\RustDesk_Credentials.txt"

# 2. Download
Write-Host "Downloading RustDesk..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $url -OutFile $installerPath

# 3. Install (FIXED: Removed '-Wait' to prevent freezing)
Write-Host "Installing..." -ForegroundColor Cyan
Start-Process -FilePath $installerPath -ArgumentList "--silent-install" -Verb RunAs

# 4. Wait for File Creation (Watch the folder instead of the process)
Write-Host "Waiting for installation to finish..." -ForegroundColor Yellow
$timeout = 0
while (-not (Test-Path $programExe)) {
    Start-Sleep -Seconds 2
    $timeout++
    # If it takes longer than 60 seconds, stop waiting
    if ($timeout -gt 30) { 
        Write-Host "Timed out waiting for files." -ForegroundColor Red
        break 
    }
}

# 5. Wait a moment for files to settle
if (Test-Path $programExe) {
    Write-Host "Files detected. Waiting 5 seconds for setup to stabilize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5

    # === STEP 6: LAUNCH APP (Vital for ID Generation) ===
    Write-Host "Launching RustDesk to generate ID..." -ForegroundColor Cyan
    # We use WorkingDirectory so it finds its DLL files
    Start-Process -FilePath $programExe -WorkingDirectory $installFolder
    
    # Wait 15 seconds for it to connect to the internet
    Write-Host "Waiting 15 seconds for network connection..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15

    # === STEP 7: SET PASSWORD ===
    $randomPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 12 | % {[char]$_})
    
    Write-Host "Setting Password..." -ForegroundColor Cyan
    Start-Process -FilePath $programExe -ArgumentList "--password", $randomPassword -WorkingDirectory $installFolder -PassThru -Wait -WindowStyle Hidden

    # === STEP 8: GET ID ===
    Write-Host "Retrieving ID..." -ForegroundColor Cyan
    $rustDeskID = "Unknown"
    
    for ($i=1; $i -le 5; $i++) {
        $rawOutput = & $programExe --get-id 2>&1 | Out-String
        $cleanOutput = $rawOutput.Trim()
        
        if ($cleanOutput -match "\d{6,}") { 
            $rustDeskID = [regex]::Match($cleanOutput, "\d{6,}").Value
            break 
        }
        Start-Sleep -Seconds 2
    }

    # 9. PRINT RESULTS
    Clear-Host
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "         RUSTDESK SETUP COMPLETE" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host " ID       : $rustDeskID" -ForegroundColor Cyan
    Write-Host " Password : $randomPassword" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    
    # Save to file
    $logContent = "RustDesk ID: $rustDeskID`r`nPassword: $randomPassword`r`nDate: $(Get-Date)"
    Set-Content -Path $logFile -Value $logContent
    Write-Host "Credentials saved to: $logFile" -ForegroundColor Yellow

} else {
    Write-Host "Installation failed. The file $programExe was never created." -ForegroundColor Red
}

# Cleanup
Remove-Item -Path $installerPath -ErrorAction SilentlyContinue

# 10. Pause at the end
Write-Host ""
Read-Host -Prompt "Press Enter to exit"
