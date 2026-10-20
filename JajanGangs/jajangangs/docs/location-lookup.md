# Approximate area lookup

Home and Create share one in-flight request. Creation requests a location only after Create Jajan is pressed. Invalid/default Jakarta coordinates never create an event.

Android declares both COARSE and FINE foreground location permissions. The installed geolocator documentation explains that coarse-only first fixes can take minutes, and its native fallback may select GPS. Existing approximate-only installs receive at most one precision-upgrade permission offer; first-time permission requests already offer both choices and are not immediately repeated. Users can retain Approximate. No background location permission is added.

After checking services and permission, the lookup reuses a rounded in-memory cell, then a rounded on-device cache, then the OS location cache. Every accepted fix retains its ORIGINAL timestamp and expires after two minutes. Disk cache reads/writes are bounded and optional. Only a rounded 0.02-degree cell, its uncertainty radius and timestamp are stored; never raw coordinates. The cache can speed up app restarts without treating an old position as current.

Fresh requests use high-accuracy foreground positioning (allowing GPS when precise permission is granted). Android waits up to 12 seconds, cancels its subscription, then tries the native cache/provider for up to six seconds. Other platforms have an 18-second provider window. Checks/cache access have separate bounded deadlines; user permission prompt duration is outside these budgets. Streams are cancelled on all exit paths. This is a best-effort lookup, not a guarantee when the OS cannot provide a fix.

Only valid finite fixes no older than two minutes with accuracy at most 3 km are accepted. Coordinates are rounded before leaving this service. The UI preserves existing area/form data on failures. Debug output identifies permission accuracy, provider selection, cache reuse, unusable sample categories and elapsed time without logging coordinates.

An Android rebuild/reinstall is necessary for the manifest change; hot reload alone does not apply permissions. On an existing installation, Settings → Apps → Jajan Gangs → Permissions → Location can enable Precise location if the optional prompt was already declined. The choice remains with the user.

Source reviewed and formatted. No tests, analyzer, builds or device runs performed, per user instruction.
