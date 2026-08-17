$ErrorActionPreference = 'Stop'

Write-Host '=== Taskora financial functions deploy ===' -ForegroundColor Cyan

if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    throw 'Supabase CLI bulunamadı. Önce Supabase CLI kurulu ve PATH üzerinde olmalı.'
}

supabase functions deploy create-payment-intent
if ($LASTEXITCODE -ne 0) { throw 'create-payment-intent deploy başarısız.' }

supabase functions deploy stripe-webhook --no-verify-jwt
if ($LASTEXITCODE -ne 0) { throw 'stripe-webhook deploy başarısız.' }

supabase functions deploy verify-iap-purchase
if ($LASTEXITCODE -ne 0) { throw 'verify-iap-purchase deploy başarısız.' }

Write-Host ''
Write-Host 'Deploy tamamlandı.' -ForegroundColor Green
Write-Host 'Stripe secret/webhook secret ve Google/Apple IAP secretları ayrıca Supabase Secrets olarak tanımlanmalıdır.' -ForegroundColor Yellow
