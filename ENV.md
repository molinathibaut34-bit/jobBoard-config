# Environnements et secrets — JobBoard

## Objectif

Séparer la configuration non sensible (commitée) des secrets (locaux / CI).

## Fichiers

| Fichier | Rôle | Versionné |
|---------|------|-----------|
| `back/.../appsettings.json` | Structure + valeurs non secrètes | Oui |
| `back/.../appsettings.Development.json` | Logs / overrides non secrets | Oui |
| `config/.env.example` | Modèle de variables | Oui |
| `config/.env` | Secrets locaux (Docker + API) | **Non** |
| .NET User Secrets | Alternative locale pour l’API | **Non** (machine) |
| Variables d’environnement / GitHub Secrets | CI / production | **Non** |

## Démarrage local (recommandé)

Depuis la **racine du monorepo** (`jobBoard/`) :

```bash
npm run setup:env
npm run dev:docker
npm run dev
```

Ou depuis `config/` :

```bash
cp .env.example .env
npm run setup:env
npm run dev:docker
```

L’API charge automatiquement `config/.env` au démarrage (sans écraser les variables déjà définies dans le shell / CI).

## User Secrets (.NET)

```bash
cd back/jobBoard-Api/jobBoard-Api
dotnet user-secrets set "Jwt:Key" "votre-clé-longue"
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=localhost;Port=5434;..."
dotnet user-secrets set "Minio:AccessKey" "..."
dotnet user-secrets set "Minio:SecretKey" "..."
```

Le script `setup-env.ps1` / `setup-env.sh` synchronise aussi User Secrets depuis `.env`.

## Variables importantes

### Docker

- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_PORT`
- `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `MINIO_BUCKET`
- `MAILPIT_UI_PORT`, `MAILPIT_SMTP_PORT`, `MAILPIT_MAX_MESSAGES` (UI : http://localhost:8025)

### API ASP.NET Core (notation `__`)

- `ConnectionStrings__DefaultConnection` (sinon dérivée de `POSTGRES_*`)
- `Jwt__Key`, `Jwt__Issuer`, `Jwt__Audience`
- `Minio__Endpoint`, `Minio__AccessKey`, `Minio__SecretKey`, `Minio__BucketName`, `Minio__PublicBaseUrl`
- `Email__Provider`, `Email__From`, `Email__FromName`, `Email__Smtp__Host`, `Email__Smtp__Port`, `Email__Smtp__UseSsl`, `Email__Smtp__Username`, `Email__Smtp__Password`
  - Dev (défaut) : `Provider=Smtp` → Mailpit (`localhost:1025`, UI http://localhost:8025)
  - Sans envoi : `Provider=Logging`
  - Prod (Brevo) : garder `Provider=Smtp`, changer host/port/credentials SMTP Brevo
- `Seed__Admin__Email`, `Seed__Admin__Password`, `Seed__Admin__FirstName`, `Seed__Admin__Name` (compte Admin créé au démarrage)
- `App__FrontendBaseUrl`, `App__PasswordResetTokenMinutes` (liens de réinitialisation de mot de passe)

## CI / GitHub Actions

Ne jamais committer de secrets. Prévoir des repository secrets, par exemple :

- `JOBBOARD_JWT_KEY`
- `JOBBOARD_DB_CONNECTION`
- `JOBBOARD_MINIO_ACCESS_KEY`
- `JOBBOARD_MINIO_SECRET_KEY`

Puis les injecter dans le workflow backend :

```yaml
env:
  Jwt__Key: ${{ secrets.JOBBOARD_JWT_KEY }}
  ConnectionStrings__DefaultConnection: ${{ secrets.JOBBOARD_DB_CONNECTION }}
  Minio__AccessKey: ${{ secrets.JOBBOARD_MINIO_ACCESS_KEY }}
  Minio__SecretKey: ${{ secrets.JOBBOARD_MINIO_SECRET_KEY }}
```

## Priorité de configuration

1. Variables d’environnement du process / CI  
2. User Secrets (Development)  
3. Fichier `config/.env`  
4. `appsettings.*.json`  

## Validation

Au démarrage, l’API refuse de démarrer si JWT, connection string ou credentials MinIO manquent, avec un message pointant vers ce document.
