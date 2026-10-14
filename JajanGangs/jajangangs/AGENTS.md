# Project constraints

- Keep the current and upcoming development phases compatible with Firebase Spark. Do not introduce Cloud Functions, real SMS authentication, or another billing-dependent backend requirement unless the user explicitly changes this decision.
- Use Firestore transactions and security rules for authorized client operations. Automated OS push delivery remains deferred on Spark; in-app notifications must work without a server function. Manual Firebase Console broadcasts to the `jajan_announcements` FCM topic are explicitly authorized on Spark.
- All app-owned text must support English and Bahasa Indonesia; follow `lib/AGENTS.md`.
- The user has requested no tests, analyzer, builds, or device runs unless they ask for them again. Source review, formatting, and localization generation are permitted.
