# UNJAM Google Play Purchase Verifier

Small Cloud Run service used only to verify UNJAM Google Play one-time products and prevent duplicate reward grants. It does not create player accounts or store gameplay data.

## Endpoints

- `GET /healthz` -> `{ "ok": true }`
- `POST /verify` body: `package_name`, `product_id`, `purchase_token`, `claim_id`
- `POST /commit` body: same fields, called after the game has persisted the reward locally

The service verifies purchases with Google Play Developer API v3 `purchases.productsv2.getproductpurchasev2`. Firestore stores only a SHA-256-derived document ID and purchase metadata; raw purchase tokens are never stored or logged.

## Local tests

```bash
npm test
```

The unit tests use fake Play/ledger adapters and do not require Google credentials.

## Runtime identity

Do not create or commit a service-account JSON key. Cloud Run should run as a dedicated service account with Firestore data access. Separately, grant that service account access to the replacement UNJAM app in Play Console so the Android Publisher API can read purchases.

## Deploy to a dedicated Google Cloud project

Install and authenticate the Google Cloud CLI, then from this directory run:

```bash
export GOOGLE_CLOUD_PROJECT=your-unjam-project-id
bash deploy.sh
```

The script enables the required Google APIs, creates a dedicated Cloud Run runtime service account, grants only Firestore data access in the Cloud project, creates the default Firestore Native database when needed, and deploys the service with scale-to-zero. It does **not** grant Play Console access because only the Play account owner/admin can do that.

After deployment, copy the printed Cloud Run service URL. In Play Console, give the runtime service account app access to UNJAM with the permission that allows access to the Purchases API. Then verify:

```bash
curl https://YOUR-CLOUD-RUN-URL/healthz
```

The GitHub Actions release secret must be the `/verify` endpoint, not just the service root:

```text
UNJAM_PURCHASE_VERIFICATION_URL=https://YOUR-CLOUD-RUN-URL/verify
```

Do not put a Google service-account JSON key in GitHub or in the game. Cloud Run uses its attached service-account identity.
