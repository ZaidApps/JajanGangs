// One-time ADMIN operation, not app code. Dry run unless --apply is passed.
// Publish firestore.phase5-migration.rules first to freeze client writes.
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldPath, Timestamp, getFirestore } from 'firebase-admin/firestore';

const args = process.argv.slice(2);
const apply = args.includes('--apply');
const project = args.find(arg => arg.startsWith('--project='))?.slice(10);
if (project !== 'jajangangs') throw new Error('Pass --project=jajangangs explicitly.');
if (apply && !args.includes('--writes-frozen')) {
  throw new Error('Publish the temporary migration rules first, then pass --writes-frozen.');
}
initializeApp({ credential: applicationDefault(), projectId: project });
const db = getFirestore();
// Use Firestore read time, not the administrator computer's clock.
const now = (await db.doc('_phase5_migration/clock').get()).readTime.toMillis();
const states = new Set(['OPEN', 'DECIDING', 'DESTINATION_SELECTED', 'ON_THE_WAY']);
const owners = new Map();
let cursor;
for (;;) {
  let query = db.collection('jajan_events').orderBy(FieldPath.documentId()).limit(250);
  if (cursor) query = query.startAfter(cursor);
  const page = await query.get();
  for (const doc of page.docs) {
    const data = doc.data();
    if (!states.has(data.state)) continue;
    if (!data.createdAt?.toMillis || typeof data.creatorId !== 'string' || data.durationMinutes !== 45) {
      throw new Error('An event has an unsupported schema. Resolve it before deploying Phase 5.');
    }
    const expires = data.createdAt.toMillis() + data.durationMinutes * 60000;
    if (expires <= now) continue;
    const record = owners.get(data.creatorId) ?? { eventId: '', legacyEventIds: [], until: 0 };
    record.legacyEventIds.push(doc.id);
    record.until = Math.max(record.until, expires);
    owners.set(data.creatorId, record);
  }
  if (page.size < 250) break;
  cursor = page.docs.at(-1);
}
// Check all existing slots before any writes. Reruns can preserve identical
// migration records but must never overwrite a slot used by the new app.
const writes = [];
for (const [uid, record] of owners) {
  record.legacyEventIds.sort();
  if (record.legacyEventIds.length > 5000) throw new Error('Too many legacy events for one owner; resolve manually.');
  const ref = db.collection('active_jajan_slots').doc(uid);
  const prior = await ref.get();
  if (prior.exists) {
    const value = prior.data();
    const covered = value.eventId === '' && record.legacyEventIds.every(id => value.legacyEventIds?.includes(id))
      && value.legacyUntil?.toMillis() >= record.until;
    if (!covered) throw new Error('A conflicting active slot exists. Stop and inspect the migration; nothing will be overwritten.');
    continue;
  }
  writes.push({ ref, data: {
    eventId: '', legacyEventIds: record.legacyEventIds, legacyUntil: Timestamp.fromMillis(record.until),
  }});
}
console.log(`${owners.size} owners with active legacy events; ${writes.length} new slots required.`);
if (apply) {
  for (const { ref, data } of writes) await ref.create(data);
  console.log('Migration finished. Publish the final firestore.rules before reopening writes.');
} else {
  console.log('Dry run only. No data changed. Use --apply --writes-frozen after freezing client writes.');
}
