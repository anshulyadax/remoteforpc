# Neon Auth Setup

This project now reads cloud auth credentials from compile-time defines instead of hardcoded values.

## Neon Project Info

- Auth URL: `https://ep-dawn-snow-aichjaw3.neonauth.c-4.us-east-1.aws.neon.tech/neondb/auth`
- JWKS URL: `https://ep-dawn-snow-aichjaw3.neonauth.c-4.us-east-1.aws.neon.tech/neondb/auth/.well-known/jwks.json`

## Required Dart Defines

Set these when running/building:

- `NEON_APP_URL`
- `NEON_ANON_KEY`
- `NEON_AUTH_URL`
- `NEON_JWKS_URL`

Optional:

- `NEON_DATABASE_URL`

## Run Commands

Client:

```bash
flutter run -d chrome \
  --dart-define=NEON_APP_URL=https://ep-dawn-snow-aichjaw3.neonauth.c-4.us-east-1.aws.neon.tech/neondb \
  --dart-define=NEON_ANON_KEY=<your_neon_anon_key> \
  --dart-define=NEON_AUTH_URL=https://ep-dawn-snow-aichjaw3.neonauth.c-4.us-east-1.aws.neon.tech/neondb/auth \
  --dart-define=NEON_JWKS_URL=https://ep-dawn-snow-aichjaw3.neonauth.c-4.us-east-1.aws.neon.tech/neondb/auth/.well-known/jwks.json \
  --dart-define=NEON_DATABASE_URL='postgresql://neondb_owner:npg_Lh6orRMngZO9@ep-dawn-snow-aichjaw3-pooler.c-4.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require'
```

Server desktop:

```bash
flutter run -d macos \
  --dart-define=NEON_APP_URL=https://ep-dawn-snow-aichjaw3.neonauth.c-4.us-east-1.aws.neon.tech/neondb \
  --dart-define=NEON_ANON_KEY=<your_neon_anon_key> \
  --dart-define=NEON_AUTH_URL=https://ep-dawn-snow-aichjaw3.neonauth.c-4.us-east-1.aws.neon.tech/neondb/auth \
  --dart-define=NEON_JWKS_URL=https://ep-dawn-snow-aichjaw3.neonauth.c-4.us-east-1.aws.neon.tech/neondb/auth/.well-known/jwks.json \
  --dart-define=NEON_DATABASE_URL='postgresql://neondb_owner:npg_Lh6orRMngZO9@ep-dawn-snow-aichjaw3-pooler.c-4.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require'
```

## Redirect Domains

Add trusted redirect domains in Neon Auth for OAuth and magic link callbacks.
