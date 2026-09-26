#Requires -Version 5.1
<#
.SYNOPSIS
  Prepares local JobBoard env: copies .env.example and syncs .NET User Secrets.
#>
$ErrorActionPreference = "Stop"

$configDir = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $configDir
$envExample = Join-Path $configDir ".env.example"
$envFile = Join-Path $configDir ".env"
$apiProject = Join-Path $repoRoot "back\jobBoard-Api\jobBoard-Api\jobBoard-Api.csproj"

if (-not (Test-Path $envExample)) {
  throw ".env.example not found at $envExample"
}

if (-not (Test-Path $envFile)) {
  Copy-Item $envExample $envFile
  Write-Host "Created $envFile from .env.example"
} else {
  Write-Host "Using existing $envFile"
}

function Get-DotEnvValue([string]$path, [string]$key) {
  $line = Get-Content $path | Where-Object { $_ -match "^\s*$([regex]::Escape($key))\s*=" } | Select-Object -First 1
  if (-not $line) { return $null }
  return ($line -split "=", 2)[1].Trim().Trim('"').Trim("'")
}

if (-not (Test-Path $apiProject)) {
  Write-Warning "API project not found; skipped User Secrets sync."
  exit 0
}

$jwtKey = Get-DotEnvValue $envFile "Jwt__Key"
$pgHost = Get-DotEnvValue $envFile "POSTGRES_HOST"
if (-not $pgHost) { $pgHost = "localhost" }
$pgPort = Get-DotEnvValue $envFile "POSTGRES_PORT"
if (-not $pgPort) { $pgPort = "5434" }
$pgDb = Get-DotEnvValue $envFile "POSTGRES_DB"
$pgUser = Get-DotEnvValue $envFile "POSTGRES_USER"
$pgPassword = Get-DotEnvValue $envFile "POSTGRES_PASSWORD"
$minioAccess = Get-DotEnvValue $envFile "Minio__AccessKey"
if (-not $minioAccess) { $minioAccess = Get-DotEnvValue $envFile "MINIO_ROOT_USER" }
$minioSecret = Get-DotEnvValue $envFile "Minio__SecretKey"
if (-not $minioSecret) { $minioSecret = Get-DotEnvValue $envFile "MINIO_ROOT_PASSWORD" }
$minioEndpoint = Get-DotEnvValue $envFile "Minio__Endpoint"
if (-not $minioEndpoint) { $minioEndpoint = Get-DotEnvValue $envFile "MINIO_ENDPOINT" }
$minioBucket = Get-DotEnvValue $envFile "Minio__BucketName"
if (-not $minioBucket) { $minioBucket = Get-DotEnvValue $envFile "MINIO_BUCKET" }
$minioPublic = Get-DotEnvValue $envFile "Minio__PublicBaseUrl"
if (-not $minioPublic) { $minioPublic = Get-DotEnvValue $envFile "MINIO_PUBLIC_BASE_URL" }

$connection = Get-DotEnvValue $envFile "ConnectionStrings__DefaultConnection"
if (-not $connection) {
  $connection = "Host=$pgHost;Port=$pgPort;Database=$pgDb;Username=$pgUser;Password=$pgPassword"
}

Push-Location (Split-Path $apiProject)
try {
  if ($jwtKey) { dotnet user-secrets set "Jwt:Key" $jwtKey --project $apiProject | Out-Null }
  if ($connection) { dotnet user-secrets set "ConnectionStrings:DefaultConnection" $connection --project $apiProject | Out-Null }
  if ($minioAccess) { dotnet user-secrets set "Minio:AccessKey" $minioAccess --project $apiProject | Out-Null }
  if ($minioSecret) { dotnet user-secrets set "Minio:SecretKey" $minioSecret --project $apiProject | Out-Null }
  if ($minioEndpoint) { dotnet user-secrets set "Minio:Endpoint" $minioEndpoint --project $apiProject | Out-Null }
  if ($minioBucket) { dotnet user-secrets set "Minio:BucketName" $minioBucket --project $apiProject | Out-Null }
  if ($minioPublic) { dotnet user-secrets set "Minio:PublicBaseUrl" $minioPublic --project $apiProject | Out-Null }

  $emailProvider = Get-DotEnvValue $envFile "Email__Provider"
  $emailFrom = Get-DotEnvValue $envFile "Email__From"
  $emailFromName = Get-DotEnvValue $envFile "Email__FromName"
  $emailHost = Get-DotEnvValue $envFile "Email__Smtp__Host"
  $emailPort = Get-DotEnvValue $envFile "Email__Smtp__Port"
  $emailSsl = Get-DotEnvValue $envFile "Email__Smtp__UseSsl"
  $emailUser = Get-DotEnvValue $envFile "Email__Smtp__Username"
  $emailPass = Get-DotEnvValue $envFile "Email__Smtp__Password"
  if ($emailProvider) { dotnet user-secrets set "Email:Provider" $emailProvider --project $apiProject | Out-Null }
  if ($emailFrom) { dotnet user-secrets set "Email:From" $emailFrom --project $apiProject | Out-Null }
  if ($emailFromName) { dotnet user-secrets set "Email:FromName" $emailFromName --project $apiProject | Out-Null }
  if ($emailHost) { dotnet user-secrets set "Email:Smtp:Host" $emailHost --project $apiProject | Out-Null }
  if ($emailPort) { dotnet user-secrets set "Email:Smtp:Port" $emailPort --project $apiProject | Out-Null }
  if ($emailSsl) { dotnet user-secrets set "Email:Smtp:UseSsl" $emailSsl --project $apiProject | Out-Null }
  if ($emailUser) { dotnet user-secrets set "Email:Smtp:Username" $emailUser --project $apiProject | Out-Null }
  if ($emailPass) { dotnet user-secrets set "Email:Smtp:Password" $emailPass --project $apiProject | Out-Null }

  $appFrontend = Get-DotEnvValue $envFile "App__FrontendBaseUrl"
  $appResetMinutes = Get-DotEnvValue $envFile "App__PasswordResetTokenMinutes"
  if ($appFrontend) { dotnet user-secrets set "App:FrontendBaseUrl" $appFrontend --project $apiProject | Out-Null }
  if ($appResetMinutes) { dotnet user-secrets set "App:PasswordResetTokenMinutes" $appResetMinutes --project $apiProject | Out-Null }

  Write-Host "User Secrets synchronized from .env"
} finally {
  Pop-Location
}

Write-Host "Done. Start infra with: docker compose -f `"$configDir\docker-compose.yml`" --env-file `"$envFile`" up -d"
