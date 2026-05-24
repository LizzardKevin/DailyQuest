$ErrorActionPreference = "Stop"
$base = "https://daily-quest-api.dailyintent.workers.dev"
$deviceId = "smoke-" + [guid]::NewGuid().ToString("N").Substring(0, 16)
$questDay = (Get-Date).ToString("yyyy-MM-dd")
$headers = @{
    "X-Device-ID"  = $deviceId
    "X-Quest-Day"  = $questDay
    "Content-Type" = "application/json"
}

Write-Host "=== Smoke Test daily-quest-api ===" -ForegroundColor Cyan
Write-Host "Device: $deviceId  QuestDay: $questDay"

Write-Host "`n[1/5] GET /health" -ForegroundColor Yellow
$health = Invoke-RestMethod -Uri "$base/health" -Method GET
if (-not $health.ok) { throw "health failed" }
Write-Host "OK: service=$($health.service)"

Write-Host "`n[2/5] POST /v1/breakdown" -ForegroundColor Yellow
$breakdownBody = @{
    mainTask  = "Ship DailyQuest smoke test"
    sideTasks = @("Write docs")
} | ConvertTo-Json -Compress
$breakdown = Invoke-RestMethod -Uri "$base/v1/breakdown" -Method POST -Headers $headers -Body $breakdownBody
if ($breakdown.main.stages.Count -lt 2) { throw "breakdown missing stages" }
Write-Host "OK: main stages=$($breakdown.main.stages.Count) sides=$($breakdown.sides.Count)"

Write-Host "`n[3/5] POST /v1/medal/design (first)" -ForegroundColor Yellow
$medal1Body = @{
    mainTask         = "Ship DailyQuest smoke test"
    sideTasks        = @("Write docs")
    questDay         = $questDay
    forceRegenerate  = $false
} | ConvertTo-Json -Compress
$medal1 = Invoke-RestMethod -Uri "$base/v1/medal/design" -Method POST -Headers $headers -Body $medal1Body
Write-Host "OK: title=$($medal1.title) center=$($medal1.visual.centerObjectSymbol) ring=$($medal1.visual.ringElements.Count) source=$($medal1.source)"

Write-Host "`n[4/5] POST /v1/medal/design (cached)" -ForegroundColor Yellow
$medal2 = Invoke-RestMethod -Uri "$base/v1/medal/design" -Method POST -Headers $headers -Body $medal1Body
if ($medal1.title -ne $medal2.title) { throw "cache mismatch" }
Write-Host "OK: cache hit, same title"

Write-Host "`n[5/5] POST /v1/medal/design (forceRegenerate)" -ForegroundColor Yellow
$medal3Body = @{
    mainTask         = "Learn Swift concurrency"
    sideTasks        = @()
    questDay         = $questDay
    forceRegenerate  = $true
} | ConvertTo-Json -Compress
$medal3 = Invoke-RestMethod -Uri "$base/v1/medal/design" -Method POST -Headers $headers -Body $medal3Body
Write-Host "OK: title=$($medal3.title) center=$($medal3.visual.centerObjectSymbol)"
if (($medal1.title -eq $medal3.title) -and ($medal1.visual.centerObjectSymbol -eq $medal3.visual.centerObjectSymbol)) {
    Write-Host "WARN: regenerate matched first design (AI coincidence possible)" -ForegroundColor DarkYellow
} else {
    Write-Host "OK: regenerate differed from first claim"
}

Write-Host "`n=== All smoke checks passed ===" -ForegroundColor Green
