# Serves the site at http://localhost:8765/ for testing in a browser.
# (Chrome extensions can't open file:// pages.) Stop with Ctrl+C.
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\serve.ps1
param([int]$Port = 8765)

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$types = @{ ".html" = "text/html; charset=utf-8"; ".jpg" = "image/jpeg"; ".webp" = "image/webp";
            ".png" = "image/png"; ".svg" = "image/svg+xml"; ".xml" = "application/xml"; ".txt" = "text/plain";
            ".woff2" = "font/woff2"; ".js" = "text/javascript; charset=utf-8" }

$listener = New-Object Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Output "Serving $root at http://localhost:$Port/"

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
  if ($path -eq "") { $path = "index.html" }
  $file = Join-Path $root $path
  if ((Test-Path $file -PathType Leaf) -and (Resolve-Path $file).Path.StartsWith($root)) {
    $bytes = [IO.File]::ReadAllBytes($file)
    $ext = [IO.Path]::GetExtension($file)
    if ($types.ContainsKey($ext)) { $ctx.Response.ContentType = $types[$ext] }
    $ctx.Response.Headers.Add("Cache-Control", "no-store")
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $ctx.Response.StatusCode = 404
  }
  $ctx.Response.Close()
}
