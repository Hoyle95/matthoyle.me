param([string]$Page = "index.html", [string[]]$Only = @(), [switch]$ReducedMotion, [switch]$NoJs, [switch]$Shots, [int]$Port = 9430)
# Emulates a range of phones, tablets and desktops in headless Edge and checks the page on each:
# JS errors, the terminal sequence finishing, name on one line, no sideways scroll, HUD corners not overlapping /
# on screen / readable over content, footer clear of the corners, and frame times during the intro.
# Needs the local server running first (tools\serve.ps1).
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\device-test.ps1            # all devices
#   ... -Only "iPhone 14","Desktop 1080p"   -ReducedMotion   -NoJs   -Shots (screenshots to %TEMP%\matthoyle-device-shots)
$ErrorActionPreference = "Stop"
$sp = Join-Path $env:TEMP "matthoyle-device-shots"
New-Item -ItemType Directory -Force $sp | Out-Null
$devices = @(
  @{ n = "iPhone SE (1st gen)"; w = 320;  h = 568;  d = 2;     m = $true;  cpu = 6 }
  @{ n = "Galaxy S (small)";    w = 360;  h = 780;  d = 3;     m = $true;  cpu = 4 }
  @{ n = "iPhone SE (3rd gen)"; w = 375;  h = 667;  d = 2;     m = $true;  cpu = 4 }
  @{ n = "iPhone 14";           w = 390;  h = 844;  d = 3;     m = $true;  cpu = 4 }
  @{ n = "Pixel 7";             w = 412;  h = 915;  d = 2.625; m = $true;  cpu = 4 }
  @{ n = "iPad Mini";           w = 768;  h = 1024; d = 2;     m = $true;  cpu = 2 }
  @{ n = "iPad Pro landscape";  w = 1366; h = 1024; d = 2;     m = $true;  cpu = 2 }
  @{ n = "Laptop";              w = 1366; h = 768;  d = 1;     m = $false; cpu = 1 }
  @{ n = "Desktop 1080p";       w = 1920; h = 1080; d = 1;     m = $false; cpu = 1 }
  @{ n = "Desktop 1440p";       w = 2560; h = 1440; d = 1;     m = $false; cpu = 1 }
)
# "powershell -File" passes -Only "a","b" as one "a,b" string, so split on commas
$Only = @($Only | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($Only.Count) {
  $allNames = $devices | ForEach-Object { $_.n }
  $devices = @($devices | Where-Object { $Only -contains $_.n })
  if (-not $devices.Count) { throw "No device matches -Only '$($Only -join "', '")'. Device names: $($allNames -join ', ')" }
}

$initScript = @'
window.__errors = [];
addEventListener('error', e => __errors.push(String(e.message || e.target?.src || 'resource error')), true);
addEventListener('unhandledrejection', e => __errors.push('promise: ' + e.reason));
const __ce = console.error; console.error = (...a) => { __errors.push('console: ' + a.join(' ')); __ce(...a); };
window.__frames = [];
(function f(t) { if (t < 4000) { __frames.push(t); requestAnimationFrame(f); } })(0);
'@

$checks = @'
(() => {
  const q = s => document.querySelector(s), all = s => [...document.querySelectorAll(s)];
  const name = q('#name'), fs = parseFloat(getComputedStyle(name).fontSize);
  const box = s => q(s).getBoundingClientRect();
  const overlap = (a, b) => a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom;
  const hudVisible = s => getComputedStyle(q(s)).display !== 'none';
  const tl = box('.hud.tl .hud-text'), tr = box('.hud.tr .hud-text'), bl = box('.hud.bl .hud-text'), br = box('.hud.br .hud-text');
  const introGaps = __frames.slice(1).map((t, i) => [__frames[i], t - __frames[i]]).filter(([s]) => s < 2500).map(([, g]) => g);
  const res = {
    errors: __errors.length ? __errors.join(' ; ') : 'none',
    sequenceDone: q('#projects').classList.contains('show'),
    cardsShown: all('.link-card, .project-card').every(c => getComputedStyle(c).opacity === '1'),
    nameOneLine: name.getBoundingClientRect().height < fs * 1.5,
    horizontalOverflow: document.documentElement.scrollWidth - innerWidth,
    hudTopOverlap: overlap(tl, tr),
    hudBottomOverlap: hudVisible('.hud.bl') && overlap(bl, br),
    hudCornersIn: [tl, tr, bl, br].every(r => r.left >= 0 && r.right <= innerWidth && r.top >= 0 && r.bottom <= innerHeight),
    introFrames: introGaps.length,
    introWorstFrameMs: Math.round(Math.max(...introGaps)),
    introJankFrames: introGaps.filter(g => g > 50).length,
    slowFrames: __frames.slice(1).map((t, i) => [Math.round(__frames[i]), Math.round(t - __frames[i])]).filter(([, g]) => g > 50).map(([s, g]) => g + 'ms@' + s).join(' '),
    firstFrameAt: Math.round(__frames[1] || 0),
    hudHasText: q('#server-time').textContent.startsWith('SERVER ') && q('#load').textContent !== '--',
  };
  scrollTo(0, document.documentElement.scrollHeight);
  const range = document.createRange(); range.selectNodeContents(q('footer'));
  const ft = range.getBoundingClientRect(), b1 = box('.hud.bl'), b2 = box('.hud.br');
  res.footerClear = !(overlap(ft, b1) || overlap(ft, b2));
  scrollTo(0, 0);
  return JSON.stringify(res);
})()
'@

$edgeExe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$edge = Start-Process -FilePath $edgeExe -PassThru -ArgumentList "--headless=new", "--hide-scrollbars", "--remote-debugging-port=$Port", "--user-data-dir=$env:TEMP\matthoyle-dev-$Port", "about:blank"
$sock = $null
try {
  $ws = $null
  for ($i = 0; $i -lt 40 -and -not $ws; $i++) {
    Start-Sleep -Milliseconds 500
    try { $ws = (Invoke-RestMethod "http://127.0.0.1:$Port/json" | ForEach-Object { $_ } | Where-Object { $_.type -eq 'page' } | Select-Object -First 1).webSocketDebuggerUrl } catch {}
  }
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
  [void](Send-Cdp 'Page.enable' @{})
  [void](Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = $initScript })
  if ($NoJs) { [void](Send-Cdp 'Emulation.setScriptExecutionDisabled' @{ value = $true }) }
  foreach ($d in $devices) {
    [void](Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = $d.w; height = $d.h; deviceScaleFactor = $d.d; mobile = $d.m })
    [void](Send-Cdp 'Emulation.setTouchEmulationEnabled' @{ enabled = $d.m; maxTouchPoints = $(if ($d.m) { 5 } else { 1 }) })
    # one call with every media feature: setEmulatedMedia replaces the whole list each time
    $features = @(@{ name = 'hover'; value = $(if ($d.m) { 'none' } else { 'hover' }) }, @{ name = 'pointer'; value = $(if ($d.m) { 'coarse' } else { 'fine' }) })
    if ($ReducedMotion) { $features += @{ name = 'prefers-reduced-motion'; value = 'reduce' } }
    [void](Send-Cdp 'Emulation.setEmulatedMedia' @{ features = $features })
    [void](Send-Cdp 'Emulation.setCPUThrottlingRate' @{ rate = $d.cpu })
    [void](Send-Cdp 'Page.navigate' @{ url = "http://localhost:8765/$Page" })
    # wait until the terminal sequence has finished (projects shown), then for the card animations; give up after 20s
    Start-Sleep -Seconds 1
    if ($NoJs) { Start-Sleep -Seconds 2 } else {
      $waited = Measure-Command {
        for ($t = 0; $t -lt 40; $t++) {
          $done = (Send-Cdp 'Runtime.evaluate' @{ expression = "!!document.querySelector('#projects.show')"; returnByValue = $true }).result.result.value
          if ($done) { break }
          Start-Sleep -Milliseconds 500
        }
      }
      Start-Sleep -Milliseconds 1500
    }
    if ($NoJs) {
      $v = (Send-Cdp 'Runtime.evaluate' @{ expression = "JSON.stringify({ aboutText: document.querySelector('#about').textContent.length, panelOpacity: getComputedStyle(document.querySelector('.panel')).opacity, cardsOpacity: [...document.querySelectorAll('.link-card, .project-card')].map(c => getComputedStyle(c).opacity).join(''), cmds: [...document.querySelectorAll('.queued-cmd')].map(p => getComputedStyle(p).visibility + ':' + p.textContent.trim()).join(' | '), hudText: getComputedStyle(document.querySelector('.hud-text')).opacity, name: document.querySelector('#name').textContent })"; returnByValue = $true }).result.result.value
    } else {
      $v = (Send-Cdp 'Runtime.evaluate' @{ expression = $checks; returnByValue = $true }).result.result.value
    }
    Write-Output ("{0,-20} {1}x{2}@{3} cpu{4}x  {5}" -f $d.n, $d.w, $d.h, $d.d, $d.cpu, $v)
    if ($Shots) {
      [void](Send-Cdp 'Emulation.setCPUThrottlingRate' @{ rate = 1 })
      Start-Sleep -Milliseconds 500
      $shot = Send-Cdp 'Page.captureScreenshot' @{ format = 'jpeg'; quality = 70 }
      $safe = ($d.n -replace '[^A-Za-z0-9]+', '-').Trim('-')
      [IO.File]::WriteAllBytes((Join-Path $sp "dev-$safe.jpg"), [Convert]::FromBase64String($shot.result.data))
    }
  }
} finally {
  if ($sock) { $sock.Dispose() }
  Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" | Where-Object { $_.CommandLine -like "*matthoyle-dev-$Port*" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}
