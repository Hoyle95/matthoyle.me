# Takes a screenshot of a live website for the projects section and saves it
# as images/projects/<Name>.jpg (800x500, captured at a 1280x800 viewport).
#
# Runs headless Edge in *real* time via the DevTools protocol. (Plain
# `msedge --screenshot --virtual-time-budget` fakes time, so photos that load
# over the network never finish and show as grey/black placeholders.)
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\capture-thumbnail.ps1 `
#     -Url https://buzybeezcrafts.uk/ -Name buzybeez `
#     -NotReadySelector ".banner__collage-img:not(.is-loaded)"
#
# -NotReadySelector: optional CSS selector for elements that mean "still
#   loading"; capture waits until nothing matches it (and every <img> is complete).
param(
  [Parameter(Mandatory)][string]$Url,
  [Parameter(Mandatory)][string]$Name,
  [string]$NotReadySelector = "",
  [int]$MaxWaitSec = 90,
  [int]$Port = 9333
)

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outDir = Join-Path $root "images\projects"
New-Item -ItemType Directory -Force $outDir | Out-Null
$profileDir = Join-Path $env:TEMP "matthoyle-capture-$Port"

$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$proc = Start-Process -FilePath $edge -PassThru -WindowStyle Hidden -ArgumentList `
  "--headless=new", "--disable-gpu", "--hide-scrollbars", "--remote-debugging-port=$Port", `
  "--user-data-dir=$profileDir", "--window-size=1280,800", $Url
$sock = $null
try {
  $ws = $null
  for ($i = 0; $i -lt 30 -and -not $ws; $i++) {
    Start-Sleep -Milliseconds 500
    try {
      # PowerShell 5 passes a JSON array through as one object, so unroll it
      $targets = Invoke-RestMethod "http://127.0.0.1:$Port/json"
      $ws = ($targets | ForEach-Object { $_ } | Where-Object { $_.type -eq 'page' } | Select-Object -First 1).webSocketDebuggerUrl
    } catch {}
  }
  if (-not $ws) { throw "Couldn't reach Edge's DevTools endpoint" }

  $sock = New-Object Net.WebSockets.ClientWebSocket
  $sock.ConnectAsync([Uri]$ws, [Threading.CancellationToken]::None).Wait()
  $script:id = 0
  function Send-Cdp($method, $params) {
    $script:id++
    $msg = @{ id = $script:id; method = $method; params = $params } | ConvertTo-Json -Depth 5 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
    $sock.SendAsync([ArraySegment[byte]]$bytes, 'Text', $true, [Threading.CancellationToken]::None).Wait()
    while ($true) {
      $sb = New-Object Text.StringBuilder
      do {
        $buf = New-Object byte[] 1048576
        $res = $sock.ReceiveAsync([ArraySegment[byte]]$buf, [Threading.CancellationToken]::None).Result
        [void]$sb.Append([Text.Encoding]::UTF8.GetString($buf, 0, $res.Count))
      } while (-not $res.EndOfMessage)
      $obj = $sb.ToString() | ConvertFrom-Json
      if ($obj.id -eq $script:id) { return $obj }
    }
  }

  [void](Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 1280; height = 800; deviceScaleFactor = 1; mobile = $false })

  $sel = $NotReadySelector.Replace("\", "\\").Replace("'", "\'")
  $expr = "JSON.stringify({ imgs: [...document.images].every(i => i.complete), waiting: '$sel' ? document.querySelectorAll('$sel').length : 0 })"
  $start = Get-Date
  while ($true) {
    Start-Sleep -Seconds 2
    $state = (Send-Cdp 'Runtime.evaluate' @{ expression = $expr; returnByValue = $true }).result.result.value | ConvertFrom-Json
    $elapsed = [int]((Get-Date) - $start).TotalSeconds
    Write-Output "  ${elapsed}s: images complete=$($state.imgs), still loading=$($state.waiting)"
    if ($state.imgs -and $state.waiting -eq 0) { break }
    if ($elapsed -gt $MaxWaitSec) { Write-Output "  gave up waiting, capturing anyway"; break }
  }
  Start-Sleep -Seconds 2   # let fade-ins finish

  $shot = Send-Cdp 'Page.captureScreenshot' @{ format = 'png' }
  $png = [Convert]::FromBase64String($shot.result.data)

  # Resize to 800x500 JPEG with Windows' built-in imaging (no extra tools needed)
  Add-Type -AssemblyName PresentationCore
  $ms = New-Object IO.MemoryStream(, $png)
  $frame = [Windows.Media.Imaging.BitmapDecoder]::Create($ms, 'None', 'OnLoad').Frames[0]
  $scale = New-Object Windows.Media.ScaleTransform((800 / $frame.PixelWidth), (500 / $frame.PixelHeight))
  $enc = New-Object Windows.Media.Imaging.JpegBitmapEncoder
  $enc.QualityLevel = 82
  $enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create((New-Object Windows.Media.Imaging.TransformedBitmap($frame, $scale))))
  $outFile = Join-Path $outDir "$Name.jpg"
  $fs = [IO.File]::Create($outFile)
  $enc.Save($fs)
  $fs.Close()
  Write-Output "Saved $outFile"
} finally {
  if ($sock) { $sock.Dispose() }
  Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
  Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" |
    Where-Object { $_.CommandLine -like "*matthoyle-capture-$Port*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}
