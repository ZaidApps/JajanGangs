# Scheduled Jajans

Now remains the default. Later selects a UTC instant, displayed in each viewer's local date/time with its UTC offset. Creation permits 15 minutes to 7 days ahead; the picker starts one hour ahead. The host can cancel but cannot reschedule. Scheduled events are OPEN immediately, can accept members and chat immediately, and occupy the existing one-active-event slot. No automatic state transition occurs at start time.

Scheduled documents add scheduledAt and expiresAt; rules require expiresAt = scheduledAt + 45 minutes and validate the scheduling window with request.time. Now and pre-existing records retain trusted createdAt + 45 minutes. Scheduling fields are immutable through existing update whitelists. No migration is required.

No scheduling listener, cloud job, background polling or automatic reminder was added. Existing open-screen event/chat subscriptions remain. Badges are local formatting. Map requests retain the same three limit-20 queries and existing indexes; inbox retains its existing limit-20 query and explicit pagination. The createdAt lookback is widened to 7 days + 45 minutes to include schedules without issuing an additional legacy-data query. These bounded candidate queries can return fewer active records in busy areas because expired candidates are filtered locally; they do not promise every event in an area. Firebase reads still apply to loaded documents and existing listeners.

Pending creation IDs retain the selected schedule. A stale schedule is rejected after confirming the pending document does not exist, allowing the user to choose a new time without duplicating a successful write.

Admin cleanup now evaluates scheduledAt + durationMinutes (or createdAt for legacy events). Preview reads 20 candidates and shows only expired records, with Load more for remaining pages. Delete all scans using a cursor, skipping future schedules instead of repeatedly querying the same undeletable events. Admin cleanup remains manual and consumes normal read/delete quotas.

Publish the complete shared firestore.rules before using Later. The admin deployment copy is synchronized. Existing composite indexes are reused. Update both app binaries before using scheduled events: older clients assume 45 minutes after creation and may hide them.

No tests, analyzer, builds or device runs performed per project instructions. Localization generation, formatting and source review only.
