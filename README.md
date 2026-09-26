# jobBoard-config

Orchestration locale JobBoard : Docker Compose, variables d’environnement et scripts npm.

## Disposition attendue

Cloner les trois dépôts dans le même dossier parent :

```
parent/
  front/   # jobBoard-front
  back/    # jobBoard-back
  config/  # ce dépôt
```

Le fichier `package.json` à la **racine du monorepo parent** centralise les commandes.
Depuis ce dépôt (`config/`), les scripts Docker et setup restent disponibles.

## Commandes (depuis ce dossier)

```bash
cp .env.example .env
npm run setup:env
npm run dev:docker
```

## Commandes (depuis le monorepo parent)

```bash
npm run setup:env
npm run dev:docker
npm run dev
```

Documentation secrets : [ENV.md](./ENV.md).

Services locaux : PostgreSQL, MinIO (API `:9000`, console `:9001`), Mailpit (SMTP `:1025`, UI http://localhost:8025).
