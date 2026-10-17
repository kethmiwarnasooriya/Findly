-- DEVELOPMENT / DEMO ONLY. Never run against a production project.
--
-- Inserts sample reports owned by a dedicated demo account so a fresh
-- project shows realistic data. It only ever touches rows with
-- is_demo = true owned by that account, so real user data is never changed.
--
-- 1. In Supabase Dashboard → Authentication → Users, create a user for the
--    demo account (e.g. demo@findly.test) with "Auto Confirm User" ticked.
-- 2. Replace the email below if you used a different one.
-- 3. Run this script in the SQL editor. Re-running replaces the demo rows.

do $$
declare
  demo_email constant text := 'demo@findly.test';
  demo_id uuid;
begin
  select id into demo_id from auth.users where email = demo_email;
  if demo_id is null then
    raise exception 'Create the demo user % first (see comments above)', demo_email;
  end if;

  delete from public.reports where owner_id = demo_id and is_demo = true;

  insert into public.reports
    (owner_id, type, title, description, category, location, event_date, is_demo, created_at)
  values
    (demo_id, 'lost', 'Black Lenovo laptop bag',
     'Black laptop bag with a Lenovo charger and a blue notebook inside. Has a small keychain on the zip.',
     'bags', 'Main library, 2nd floor study area', current_date - 1, true, now() - interval '20 hours'),
    (demo_id, 'found', 'Laptop bag',
     'Found a black laptop bag with a charger inside near the study tables.',
     'bags', 'Main library 2nd floor', current_date - 1, true, now() - interval '18 hours'),
    (demo_id, 'lost', 'Student ID card',
     'University student ID card in a clear plastic holder with a green lanyard.',
     'id_documents', 'Canteen', current_date - 3, true, now() - interval '3 days'),
    (demo_id, 'found', 'Green lanyard with card holder',
     'Green lanyard with a plastic card holder, found under a table.',
     'id_documents', 'Canteen seating area', current_date - 2, true, now() - interval '2 days'),
    (demo_id, 'lost', 'Silver water bottle',
     'Stainless steel water bottle with stickers of mountains on it.',
     'bottles', 'Gym', current_date - 5, true, now() - interval '5 days'),
    (demo_id, 'found', 'AirPods case',
     'White AirPods charging case, no earbuds inside. Scratch on the lid.',
     'electronics', 'Lecture hall B', current_date - 4, true, now() - interval '4 days'),
    (demo_id, 'lost', 'Car keys with red fob',
     'Toyota car key with a red rubber fob and two smaller house keys on the ring.',
     'keys', 'Car park near the main gate', current_date - 6, true, now() - interval '6 days'),
    (demo_id, 'found', 'Casio scientific calculator',
     'Casio fx-991 calculator left on a desk after the morning exam.',
     'books_stationery', 'Exam hall 1', current_date - 2, true, now() - interval '2 days'),
    (demo_id, 'lost', 'Navy blue hoodie',
     'Navy hoodie with the faculty logo on the back, size M.',
     'clothing', 'Basketball court', current_date - 8, true, now() - interval '8 days'),
    (demo_id, 'found', 'Brown leather wallet',
     'Brown leather wallet, no cash. Has a bus pass inside.',
     'wallets_cards', 'Bus stop outside the faculty', current_date - 1, true, now() - interval '1 day');

  -- One resolved example so the Resolved filter has something to show.
  update public.reports
     set status = 'resolved'
   where owner_id = demo_id and is_demo = true and title = 'Navy blue hoodie';
end;
$$;
