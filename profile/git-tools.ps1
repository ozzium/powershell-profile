# ==========================================
# Raven Git & GitHub Tools
# ==========================================

function Get-RavenRepoRoot {
    if (-not $env:RAVEN_PROFILE_ROOT) { return $null }

    $root = (Resolve-Path $env:RAVEN_PROFILE_ROOT -ErrorAction SilentlyContinue)?.Path
    if (-not $root) { return $null }

    if (Test-Path (Join-Path $root ".git")) {
        return $root
    }

    $parent = (Resolve-Path (Join-Path $root "..") -ErrorAction SilentlyContinue)?.Path
    if ($parent -and (Test-Path (Join-Path $parent ".git"))) {
        return $parent
    }

    return $null
}

function global:Invoke-RavenGit {
    param(
        [Parameter(Mandatory)]
        [string[]]$Args
    )

    $repo = Get-RavenRepoRoot

    if (-not $repo -or -not (Test-Path $repo)) {
        Write-Warning "Git repo not found."
        return
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning "Git is not installed or not available in PATH."
        return
    }

    Push-Location $repo

    try {
        & git @Args
    }
    catch {
        Write-Warning "Git command failed: $($_.Exception.Message)"
    }
    finally {
        Pop-Location
    }
}

function global:Wait-RavenGit {
    Write-Host ""
    Read-Host "Press Enter to continue..."
}

function Show-RavenGitStatus {
    Invoke-RavenGit @("status")
    Wait-RavenGit
}

function global:Update-RavenLocalProfile {
    $repo = Get-RavenRepoRoot
    if (-not $repo) {
        Write-Warning "Raven repo not found."
        Wait-RavenGit
        return
    }

    Push-Location $repo
    try {
        Write-Host "Pulling latest Raven profile..." -ForegroundColor Cyan
        & git pull
        if ($LASTEXITCODE -ne 0) { throw "git pull failed." }

        Write-Host ""
        Write-Host "Reloading profile..." -ForegroundColor Cyan

        if (Get-Command reload-profile -ErrorAction SilentlyContinue) {
            reload-profile
        } else {
            . $PROFILE
        }

        Write-Host "Local profile updated and reloaded. ✅" -ForegroundColor Green
    }
    catch {
        Write-Warning "Update local profile failed: $($_.Exception.Message)"
    }
    finally {
        Pop-Location
        Wait-RavenGit
    }
}

function global:Update-RavenGitHubVersion {
    $repo = Get-RavenRepoRoot
    if (-not $repo) {
        Write-Warning "Raven repo not found."
        Wait-RavenGit
        return
    }

    Push-Location $repo
    try {
        Write-Host "Current repo status:" -ForegroundColor Cyan
        & git status --short

        Write-Host ""
        $msg = Read-Host "Commit message"

        if (-not $msg) {
            $msg = "Raven update $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        }

        & git add -A
        if ($LASTEXITCODE -ne 0) { throw "git add failed." }

        & git diff --cached --quiet
        if ($LASTEXITCODE -eq 0) {
            Write-Host "No staged changes to commit." -ForegroundColor Yellow
        } else {
            & git commit -m $msg
            if ($LASTEXITCODE -ne 0) { throw "git commit failed." }
        }

        & git push
        if ($LASTEXITCODE -ne 0) { throw "git push failed." }

        Write-Host "GitHub version updated. ✅" -ForegroundColor Green
    }
    catch {
        Write-Warning "Update GitHub version failed: $($_.Exception.Message)"
    }
    finally {
        Pop-Location
        Wait-RavenGit
    }
}

function global:Show-RavenGitMenu {
    while ($true) {
        Clear-Host

        $repo = Get-RavenRepoRoot
        $repoName = if ($repo) { Split-Path $repo -Leaf } else { "not found" }

        Write-Host "╭──────────────────────────────────────────────╮" -ForegroundColor DarkMagenta
        Write-Host "│ 🦇 Git & GitHub Tools                         │" -ForegroundColor Magenta
        Write-Host ("│ Repo: {0,-38} │" -f $repoName) -ForegroundColor DarkMagenta
        Write-Host "╰──────────────────────────────────────────────╯" -ForegroundColor DarkMagenta
        Write-Host ""

        Write-Host " 1) Status"
        Write-Host " 2) Update local profile      (pull + reload)"
        Write-Host " 3) Update GitHub version     (add + commit + push)"
        Write-Host " 4) Stage all"
        Write-Host " 5) Commit only"
        Write-Host " 6) Pull only"
        Write-Host " 7) Push only"
        Write-Host " 8) Fetch"
        Write-Host " 9) Log"
        Write-Host "10) Lazygit"
        Write-Host "11) Back"
        Write-Host ""

        $choice = Read-Host "Choose"

        switch ($choice) {
            "1" {
                Invoke-RavenGit @("status")
                Wait-RavenGit
            }

            "2" { Update-RavenLocalProfile }

            "3" { Update-RavenGitHubVersion }

            "4" {
                Invoke-RavenGit @("add","-A")
                Write-Host "Staged all changes." -ForegroundColor Green
                Wait-RavenGit
            }

            "5" {
                $msg = Read-Host "Commit message"
                if ($msg) {
                    Invoke-RavenGit @("commit","-m",$msg)
                }
                Wait-RavenGit
            }

            "6" {
                Invoke-RavenGit @("pull")
                Wait-RavenGit
            }

            "7" {
                Invoke-RavenGit @("push")
                Wait-RavenGit
            }

            "8" {
                Invoke-RavenGit @("fetch","--all","--prune")
                Wait-RavenGit
            }

            "9" {
                Invoke-RavenGit @("log", "--oneline", "--graph", "--decorate", "-n", "15")
                Wait-RavenGit
        }
            "10" {
                if (Get-Command lazygit -ErrorAction SilentlyContinue) {
                    $repo = Get-RavenRepoRoot
                    Push-Location $repo
                    try { lazygit }
                    finally { Pop-Location }
                } else {
                    Write-Warning "lazygit not found. Install it first."
                    Wait-RavenGit
                }
            }

            "11" { return }

            default {
                Write-Host "Invalid option." -ForegroundColor Red
                Start-Sleep -Milliseconds 600
            }
        }
    }
}