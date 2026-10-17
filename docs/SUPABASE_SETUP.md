# Supabase setup

Findly needs one Supabase project. This guide takes about 15 minutes.

> **Never** put the `service_role` / secret key, the database password, or an
> access token in the app, in `env/*.json`, or anywhere in this repository.
> The app only needs the **project URL** and the **publishable (anon) key**.
> Those two values are designed to be public; security comes from the row
> level security policies in `supabase/migrations`.

## 1. Create the project

1. Sign in at <https://supabase.com/dashboard> and click **New project**.
2. Pick a name (e.g. `findly-dev`), a region close to your users, and a strong
   database password. Store the password in a password manager. The app never
   uses it.
3. Wait for the project to finish provisioning.

## 2. Run the schema migration

1. Open **SQL Editor → New query**.
2. Paste the whole of `supabase/migrations/20261016000000_initial_schema.sql`
   and click **Run**.
3. Check **Table Editor → reports** exists and shows "RLS enabled", and
   **Storage** shows a private bucket called `report-photos`.

Run the migration once. Running it a second time fails on `create type`
because the objects already exist. That is expected and harmless.

## 3. Configure authentication

**Authentication → Sign In / Providers → Email**

- Email provider: **enabled**
- Confirm email: **enabled** (unconfirmed users cannot sign in)
- Minimum password length: **8** or more

**Authentication → URL Configuration**

- Site URL: `com.findly.findly://login-callback`
- Redirect URLs: add `com.findly.findly://login-callback`

This deep link is what email confirmation and password-reset links open. It
must match `AppConfig.authRedirectUrl` and the intent filter in
`android/app/src/main/AndroidManifest.xml`.

**Email sending limits.** The built-in email service is for development only
and sends very few emails per hour. For real users, configure custom SMTP under
**Authentication → Emails → SMTP Settings**.

## 4. Connect the app

1. **Project Settings → API Keys**: copy the **publishable** key (or the legacy
   **anon** key). Do **not** copy the secret / `service_role` key.
2. **Project Settings → Data API** (or the project's Connect dialog): copy the
   project URL, `https://<ref>.supabase.co`.
3. Create your local, git-ignored config:

   ```sh
   cp env/dev.example.json env/dev.json
   ```

   Put the two values into `env/dev.json`. `.gitignore` excludes
   `env/*.json` except the example, so this file is never committed.

4. Run the app:

   ```sh
   flutter run --dart-define-from-file=env/dev.json
   ```

   In VS Code, use the **Findly (dev)** launch configuration, which passes the
   same flag.

## 5. Optional: demo data

`supabase/seed/demo_seed.sql` adds ten realistic reports owned by a dedicated
demo account. Only use it in a development project.

1. **Authentication → Users → Add user**: `demo@findly.test`, any strong
   password, tick **Auto Confirm User**.
2. Run `supabase/seed/demo_seed.sql` in the SQL editor.

Re-running it replaces only the demo rows (`is_demo = true` for that account).
It never touches other users' reports. The app itself never inserts demo data.

## What is public, restricted and private

| Data | Who can see it |
| --- | --- |
| Report title, description, category, location, dates, status | Any **signed-in** user |
| Report photo | Any signed-in user, via signed URLs that expire after 1 hour |
| Photos not attached to any report | Only the uploader |
| Report `owner_id` (an opaque UUID) | Any signed-in user. Used to show "Your report" |
| Email address, password | Never exposed to other users |
| Anything | **Anonymous (signed-out) visitors cannot read any data** |

Only the owner of a report can edit, resolve, reopen or delete it. This is
enforced by RLS policies, not just by hiding buttons.

## Backups and monitoring

Backup availability and retention depend on your Supabase plan. Check
**Database → Backups** in your dashboard. Don't assume backups exist on the
free plan. **Reports → API / Auth** shows request and error rates.
