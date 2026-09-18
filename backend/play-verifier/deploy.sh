#!/usr/bin/env bash
set -euo pipefail

: "${GOOGLE_CLOUD_PROJECT:?Set GOOGLE_CLOUD_PROJECT to the dedicated UNJAM Google Cloud project id}"
REGION="${REGION:-europe-west1}"
FIRESTORE_LOCATION="${FIRESTORE_LOCATION:-eur3}"
SERVICE="${SERVICE:-unjam-play-verifier}"
SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME:-unjam-play-verifier}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT_NAME}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com"

gcloud config set project "$GOOGLE_CLOUD_PROJECT"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com firestore.googleapis.com androidpublisher.googleapis.com

if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" --display-name="UNJAM Play purchase verifier"
fi

gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/datastore.user" >/dev/null

if ! gcloud firestore databases describe --database='(default)' >/dev/null 2>&1; then
  gcloud firestore databases create --database='(default)' --location="$FIRESTORE_LOCATION" --type=firestore-native
fi

gcloud run deploy "$SERVICE" \
  --source=. \
  --region="$REGION" \
  --service-account="$SERVICE_ACCOUNT" \
  --allow-unauthenticated \
  --min=0 \
  --max=10 \
  --concurrency=40 \
  --cpu=1 \
  --memory=256Mi \
  --set-env-vars="UNJAM_PACKAGE_NAME=com.eghosa.unjamgam,UNJAM_LEDGER_COLLECTION=play_purchase_claims"

SERVICE_URL="$(gcloud run services describe "$SERVICE" --region="$REGION" --format='value(status.url)')"
test -n "$SERVICE_URL"

echo "Cloud Run service: $SERVICE_URL"
echo "Runtime service account: $SERVICE_ACCOUNT"
echo "Purchase verification endpoint: $SERVICE_URL/verify"

HEALTH="$(curl -fsS --retry 5 --retry-delay 2 "$SERVICE_URL/healthz")"
printf '%s' "$HEALTH" | grep -Eq '"ok"[[:space:]]*:[[:space:]]*true'
echo "Health check passed."

echo
echo "OWNER ACTION REQUIRED:"
echo "1. In Play Console, grant $SERVICE_ACCOUNT access to package com.eghosa.unjamgam with permission to use the Purchases API."
echo "2. Set GitHub Actions secret UNJAM_PURCHASE_VERIFICATION_URL to $SERVICE_URL/verify."
echo "3. Run the Monetization Readiness workflow after the Play permission is granted."
