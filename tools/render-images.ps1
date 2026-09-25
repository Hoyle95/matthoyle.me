# Renders the site's generated images with headless Edge (no server needed):
#   tools/og-card.html    -> images/og-card.jpg      (1200x630 link-preview banner for Discord, X, iMessage...)
#   tools/touch-icon.html -> apple-touch-icon.png    (180x180 iPhone/iPad home-screen icon)
# Re-run after changing the name, tagline, photo or favicon:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\render-images.ps1
param([int]$Port = 9500)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$jobs = @(
  @{ page = "tools/og-card.html";    out = "images/og-card.jpg";   w = 1200; h = 630; format = "jpeg" }
  @{ page = "tools/touch-icon.html"; out = "apple-touch-icon.png"; w = 180;  h = 180; format = "png" }
)
$edgeExe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$profileDir = Join-Path $env:TEMP "matthoyle-render-$Port"
$edge = Start-Process -FilePath $edgeExe -PassThru -ArgumentList "--headless=new", "--hide-scrollbars", "--allow-file-access-from-files",
  "--remote-debugging-port=$Port", "--user-data-dir=$profileDir", "about:blank"
$sock = $null
try {
  $ws = $null
  for ($i = 0; $i -lt 40 -and -not $ws; $i++) {
    Start-Sleep -Milliseconds 500
    try { $ws = (Invoke-RestMethod "http://127.0.0.1:$Port/json" | ForEach-Object { $_ } | Where-Object { $_.type -eq 'page' } | Select-Object -First 1).webSocketDebuggerUrl } catch {}
  }
  if (-not $ws) { throw "Couldn't reach Edge's DevTools endpoint" }
  $sock = New-Object Net.WebSockets.ClientWebSocket
  $sock.ConnectAsync([Uri]$ws, [Threading.CancellationToken]::None).Wait()
  $script:id = 0
  $buf = New-Object byte[] 4194304
  function Send-Cdp($method, $params) {
    $script:id++
    $bytes = [Text.Encoding]::UTF8.GetBytes((@{ id = $script:id; method = $method; params = $params } | ConvertTo-Json -Depth 6 -Compress))
    $sock.SendAsync([ArraySegment[byte]]$bytes, 'Text', $true, [Threading.CancellationToken]::None).Wait()
    while ($true) {
      $ms = New-Object IO.MemoryStream
      do { $res = $sock.ReceiveAsync([ArraySegment[byte]]$buf, [Threading.CancellationToken]::None).Result; $ms.Write($buf, 0, $res.Count) } while (-not $res.EndOfMessage)
      $obj = [Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json
      if ($obj.id -eq $script:id) { return $obj }
    }
  }
  foreach ($j in $jobs) {
    [void](Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = $j.w; height = $j.h; deviceScaleFactor = 1; mobile = $false })
    $url = "file:///" + (Join-Path $root $j.page).Replace('\', '/')
    [void](Send-Cdp 'Page.navigate' @{ url = $url })
    # wait for fonts, images and the page's own ready flag
    for ($t = 0; $t -lt 40; $t++) {
      Start-Sleep -Milliseconds 250
      $ready = (Send-Cdp 'Runtime.evaluate' @{ expression = "!!window.__ready && [...document.images].every(i => i.complete && i.naturalWidth) && document.fonts.status === 'loaded'"; returnByValue = $true }).result.result.value
      if ($ready) { break }
    }
    if (-not $ready) { throw "$($j.page) didn't finish loading" }
    Start-Sleep -Milliseconds 300
    $params = @{ format = $j.format; clip = @{ x = 0; y = 0; width = $j.w; height = $j.h; scale = 1 } }
    if ($j.format -eq "jpeg") { $params.quality = 88 }
    $shot = Send-Cdp 'Page.captureScreenshot' $params
    $out = Join-Path $root $j.out
    [IO.File]::WriteAllBytes($out, [Convert]::FromBase64String($shot.result.data))
    Write-Output ("{0} ({1}x{2}, {3:n0} KB)" -f $j.out, $j.w, $j.h, ((Get-Item $out).Length / 1KB))
  }
} finally {
  if ($sock) { $sock.Dispose() }
  Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" | Where-Object { $_.CommandLine -like "*matthoyle-render-$Port*" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}
