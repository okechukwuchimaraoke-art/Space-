-- SPACE Phase 1 core schema. Run once in Supabase SQL Editor.
create extension if not exists citext;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username citext not null unique
    check (username ~ '^[a-z0-9_]{3,30}$'),
  display_name text not null default '' check (char_length(display_name) <= 60),
  bio text not null default '' check (char_length(bio) <= 300),
  avatar_url text,
  created_at timestamptz not null default now()
);

create table public.auth_methods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('email','phone','passkey')),
  identifier text not null,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  unique (kind, identifier)
);

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  platform text not null check (platform in ('android','ios','web','windows','macos','linux')),
  last_seen_at timestamptz not null default now(),
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

-- PUBLIC key material only
create table public.device_keys (
  device_id uuid primary key references public.devices(id) on delete cascade,
  registration_id int not null,
  identity_key bytea not null,
  signed_prekey_id int not null,
  signed_prekey bytea not null,
  signed_prekey_signature bytea not null,
  updated_at timestamptz not null default now()
);

create table public.one_time_prekeys (
  device_id uuid not null references public.devices(id) on delete cascade,
  key_id int not null,
  public_key bytea not null,
  primary key (device_id, key_id)
);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('direct','group')),
  title text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','member')),
  muted boolean not null default false,
  archived boolean not null default false,
  pinned boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);
create index on public.participants (user_id);

-- Ciphertext only. Never plaintext.
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  sender_device_id uuid references public.devices(id),
  ciphertext bytea not null,
  crypto_header jsonb not null default '{}'::jsonb,
  reply_to uuid references public.messages(id) on delete set null,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz,
  expires_at timestamptz
);
create index on public.messages (conversation_id, created_at desc);

create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  storage_path text not null,
  size_bytes bigint not null check (size_bytes >= 0),
  mime_type text,
  created_at timestamptz not null default now()
);

create table public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid references public.profiles(id) on delete set null,
  reason text not null check (char_length(reason) <= 1000),
  created_at timestamptz not null default now()
);

create table public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  theme_mode text not null default 'dark' check (theme_mode in ('dark','light','system')),
  hide_notification_previews boolean not null default false,
  discoverable_by_username boolean not null default true,
  read_receipts boolean not null default true,
  updated_at timestamptz not null default now()
);

create or replace function public.is_participant(conv uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.participants p
    where p.conversation_id = conv and p.user_id = auth.uid()
  );
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, display_name)
  values (new.id,
          'user_' || substr(replace(new.id::text, '-', ''), 1, 10),
          coalesce(new.raw_user_meta_data->>'display_name', ''));
  insert into public.user_settings (user_id) values (new.id);
  if new.email is not null then
    insert into public.auth_methods (user_id, kind, identifier, verified_at)
    values (new.id, 'email', lower(new.email), new.email_confirmed_at);
  end if;
  return new;
end $$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.create_direct_conversation(other uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare conv uuid;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if other = auth.uid() then raise exception 'cannot message yourself'; end if;
  if not exists (select 1 from public.profiles where id = other) then
    raise exception 'user not found';
  end if;

  select c.id into conv from public.conversations c
  where c.kind = 'direct'
    and exists (select 1 from public.participants p where p.conversation_id = c.id and p.user_id = auth.uid())
    and exists (select 1 from public.participants p where p.conversation_id = c.id and p.user_id = other)
  limit 1;
  if conv is not null then return conv; end if;

  insert into public.conversations (kind, created_by) values ('direct', auth.uid()) returning id into conv;
  insert into public.participants (conversation_id, user_id, role)
  values (conv, auth.uid(), 'member'), (conv, other, 'member');
  return conv;
end $$;

create or replace function public.claim_prekey(target_device uuid)
returns table (key_id int, public_key bytea)
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  return query
  delete from public.one_time_prekeys o
  where o.ctid = (
    select o2.ctid from public.one_time_prekeys o2
    where o2.device_id = target_device
    order by o2.key_id limit 1
    for update skip locked)
  returning o.key_id, o.public_key;
end $$;

revoke all on function public.create_direct_conversation(uuid) from public, anon;
revoke all on function public.claim_prekey(uuid) from public, anon;
grant execute on function public.create_direct_conversation(uuid) to authenticated;
grant execute on function public.claim_prekey(uuid) to authenticated;

alter table public.profiles enable row level security;
alter table public.auth_methods enable row level security;
alter table public.devices enable row level security;
alter table public.device_keys enable row level security;
alter table public.one_time_prekeys enable row level security;
alter table public.conversations enable row level security;
alter table public.participants enable row level security;
alter table public.messages enable row level security;
alter table public.attachments enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;
alter table public.user_settings enable row level security;

create policy profiles_read on public.profiles for select to authenticated using (true);
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy auth_methods_own on public.auth_methods for select to authenticated using (user_id = auth.uid());

create policy devices_own_select on public.devices for select to authenticated using (user_id = auth.uid());
create policy devices_own_insert on public.devices for insert to authenticated with check (user_id = auth.uid());
create policy devices_own_update on public.devices for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy device_keys_read on public.device_keys for select to authenticated using (true);
create policy device_keys_write on public.device_keys for all to authenticated
  using (exists (select 1 from public.devices d where d.id = device_id and d.user_id = auth.uid()))
  with check (exists (select 1 from public.devices d where d.id = device_id and d.user_id = auth.uid()));

create policy prekeys_insert_own on public.one_time_prekeys for insert to authenticated
  with check (exists (select 1 from public.devices d where d.id = device_id and d.user_id = auth.uid()));

create policy conversations_read on public.conversations for select to authenticated using (public.is_participant(id));

create policy participants_read on public.participants for select to authenticated using (public.is_participant(conversation_id));
create policy participants_update_own on public.participants for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy messages_read on public.messages for select to authenticated using (public.is_participant(conversation_id));
create policy messages_insert on public.messages for insert to authenticated
  with check (sender_id = auth.uid() and public.is_participant(conversation_id));
create policy messages_update_own on public.messages for update to authenticated
  using (sender_id = auth.uid()) with check (sender_id = auth.uid());

create policy attachments_read on public.attachments for select to authenticated
  using (exists (select 1 from public.messages m where m.id = message_id and public.is_participant(m.conversation_id)));
create policy attachments_insert on public.attachments for insert to authenticated
  with check (exists (select 1 from public.messages m where m.id = message_id and m.sender_id = auth.uid()));

create policy blocks_own on public.blocks for all to authenticated
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

create policy reports_insert on public.reports for insert to authenticated with check (reporter_id = auth.uid());

create policy settings_own on public.user_settings for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

alter publication supabase_realtime add table public.messages;
