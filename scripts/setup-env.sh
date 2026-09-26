#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${CONFIG_DIR}/.." && pwd)"
ENV_EXAMPLE="${CONFIG_DIR}/.env.example"
ENV_FILE="${CONFIG_DIR}/.env"
API_PROJECT="${REPO_ROOT}/back/jobBoard-Api/jobBoard-Api/jobBoard-Api.csproj"

if [[ ! -f "${ENV_EXAMPLE}" ]]; then
  echo ".env.example not found at ${ENV_EXAMPLE}" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${ENV_EXAMPLE}" "${ENV_FILE}"
  echo "Created ${ENV_FILE} from .env.example"
else
  echo "Using existing ${ENV_FILE}"
fi

getenv() {
  local key="$1"
  local line
  line="$(grep -E "^[[:space:]]*${key}=" "${ENV_FILE}" | tail -n 1 || true)"
  if [[ -z "${line}" ]]; then
    echo ""
    return
  fi
  echo "${line#*=}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//"
}

if [[ ! -f "${API_PROJECT}" ]]; then
  echo "API project not found; skipped User Secrets sync."
  exit 0
fi

JWT_KEY="$(getenv Jwt__Key)"
PG_HOST="$(getenv POSTGRES_HOST)"; PG_HOST="${PG_HOST:-localhost}"
PG_PORT="$(getenv POSTGRES_PORT)"; PG_PORT="${PG_PORT:-5434}"
PG_DB="$(getenv POSTGRES_DB)"
PG_USER="$(getenv POSTGRES_USER)"
PG_PASSWORD="$(getenv POSTGRES_PASSWORD)"
MINIO_ACCESS="$(getenv Minio__AccessKey)"; MINIO_ACCESS="${MINIO_ACCESS:-$(getenv MINIO_ROOT_USER)}"
MINIO_SECRET="$(getenv Minio__SecretKey)"; MINIO_SECRET="${MINIO_SECRET:-$(getenv MINIO_ROOT_PASSWORD)}"
MINIO_ENDPOINT="$(getenv Minio__Endpoint)"; MINIO_ENDPOINT="${MINIO_ENDPOINT:-$(getenv MINIO_ENDPOINT)}"
MINIO_BUCKET="$(getenv Minio__BucketName)"; MINIO_BUCKET="${MINIO_BUCKET:-$(getenv MINIO_BUCKET)}"
MINIO_PUBLIC="$(getenv Minio__PublicBaseUrl)"; MINIO_PUBLIC="${MINIO_PUBLIC:-$(getenv MINIO_PUBLIC_BASE_URL)}"
CONNECTION="$(getenv ConnectionStrings__DefaultConnection)"
if [[ -z "${CONNECTION}" ]]; then
  CONNECTION="Host=${PG_HOST};Port=${PG_PORT};Database=${PG_DB};Username=${PG_USER};Password=${PG_PASSWORD}"
fi

[[ -n "${JWT_KEY}" ]] && dotnet user-secrets set "Jwt:Key" "${JWT_KEY}" --project "${API_PROJECT}" >/dev/null
[[ -n "${CONNECTION}" ]] && dotnet user-secrets set "ConnectionStrings:DefaultConnection" "${CONNECTION}" --project "${API_PROJECT}" >/dev/null
[[ -n "${MINIO_ACCESS}" ]] && dotnet user-secrets set "Minio:AccessKey" "${MINIO_ACCESS}" --project "${API_PROJECT}" >/dev/null
[[ -n "${MINIO_SECRET}" ]] && dotnet user-secrets set "Minio:SecretKey" "${MINIO_SECRET}" --project "${API_PROJECT}" >/dev/null
[[ -n "${MINIO_ENDPOINT}" ]] && dotnet user-secrets set "Minio:Endpoint" "${MINIO_ENDPOINT}" --project "${API_PROJECT}" >/dev/null
[[ -n "${MINIO_BUCKET}" ]] && dotnet user-secrets set "Minio:BucketName" "${MINIO_BUCKET}" --project "${API_PROJECT}" >/dev/null
[[ -n "${MINIO_PUBLIC}" ]] && dotnet user-secrets set "Minio:PublicBaseUrl" "${MINIO_PUBLIC}" --project "${API_PROJECT}" >/dev/null

EMAIL_PROVIDER="$(getenv Email__Provider)"
EMAIL_FROM="$(getenv Email__From)"
EMAIL_FROM_NAME="$(getenv Email__FromName)"
EMAIL_HOST="$(getenv Email__Smtp__Host)"
EMAIL_PORT="$(getenv Email__Smtp__Port)"
EMAIL_SSL="$(getenv Email__Smtp__UseSsl)"
EMAIL_USER="$(getenv Email__Smtp__Username)"
EMAIL_PASS="$(getenv Email__Smtp__Password)"
[[ -n "${EMAIL_PROVIDER}" ]] && dotnet user-secrets set "Email:Provider" "${EMAIL_PROVIDER}" --project "${API_PROJECT}" >/dev/null
[[ -n "${EMAIL_FROM}" ]] && dotnet user-secrets set "Email:From" "${EMAIL_FROM}" --project "${API_PROJECT}" >/dev/null
[[ -n "${EMAIL_FROM_NAME}" ]] && dotnet user-secrets set "Email:FromName" "${EMAIL_FROM_NAME}" --project "${API_PROJECT}" >/dev/null
[[ -n "${EMAIL_HOST}" ]] && dotnet user-secrets set "Email:Smtp:Host" "${EMAIL_HOST}" --project "${API_PROJECT}" >/dev/null
[[ -n "${EMAIL_PORT}" ]] && dotnet user-secrets set "Email:Smtp:Port" "${EMAIL_PORT}" --project "${API_PROJECT}" >/dev/null
[[ -n "${EMAIL_SSL}" ]] && dotnet user-secrets set "Email:Smtp:UseSsl" "${EMAIL_SSL}" --project "${API_PROJECT}" >/dev/null
[[ -n "${EMAIL_USER}" ]] && dotnet user-secrets set "Email:Smtp:Username" "${EMAIL_USER}" --project "${API_PROJECT}" >/dev/null
[[ -n "${EMAIL_PASS}" ]] && dotnet user-secrets set "Email:Smtp:Password" "${EMAIL_PASS}" --project "${API_PROJECT}" >/dev/null

APP_FRONTEND="$(getenv App__FrontendBaseUrl)"
APP_RESET_MINUTES="$(getenv App__PasswordResetTokenMinutes)"
[[ -n "${APP_FRONTEND}" ]] && dotnet user-secrets set "App:FrontendBaseUrl" "${APP_FRONTEND}" --project "${API_PROJECT}" >/dev/null
[[ -n "${APP_RESET_MINUTES}" ]] && dotnet user-secrets set "App:PasswordResetTokenMinutes" "${APP_RESET_MINUTES}" --project "${API_PROJECT}" >/dev/null

echo "User Secrets synchronized from .env"
echo "Done. Start infra with: docker compose -f \"${CONFIG_DIR}/docker-compose.yml\" --env-file \"${ENV_FILE}\" up -d"
