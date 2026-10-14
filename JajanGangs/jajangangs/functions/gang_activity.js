const {getFirestore} = require('firebase-admin/firestore');
const db = getFirestore();

function compare(at, id, priorAt, priorId = '') {
  if (!priorAt) return 1;
  const seconds = at.seconds - priorAt.seconds;
  const nanos = at.nanoseconds - priorAt.nanoseconds;
  return seconds || nanos || (id < priorId ? -1 : id > priorId ? 1 : 0);
}

// All fan-out and the idempotency marker commit together. Cancellation changes
// the parent, forcing an in-flight transaction to retry before it can recreate data.
async function publishMessageActivity(ref) {
  const parent = ref.parent.parent;
  await db.runTransaction(async tx => {
    const [roomSnap, messageSnap] = await Promise.all([tx.get(parent), tx.get(ref)]);
    if (!roomSnap.exists || !messageSnap.exists || roomSnap.data().state === 'CANCELLING') return;
    const room = roomSnap.data(), message = messageSnap.data();
    if (message.activityPublished) return;
    const ids = room.memberIds;
    const stateRefs = ids.map(uid => parent.collection('chat_state').doc(uid));
    const states = await Promise.all(stateRefs.map(r => tx.get(r)));
    const noticeRefs = ids.map(uid => parent.collection('event_notifications').doc(`${uid}_message`));
    const notices = await Promise.all(noticeRefs.map(r => tx.get(r)));
    const at = message.createdAt, messageId = ref.id;
    ids.forEach((uid, index) => {
      const state = states[index].data() || {};
      const change = {};
      if (compare(at, messageId, state.lastMessageAt, state.lastMessageId) > 0) {
        Object.assign(change, {lastMessageAt: at, lastMessageId: messageId,
          lastText: message.text, lastName: message.name, lastSenderId: message.senderId});
      }
      if (uid !== message.senderId) {
        if (compare(at, messageId, state.incomingAt, state.incomingId) > 0) {
          Object.assign(change, {incomingAt: at, incomingId: messageId});
        }
        const previous = notices[index].data();
        if (!previous || compare(at, messageId, previous.createdAt, previous.messageId) > 0) {
          tx.set(noticeRefs[index], {recipientId: uid, eventId: parent.id, type: 'message',
            createdAt: at, messageId, read: compare(at, messageId, state.readAt, state.readId) <= 0});
        }
      }
      if (Object.keys(change).length) tx.set(stateRefs[index], change, {merge:true});
    });
    tx.update(ref, {activityPublished:true});
  });
}

async function publishDecision(ref) {
  const parent = ref.parent.parent;
  const notification = parent.collection('event_notifications').doc(`${ref.id}_decision`);
  await db.runTransaction(async tx => {
    const [room, request, old] = await Promise.all([tx.get(parent), tx.get(ref), tx.get(notification)]);
    if (!room.exists || room.data().state === 'CANCELLING' || !request.exists) return;
    const data = request.data();
    if (!['ACCEPTED','REJECTED'].includes(data.status) || !data.decidedAt) return;
    if (old.exists && compare(data.decidedAt, '', old.data().createdAt, '') <= 0) return;
    tx.set(notification, {recipientId:ref.id, eventId:parent.id,
      type:data.status === 'ACCEPTED' ? 'accepted' : 'rejected', createdAt:data.decidedAt, read:false});
  });
}

module.exports = {publishMessageActivity, publishDecision};
