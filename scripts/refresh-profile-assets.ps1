Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$readmePath = Join-Path $repoRoot "README.md"
$discordCardPath = Join-Path $repoRoot "assets\discord-server-card.svg"

$timestamp = [DateTime]::UtcNow.ToString("yyyyMMddHHmmss")
$inviteCode = "zzjYhtMGFD"
$inviteUrl = "https://discord.com/api/v9/invites/${inviteCode}?with_counts=true&with_expiration=true"

$dynamicHosts = @(
  "spotify-recently-played-readme.vercel.app",
  "lanyard.cnrad.dev",
  "streak-stats.demolab.com",
  "github-profile-summary-cards.vercel.app"
)

function Set-CacheBust([string]$url, [string]$stamp) {
  if ($url -match '([?&])v=\d+') {
    return [regex]::Replace($url, '([?&])v=\d+', "`$1v=$stamp")
  }

  if ($url.Contains("?")) {
    return "$url&v=$stamp"
  }

  return "$url?v=$stamp"
}

function Escape-Xml([string]$value) {
  return [System.Security.SecurityElement]::Escape($value)
}

$readmeContent = Get-Content -Raw $readmePath
$srcPattern = 'src="([^"]+)"'
$matchEvaluator = {
  param($match)

  $url = $match.Groups[1].Value

  try {
    $uri = [Uri]$url
  } catch {
    return $match.Value
  }

  if ($dynamicHosts -contains $uri.Host) {
    $updatedUrl = Set-CacheBust -url $url -stamp $timestamp
    return 'src="' + $updatedUrl + '"'
  }

  return $match.Value
}

$updatedReadme = [regex]::Replace($readmeContent, $srcPattern, $matchEvaluator)
if ($updatedReadme -ne $readmeContent) {
  Set-Content -Path $readmePath -Value $updatedReadme -NoNewline
}

$invite = Invoke-RestMethod -Uri $inviteUrl
$guildId = $invite.guild.id
$serverName = Escape-Xml $invite.guild.name
$serverDescription = "Discord server"
$onlineCount = [int]$invite.approximate_presence_count
$memberCount = [int]$invite.approximate_member_count
$inviteText = Escape-Xml "discord.gg/$inviteCode"

$iconHash = $invite.guild.icon
$iconBase64 = ""
if ($iconHash) {
  $iconUri = "https://cdn.discordapp.com/icons/$guildId/$iconHash.png?size=128"
  $iconBytes = (Invoke-WebRequest -Uri $iconUri).Content
  $iconBase64 = [Convert]::ToBase64String($iconBytes)
}

$iconImage = ""
if ($iconBase64) {
  $iconImage = '<image x="42" y="42" width="80" height="80" href="data:image/png;base64,' + $iconBase64 + '" />'
}

$discordSvg = @"
<svg width="760" height="180" viewBox="0 0 760 180" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="cardBg" x1="0" y1="0" x2="760" y2="180" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#141A2B" />
      <stop offset="1" stop-color="#0A0F1A" />
    </linearGradient>
    <linearGradient id="buttonBg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#7387FF" />
      <stop offset="1" stop-color="#5865F2" />
    </linearGradient>
    <filter id="softGlow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="8" result="blur" />
      <feMerge>
        <feMergeNode in="blur" />
        <feMergeNode in="SourceGraphic" />
      </feMerge>
    </filter>
  </defs>

  <rect x="4" y="4" width="752" height="172" rx="28" fill="url(#cardBg)" />
  <rect x="4.75" y="4.75" width="750.5" height="170.5" rx="27.25" stroke="#2A3350" stroke-width="1.5" />

  <rect x="30" y="30" width="104" height="104" rx="30" fill="#101525" />
  <rect x="31" y="31" width="102" height="102" rx="29" stroke="#323B59" stroke-width="2" />
  $iconImage

  <text x="162" y="58" fill="#F5F7FF" font-family="'Segoe UI', Tahoma, Geneva, Verdana, sans-serif" font-size="26" font-weight="700">$serverName</text>
  <text x="162" y="84" fill="#9AA3C3" font-family="'Segoe UI', Tahoma, Geneva, Verdana, sans-serif" font-size="16" font-weight="500">$serverDescription</text>

  <g>
    <rect x="162" y="102" width="138" height="28" rx="14" fill="#101A17" />
    <circle cx="181" cy="116" r="6" fill="#23A55A" />
    <text x="196" y="121" fill="#F5F7FF" font-family="'Segoe UI', Tahoma, Geneva, Verdana, sans-serif" font-size="16" font-weight="700">$onlineCount online</text>
  </g>

  <g>
    <rect x="312" y="102" width="178" height="28" rx="14" fill="#14182A" />
    <circle cx="331" cy="116" r="6" fill="#5865F2" />
    <text x="346" y="121" fill="#F5F7FF" font-family="'Segoe UI', Tahoma, Geneva, Verdana, sans-serif" font-size="16" font-weight="700">$("{0:N0}" -f $memberCount) members</text>
  </g>

  <rect x="162" y="142" width="220" height="26" rx="13" fill="#1C2440" />
  <text x="178" y="159" fill="#B8C1E3" font-family="'Segoe UI', Tahoma, Geneva, Verdana, sans-serif" font-size="14" font-weight="600">$inviteText</text>

  <g filter="url(#softGlow)">
    <rect x="562" y="46" width="150" height="50" rx="18" fill="url(#buttonBg)" />
  </g>
  <text x="596" y="77" fill="white" font-family="'Segoe UI', Tahoma, Geneva, Verdana, sans-serif" font-size="18" font-weight="700">Join Server</text>

  <text x="562" y="121" fill="#A6AFCF" font-family="'Segoe UI', Tahoma, Geneva, Verdana, sans-serif" font-size="14" font-weight="600">Auto-refreshed from invite</text>
  <text x="562" y="142" fill="#6F7897" font-family="'Segoe UI', Tahoma, Geneva, Verdana, sans-serif" font-size="13">Updated via GitHub Actions</text>
</svg>
"@

Set-Content -Path $discordCardPath -Value $discordSvg -NoNewline
