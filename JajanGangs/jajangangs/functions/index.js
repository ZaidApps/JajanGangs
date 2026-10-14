const {createHash} = require('node:crypto');
const tokenKey = token => createHash('sha256').update(token).digest('hex');
const {onDocumentCreated, onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, Timestamp, FieldValue} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const logger = require('firebase-functions/logger');
initializeApp();
const db = getFirestore();
const {publishMessageActivity, publishDecision} = require('./gang_activity');

exports.gangRequestActivity = onDocumentUpdated({
  document:'jajan_events/{eventId}/join_requests/{uid}',
  region:'asia-southeast2', retry:true, maxInstances:5,
}, async event => {
  if(event.data.before.data().status === event.data.after.data().status) return;
  await publishDecision(event.data.after.ref);
});

// Deploy in the region nearest the Firestore database. No client credentials.
exports.gangMessageNotification = onDocumentCreated({
  document: 'jajan_events/{eventId}/messages/{messageId}',
  region: 'asia-southeast2', retry: true, maxInstances: 5,
}, async (event) => {
  const ref = event.data.ref;
  await publishMessageActivity(ref);
  const parent = ref.parent.parent;
  const active = (d) => d && ['OPEN','DECIDING','DESTINATION_SELECTED','ON_THE_WAY'].includes(d.state)
    && d.createdAt.toMillis() + d.durationMinutes * 60000 > Date.now();
  // Events may be delivered more than once. Lease the existing message, never
  // recreate it: cancellation may delete it while this function is running.
  const acquired = await db.runTransaction(async tx => {
    const [room, message] = await Promise.all([tx.get(parent), tx.get(ref)]);
    if (!room.exists || !message.exists || !active(room.data())) return false;
    const data = message.data();
    if (data.pushDone) return false;
    if (data.pushLease?.toMillis() > Date.now()) throw new Error('Notification delivery already leased');
    tx.update(ref, {pushLease: Timestamp.fromMillis(Date.now() + 120000)});
    return true;
  });
  if (!acquired) return;
  try {
    const [roomSnap, messageSnap] = await Promise.all([parent.get(),ref.get()]);
    if (!roomSnap.exists || !messageSnap.exists || !active(roomSnap.data())) return;
    const room = roomSnap.data(), message = messageSnap.data();
    for (const uid of room.memberIds.filter(uid => uid !== message.senderId)) {
      // Bound device fan-out; registration refreshes updatedAt on app entry.
      const devices = await db.collection('users').doc(uid).collection('push_tokens').orderBy('updatedAt','desc').limit(20).get();
      const pending = devices.docs.filter(d => !(message.pushDelivered || []).includes(tokenKey(d.id)));
      if (!pending.length) continue;
      const latest = await parent.get();
      if (!latest.exists || !active(latest.data()) || !latest.data().memberIds.includes(uid)) return;
      const result = await getMessaging().sendEach(pending.map(device => {
        const indonesian = device.data().locale === 'id';
        return {token: device.id,
          notification: {title:'Jajan Gang', body: indonesian ? 'Pesan baru dari gang kamu. Yuk, buka obrolan!' : 'Your gang has a new message. Jump into the chat!'},
          data: {eventId:event.params.eventId, recipientId:uid},
          android: {ttl: Math.max(0, room.createdAt.toMillis()+room.durationMinutes*60000-Date.now()), notification: {tag:event.params.messageId}},
          apns: {headers:{'apns-collapse-id':event.params.messageId,'apns-expiration':String(Math.floor((room.createdAt.toMillis()+room.durationMinutes*60000)/1000))},payload:{aps:{sound:'default'}}},
        };
      }));
      const delivered = [], invalid = [];
      let retry = false;
      result.responses.forEach((response,index) => {
        if (response.success) delivered.push(tokenKey(pending[index].id));
        else if (['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(response.error?.code)) {
          invalid.push(pending[index].ref); delivered.push(tokenKey(pending[index].id));
        } else {retry=true; logger.warn('Gang push failed',{code:response.error?.code});}
      });
      await Promise.all(invalid.map(ref=>ref.delete()));
      await db.runTransaction(async tx => {
        if ((await tx.get(ref)).exists && delivered.length) tx.update(ref,{pushDelivered:FieldValue.arrayUnion(...delivered)});
      });
      if(retry) throw new Error('Some devices need another notification delivery attempt');
    }
    await db.runTransaction(async tx=>{if((await tx.get(ref)).exists)tx.update(ref,{pushDone:true,pushLease:FieldValue.delete(),pushDelivered:FieldValue.delete()});});
  } catch(error) {
    await db.runTransaction(async tx=>{if((await tx.get(ref)).exists)tx.update(ref,{pushLease:FieldValue.delete()});});
    throw error;
  }
});
