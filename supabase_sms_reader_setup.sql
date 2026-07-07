-- Easy Cash SMS Reader companion app table

create table if not exists public.wallet_sms_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  message_key text not null,
  sender text,
  body text not null,
  received_at timestamptz not null,
  operation_type text not null default 'unknown',
  amount numeric not null default 0,
  phone text,
  transaction_id text,
  wallet_company text,
  status text not null default 'pending',
  source text not null default 'sms_reader_app',
  created_at timestamptz not null default now(),

  constraint wallet_sms_events_status_check check (status in ('pending', 'confirmed', 'failed', 'ignored')),
  constraint wallet_sms_events_operation_type_check check (operation_type in ('incoming', 'outgoing', 'unknown')),
  unique(user_id, message_key)
);

create index if not exists wallet_sms_events_user_idx on public.wallet_sms_events(user_id);
create index if not exists wallet_sms_events_status_idx on public.wallet_sms_events(status);
create index if not exists wallet_sms_events_received_idx on public.wallet_sms_events(received_at desc);

alter table public.wallet_sms_events enable row level security;

drop policy if exists "Users can view own sms events" on public.wallet_sms_events;
create policy "Users can view own sms events"
on public.wallet_sms_events
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own sms events" on public.wallet_sms_events;
create policy "Users can insert own sms events"
on public.wallet_sms_events
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own sms events" on public.wallet_sms_events;
create policy "Users can update own sms events"
on public.wallet_sms_events
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
