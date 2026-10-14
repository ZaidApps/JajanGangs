# Deferred Cloud Functions

This directory preserves an earlier implementation for reference only. The app now targets Firebase Spark and writes chat summaries and in-app activity through Firestore transactions.

**Do not deploy these functions with the current app.** Their earlier notification schema is incompatible with the current shared notification documents. The functions deployment target has been removed from `firebase.json`; OS push is deferred.

Follow [the Spark setup guide](../docs/spark-setup.md). Any future return to server functions requires the user's approval and a schema review.
