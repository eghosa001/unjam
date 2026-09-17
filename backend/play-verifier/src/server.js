import http from 'node:http';
import { createPurchaseService } from './purchase_service.js';
import { createGooglePlayClient } from './google_play.js';
import { createFirestoreLedger } from './firestore_ledger.js';
import { LEDGER_COLLECTION, MAX_JSON_BYTES, PACKAGE_NAME, PRODUCTS } from './config.js';
import { routeRequest } from './http_logic.js';

function writeJson(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(payload),
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
  });
  res.end(payload);
}

async function readJson(req) {
  let total = 0;
  const chunks = [];
  for await (const chunk of req) {
    total += chunk.length;
    if (total > MAX_JSON_BYTES) {
      const error = new Error('request too large');
      error.statusCode = 413;
      throw error;
    }
    chunks.push(chunk);
  }
  if (chunks.length === 0) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    const error = new Error('invalid json');
    error.statusCode = 400;
    throw error;
  }
}

const service = createPurchaseService({
  allowedPackage: PACKAGE_NAME,
  products: PRODUCTS,
  play: createGooglePlayClient(),
  ledger: createFirestoreLedger({ collectionName: LEDGER_COLLECTION }),
});

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url || '/', 'http://localhost');
    const body = req.method === 'POST' ? await readJson(req) : null;
    const result = await routeRequest({ method: req.method || 'GET', path: url.pathname, body }, service);
    writeJson(res, result.status, result.body);
  } catch (error) {
    const status = Number(error?.statusCode) || 503;
    // Never log request bodies, purchase tokens, or Google API URLs because the
    // purchase token is a reusable billing credential.
    console.error(`purchase verifier request failed (${status})`);
    writeJson(res, status, { error: status === 503 ? 'verification service unavailable' : String(error.message || 'request failed') });
  }
});

const port = Number.parseInt(process.env.PORT || '8080', 10);
server.listen(port, '0.0.0.0', () => {
  console.log(`UNJAM purchase verifier listening on ${port}`);
});
