$null = Get-Process "eMotion LV1*" | Where-Object {$_.MainWindowHandle -ne [System.IntPtr]::Zero} | ForEach-Object {$_.CloseMainWindow()}
$null = Get-Process "Reaper*" | Where-Object {$_.MainWindowHandle -ne [System.IntPtr]::Zero} | ForEach-Object {$_.CloseMainWindow()}
$null = Get-Process "Smaart*" | Where-Object {$_.MainWindowHandle -ne [System.IntPtr]::Zero} | ForEach-Object {$_.CloseMainWindow()}
$null = Get-Process "VNC-Viewer*" | Where-Object {$_.MainWindowHandle -ne [System.IntPtr]::Zero} | ForEach-Object {$_.CloseMainWindow()}
$null = Get-Process "Spotify*" | Where-Object {$_.MainWindowHandle -ne [System.IntPtr]::Zero} | ForEach-Object {$_.CloseMainWindow()}
