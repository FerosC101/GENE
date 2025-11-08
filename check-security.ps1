# Security Check Script
# Run this before pushing to ensure no API keys are exposed

Write-Host "🔍 Checking for API keys in tracked files..." -ForegroundColor Yellow
Write-Host ""

# Check for API key patterns
$patterns = @("AIzaSy", "api_key", "API_KEY=", "apiKey:")
$foundKeys = $false

foreach ($pattern in $patterns) {
    Write-Host "Searching for pattern: $pattern" -ForegroundColor Cyan
    $results = git grep -i $pattern -- . ":(exclude)*.example" ":(exclude)*.md" ":(exclude)lib/firebase_options.dart" 2>$null
    
    if ($results) {
        Write-Host "⚠️  Found potential API keys:" -ForegroundColor Red
        Write-Host $results
        $foundKeys = $true
    }
}

if (-not $foundKeys) {
    Write-Host "✅ No exposed API keys found in tracked files!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ API keys detected! Review the files above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔒 Checking gitignored files..." -ForegroundColor Yellow
$ignoredFiles = @(".env", "android/local.properties", "android/app/google-services.json", "ios/Runner/GoogleService-Info.plist")

foreach ($file in $ignoredFiles) {
    if (Test-Path $file) {
        $ignored = git check-ignore $file 2>$null
        if ($ignored) {
            Write-Host "✅ $file is properly gitignored" -ForegroundColor Green
        } else {
            Write-Host "❌ $file is NOT gitignored!" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host ""
Write-Host "🎉 All security checks passed! Safe to push." -ForegroundColor Green
Write-Host ""
Write-Host "📝 Remember:" -ForegroundColor Yellow
Write-Host "  - Firebase keys in firebase_options.dart are safe (protected by Security Rules)"
Write-Host "  - Template files (*.example) are safe to commit"
Write-Host "  - Make sure .env and config files exist locally"
