$body = @{
    query = "삼성전자 주가"
    execute = $true
} | ConvertTo-Json -Compress

$bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
$result = Invoke-RestMethod -Uri 'http://localhost:8000/api/natural-language' -Method POST -ContentType 'application/json; charset=utf-8' -Body $bytes
$result | ConvertTo-Json -Depth 10
