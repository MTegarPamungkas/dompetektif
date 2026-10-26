# Publishes the web build to the gh-pages branch, which GitHub Pages serves at
# https://<owner>.github.io/<repo>/.
#
# When env.json exists, the build is connected to Supabase (cloud login and
# Google OAuth). Without it, the deployed app runs in local demo mode.
#
# Usage: pwsh tool/deploy_pages.ps1
param(
    [string]$Remote = "origin",
    [string]$Branch = "gh-pages",
    [string]$BaseHref = "",
    [string]$DartDefineFile = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    $url = git remote get-url $Remote
    if (-not $BaseHref) {
        $repoName = [System.IO.Path]::GetFileNameWithoutExtension(
            ($url -replace '\.git$', '')
        )
        $BaseHref = "/$repoName/"
    }
    if (-not $DartDefineFile -and (Test-Path "env.json")) {
        $DartDefineFile = "env.json"
    }

    Write-Host "Building web bundle with base href $BaseHref"
    $buildArgs = @(
        "build", "web", "--release",
        "--output", "build/web_pages",
        "--base-href", $BaseHref
    )
    if ($DartDefineFile) {
        Write-Host "Using Supabase configuration from $DartDefineFile"
        $buildArgs += "--dart-define-from-file=$DartDefineFile"
    }
    & flutter @buildArgs

    $stage = Join-Path $env:TEMP "dompetektif-pages"
    if (Test-Path $stage) {
        Remove-Item $stage -Recurse -Force
    }
    New-Item -ItemType Directory -Path $stage | Out-Null
    Copy-Item "build/web_pages/*" $stage -Recurse -Force
    New-Item -ItemType File -Path (Join-Path $stage ".nojekyll") | Out-Null

    Push-Location $stage
    try {
        git init -b $Branch | Out-Null
        git add -A
        git commit -m "Deploy web build" | Out-Null
        git remote add origin $url
        git push -f origin $Branch
    }
    finally {
        Pop-Location
    }
    Write-Host "Deployed $Branch to $url"
}
finally {
    Pop-Location
}
