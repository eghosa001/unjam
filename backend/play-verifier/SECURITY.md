# Security notes

- Never log or persist raw Google Play purchase tokens.
- Never commit service-account JSON keys, PEM keys, `.env` files, or keystores.
- Keep the package and product allowlists exact.
- Treat `/verify` and `/commit` as public endpoints; authorization for rewards comes from Google Play token verification plus the Firestore claim ledger.
- Run Cloud Run with the dedicated runtime service account created by `deploy.sh` and grant only the Play Console app access required for purchase verification.
