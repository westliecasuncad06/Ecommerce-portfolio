/**
 * Migration script: set `active` boolean for product documents based on `status`.
 *
 * Usage:
 * 1. Install dependencies:
 *    npm init -y
 *    npm install firebase-admin
 *
 * 2. Provide a service account JSON and set the env var:
 *    On Windows (PowerShell): $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\serviceAccount.json"
 *    On bash: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccount.json"
 *
 * 3. Run:
 *    node scripts/migrate_products_set_active.js
 *
 * The script will iterate product documents and set `active: true` when
 * `status === 'active'`, otherwise `active: false`. It updates docs that
 * either lack `active` or have it different from the computed value.
 */

const admin = require('firebase-admin');

try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
} catch (e) {
  console.error('Failed to initialize Firebase Admin:', e);
  process.exit(1);
}

const db = admin.firestore();

async function run() {
  console.log('Scanning products collection...');
  const snapshot = await db.collection('products').get();
  console.log(`Found ${snapshot.size} product documents`);

  const updates = [];
  snapshot.forEach((doc) => {
    const data = doc.data() || {};
    const status = (data.status || 'active');
    const desiredActive = status === 'active';
    const currentActive = data.hasOwnProperty('active') ? !!data.active : undefined;
    if (currentActive !== desiredActive) {
      updates.push({ ref: doc.ref, active: desiredActive });
    }
  });

  console.log(`Will update ${updates.length} documents`);
  const BATCH_SIZE = 400; // keep below Firestore limit of 500 writes per batch
  for (let i = 0; i < updates.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const slice = updates.slice(i, i + BATCH_SIZE);
    slice.forEach((u) => batch.update(u.ref, { active: u.active }));
    console.log(`Committing batch ${i / BATCH_SIZE + 1} with ${slice.length} updates...`);
    await batch.commit();
  }

  console.log('Migration complete.');
}

run().catch((e) => {
  console.error('Migration failed:', e);
  process.exit(1);
});
