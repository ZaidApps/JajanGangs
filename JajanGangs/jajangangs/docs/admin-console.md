# Separate Flutter admin console

Implemented at `G:/Flutt/JajanGangsAdmin`. Read its README.md for Firebase registration, role assignment, rules/index publishing and launch instructions.

The consumer app's UI and authentication flows were not changed for this work. Shared Firestore rules now include verified `admin: true` custom-claim access to user profiles, events, reports and admin audit/cleanup records. Admin mutation grants are limited to report status changes and expired-event cleanup. No maintenance switch/listener was added.

Two collection indexes were added: jajan_events(state ascending, createdAt descending) and user_reports(status ascending, createdAt descending). Publish the complete shared rules and indexes; they have not been deployed.

The admin app has no Firestore listeners or polling. Queries require explicit Load/Apply/Refresh/Load more actions; result pages are cached for the session. Tests, analyzer, builds and device runs were not performed, per the project instructions.

When changing the event schema, update the admin cleanup child-collection list and expiry query too. The current preview assumes the 45-minute duration enforced by validEvent().
