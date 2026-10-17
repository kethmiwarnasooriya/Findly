# Security test log

Results of `tool/security_check.sh`, which calls the Supabase REST and Storage
APIs directly with two separate accounts. It bypasses the Flutter UI, so these
results reflect what the database and Storage enforce on the server.

## Run 1 — 2026-10-16

- Project: dedicated development Supabase project (no production data)
- Schema: `supabase/migrations/20261016000000_initial_schema.sql`
- Accounts: two dashboard-created, auto-confirmed test users (A and B)
- Result: **27 passed, 0 failed**

| Area | Check | Result |
| --- | --- | --- |
| Reports | Anonymous request cannot read reports | PASS |
| Reports | Invalid/tampered token is rejected | PASS |
| Reports | A can create a report | PASS |
| Reports | `owner_id` is set by the server to A | PASS |
| Reports | B can read A's report (signed-in visibility is intended) | PASS |
| Reports | B cannot update A's report | PASS |
| Reports | B cannot delete A's report | PASS |
| Reports | A's report is unchanged after B's attempts | PASS |
| Reports | B cannot create a report owned by A | PASS |
| Reports | `owner_id` cannot be changed | PASS |
| Reports | Clients cannot set `is_demo` | PASS |
| Reports | `created_at` cannot be changed | PASS |
| Reports | Report type cannot be changed after creation | PASS |
| Reports | Too-short title is rejected by the database | PASS |
| Reports | Future `event_date` is rejected by the database | PASS |
| Storage | A can upload a PNG to their own folder | PASS |
| Storage | B cannot upload into A's folder | PASS |
| Storage | A cannot overwrite an existing object | PASS |
| Storage | Uploads into nested folders are rejected | PASS |
| Storage | Non-image content type is rejected | PASS |
| Storage | Files over 5 MB are rejected | PASS |
| Storage | B cannot read A's photo before it is attached to a report | PASS |
| Storage | A can attach their photo to their report | PASS |
| Storage | B can view A's photo once it is attached to a report | PASS |
| Storage | B cannot delete A's photo | PASS |
| Storage | A cannot point their report at B's photo | PASS |
| Reports | A can resolve their own report and `resolved_at` is set | PASS |

## Not covered by this run

- **Truly expired sessions.** Only a tampered token was tested. A naturally
  expired JWT (1 hour by default) has not been tested yet.
- **Rate limit** (20 reports per user per 24 hours). Not exercised, because it
  would create 20 rows.
- **File content vs. declared type.** Storage checks the declared
  `Content-Type`, not the file's actual bytes. A client that lies about the
  type could upload a non-image file labelled `image/png` to its *own* folder.
  The Flutter app checks file signatures before uploading. Other users only
  see such a file if it is attached to a report, and the app shows it as an
  image (or falls back to an icon).
