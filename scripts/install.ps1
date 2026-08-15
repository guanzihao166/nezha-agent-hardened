$ErrorActionPreference = "Stop"

$repo = "guanzihao166/nezha-agent-hardened"
$version = "v1.0.0-hardened"
$dir = "C:\NezhaAgent"
$bin = Join-Path $dir "nezha-agent.exe"

if (-not $env:NZ_SERVER) { throw "NZ_SERVER is required" }
if (-not $env:NZ_CLIENT_SECRET) { throw "NZ_CLIENT_SECRET is required" }

$service = Get-Service -Name nezha-agent -ErrorAction SilentlyContinue
if ($service) {
    Stop-Service -Name nezha-agent -Force -ErrorAction SilentlyContinue
    Set-Service -Name nezha-agent -StartupType Disabled -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}
Get-Process -Name nezha-agent -ErrorAction SilentlyContinue | Stop-Process -Force

New-Item -ItemType Directory -Force $dir | Out-Null
Remove-Item -Force $bin -ErrorAction SilentlyContinue
Invoke-WebRequest "https://github.com/$repo/releases/download/$version/nezha-agent_windows_amd64.exe" -OutFile $bin

Set-Location $dir
.\nezha-agent.exe service install
.\nezha-agent.exe service start

Write-Host "installed: $bin"
Get-FileHash $bin -Algorithm SHA256
