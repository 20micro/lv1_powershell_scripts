$null = Start-Process -FilePath "C:\Program Files (x86)\Waves\eMotion LV1\eMotion LV1.exe"
$null = Start-Process -FilePath "C:\Program Files\REAPER (x64)\reaper.exe"
$null = Start-Process -FilePath "C:\Program Files\Smaart Suite\Smaart.exe"
$null = Start-Process -FilePath "C:\Users\LV1\Desktop\VNC-Viewer-7.12.1-Windows-64bit.exe"
$null = Start-Process spotify
Start-Sleep(10)
$null = Move-Window -Hwnd ((Get-Process "eMotion LV1*")[0].MainWindowHandle) -Desktop (Get-Desktop 0)
Start-Sleep(1)
$null = Move-Window -Hwnd ((Get-Process "Reaper*")[0].MainWindowHandle) -Desktop (Get-Desktop 1)
Start-Sleep(1)
$null = Move-Window -Hwnd ((Get-Process "Smaart*")[0].MainWindowHandle) -Desktop (Get-Desktop 2)
Start-Sleep(1)
$null = Move-Window -Hwnd ((Get-Process "VNC-Viewer*")[0].MainWindowHandle) -Desktop (Get-Desktop 3)
Start-Sleep(1)
$null = Move-Window -Hwnd ((Get-Process "Spotify*")[0].MainWindowHandle) -Desktop (Get-Desktop 4)
