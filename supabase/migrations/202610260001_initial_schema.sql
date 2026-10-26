-- Dompetektif · initial cloud schema
--
-- The mobile/web client is offline-first. Hive keeps the local source of truth
-- and pushes ids/timestamps generated on-device. These tables therefore accept
-- client supplied UUIDs and timestamps, while RLS enforces wallet membership.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 80),
  type text not null default 'cash' check (type in ('cash', 'bank', 'ewallet')),
  opening_balance_minor bigint not null default 0,
  currency text not null default 'IDR' check (char_length(currency) = 3),
  color_hex text not null default '#E8B84B',
  icon_key text not null default 'wallet',
  is_shared boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 80),
  kind text not null default 'expense' check (kind in ('expense', 'income')),
  icon_key text not null default 'category',
  color_hex text not null default '#E8B84B',
  keywords text[] not null default '{}',
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint categories_scope_check check (
    (is_system and owner_id is null) or (not is_system and owner_id is not null)
  )
);

create table if not exists public.wallet_members (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'viewer' check (role in ('owner', 'editor', 'viewer')),
  display_name text not null default 'Investigator',
  email text not null default '',
  avatar_url text,
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (wallet_id, user_id)
);

create table if not exists public.wallet_invites (
  code text primary key,
  wallet_id uuid not null references public.wallets(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  expires_at timestamptz not null default (now() + interval '7 days'),
  used_at timestamptz,
  used_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null default 'expense' check (type in ('expense', 'income', 'transfer')),
  amount_minor bigint not null check (amount_minor >= 0),
  currency text not null default 'IDR' check (char_length(currency) = 3),
  category_id uuid references public.categories(id) on delete set null,
  to_wallet_id uuid references public.wallets(id) on delete set null,
  occurred_at timestamptz not null default now(),
  note text not null default '',
  merchant text not null default '',
  receipt_id uuid,
  recurring_rule_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint transfer_shape_check check (
    (type = 'transfer' and to_wallet_id is not null and category_id is null)
    or (type <> 'transfer')
  )
);

create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  wallet_id uuid references public.wallets(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  amount_minor bigint not null check (amount_minor > 0),
  currency text not null default 'IDR' check (char_length(currency) = 3),
  month date not null,
  alert_threshold numeric(4, 3) not null default 0.8 check (alert_threshold > 0 and alert_threshold <= 2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.recurring_rules (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  wallet_id uuid not null references public.wallets(id) on delete cascade,
  type text not null default 'expense' check (type in ('expense', 'income', 'transfer')),
  amount_minor bigint not null check (amount_minor >= 0),
  currency text not null default 'IDR' check (char_length(currency) = 3),
  category_id uuid references public.categories(id) on delete set null,
  to_wallet_id uuid references public.wallets(id) on delete set null,
  note text not null default '',
  merchant text not null default '',
  frequency text not null default 'monthly' check (frequency in ('daily', 'weekly', 'monthly', 'yearly')),
  interval integer not null default 1 check (interval between 1 and 120),
  next_run_at timestamptz not null default now(),
  end_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.case_notes (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id) on delete cascade,
  transaction_id uuid references public.transactions(id) on delete set null,
  user_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null default 'Investigator',
  avatar_url text,
  body text not null check (char_length(trim(body)) between 1 and 4000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.receipts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  wallet_id uuid references public.wallets(id) on delete set null,
  transaction_id uuid references public.transactions(id) on delete set null,
  merchant text not null default '',
  total_minor bigint not null default 0,
  currency text not null default 'IDR' check (char_length(currency) = 3),
  occurred_at timestamptz not null default now(),
  raw_text text not null default '',
  items jsonb not null default '[]'::jsonb,
  image_key text,
  remote_image_url text,
  status text not null default 'draft' check (status in ('draft', 'parsed', 'converted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  wallet_id uuid references public.wallets(id) on delete set null,
  period_start timestamptz not null,
  period_end timestamptz not null,
  headline text not null default '',
  summary text not null default '',
  findings jsonb not null default '[]'::jsonb,
  anomalies jsonb not null default '[]'::jsonb,
  recommendations text[] not null default '{}',
  source text not null default 'heuristic' check (source in ('ai', 'heuristic')),
  generated_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keep receipt_id / recurring_rule_id useful even when rows sync in a
-- different order. Constraints are intentionally deferred by being nullable
-- references rather than hard insert-time requirements.
alter table public.transactions
  drop constraint if exists transactions_receipt_id_fkey;
alter table public.transactions
  add constraint transactions_receipt_id_fkey
  foreign key (receipt_id) references public.receipts(id) on delete set null;
alter table public.transactions
  drop constraint if exists transactions_recurring_rule_id_fkey;
alter table public.transactions
  add constraint transactions_recurring_rule_id_fkey
  foreign key (recurring_rule_id) references public.recurring_rules(id) on delete set null;

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

create index if not exists wallets_owner_idx on public.wallets(owner_id);
create index if not exists wallets_updated_idx on public.wallets(updated_at);
create index if not exists categories_owner_idx on public.categories(owner_id);
create index if not exists categories_updated_idx on public.categories(updated_at);
create index if not exists wallet_members_user_idx on public.wallet_members(user_id);
create index if not exists wallet_members_wallet_idx on public.wallet_members(wallet_id);
create index if not exists wallet_members_updated_idx on public.wallet_members(updated_at);
create index if not exists wallet_invites_wallet_idx on public.wallet_invites(wallet_id);
create index if not exists transactions_wallet_date_idx on public.transactions(wallet_id, occurred_at desc);
create index if not exists transactions_updated_idx on public.transactions(updated_at);
create index if not exists transactions_category_idx on public.transactions(category_id);
create index if not exists budgets_wallet_month_idx on public.budgets(wallet_id, month);
create index if not exists budgets_updated_idx on public.budgets(updated_at);
create index if not exists recurring_wallet_idx on public.recurring_rules(wallet_id);
create index if not exists recurring_updated_idx on public.recurring_rules(updated_at);
create index if not exists notes_wallet_created_idx on public.case_notes(wallet_id, created_at);
create index if not exists notes_updated_idx on public.case_notes(updated_at);
create index if not exists receipts_wallet_idx on public.receipts(wallet_id);
create index if not exists receipts_updated_idx on public.receipts(updated_at);
create index if not exists reports_wallet_idx on public.reports(wallet_id, generated_at desc);
create index if not exists reports_updated_idx on public.reports(updated_at);

-- ---------------------------------------------------------------------------
-- Timestamp hygiene
-- ---------------------------------------------------------------------------

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.updated_at is null then
    new.updated_at := now();
  elsif tg_op = 'UPDATE' and new.updated_at < old.updated_at then
    -- Never regress a sync cursor because of device clock skew.
    new.updated_at := now();
  end if;
  return new;
end;
$$;

create or replace function public.touch_member_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'wallets', 'categories', 'transactions', 'budgets', 'recurring_rules',
    'case_notes', 'receipts', 'reports'
  ]
  loop
    execute format(
      'drop trigger if exists %I on public.%I',
      table_name || '_touch_updated_at',
      table_name
    );
    execute format(
      'create trigger %I before insert or update on public.%I for each row execute function public.touch_updated_at()',
      table_name || '_touch_updated_at',
      table_name
    );
  end loop;

  drop trigger if exists wallet_members_touch_updated_at on public.wallet_members;
  create trigger wallet_members_touch_updated_at
    before insert or update on public.wallet_members
    for each row execute function public.touch_member_updated_at();
end $$;

-- ---------------------------------------------------------------------------
-- Membership helpers (security definer to avoid recursive RLS)
-- ---------------------------------------------------------------------------

create or replace function public.is_wallet_member(
  p_wallet_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    p_user_id is not null
    and exists (
      select 1
      from public.wallet_members wm
      where wm.wallet_id = p_wallet_id and wm.user_id = p_user_id
    );
$$;

create or replace function public.wallet_role(
  p_wallet_id uuid,
  p_user_id uuid default auth.uid()
)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when p_user_id is null then null
    when exists (
      select 1 from public.wallets w
      where w.id = p_wallet_id and w.owner_id = p_user_id
    ) then 'owner'
    else (
      select wm.role::text
      from public.wallet_members wm
      where wm.wallet_id = p_wallet_id and wm.user_id = p_user_id
      limit 1
    )
  end;
$$;

create or replace function public.can_view_wallet(
  p_wallet_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    p_user_id is not null
    and (
      exists (
        select 1 from public.wallets w
        where w.id = p_wallet_id and w.owner_id = p_user_id
      )
      or public.is_wallet_member(p_wallet_id, p_user_id)
    );
$$;

create or replace function public.can_edit_wallet(
  p_wallet_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.wallet_role(p_wallet_id, p_user_id) in ('owner', 'editor');
$$;

create or replace function public.can_manage_wallet(
  p_wallet_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.wallet_role(p_wallet_id, p_user_id) = 'owner';
$$;

-- Realtime delete events need the old row to identify a removed membership.
alter table public.wallet_members replica identity full;

-- ---------------------------------------------------------------------------
-- New wallet → owner membership
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_wallet()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_email text;
  v_name text;
  v_avatar text;
begin
  select
    coalesce(u.email, ''),
    coalesce(
      nullif(trim(u.raw_user_meta_data ->> 'display_name'), ''),
      split_part(coalesce(u.email, ''), '@', 1),
      'Investigator'
    ),
    nullif(u.raw_user_meta_data ->> 'avatar_url', '')
  into v_email, v_name, v_avatar
  from auth.users u
  where u.id = new.owner_id;

  insert into public.wallet_members (
    wallet_id, user_id, role, display_name, email, avatar_url
  )
  values (
    new.id, new.owner_id, 'owner',
    coalesce(v_name, 'Investigator'),
    coalesce(v_email, ''),
    v_avatar
  )
  on conflict (wallet_id, user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists wallets_add_owner_member on public.wallets;
create trigger wallets_add_owner_member
  after insert on public.wallets
  for each row execute function public.handle_new_wallet();

-- ---------------------------------------------------------------------------
-- Invites
-- ---------------------------------------------------------------------------

create or replace function public.create_wallet_invite(p_wallet_id uuid)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_code text;
  v_attempt integer := 0;
begin
  if v_user is null then
    raise exception 'Masuk terlebih dahulu.' using errcode = '42501';
  end if;
  if not public.can_edit_wallet(p_wallet_id, v_user) then
    raise exception 'Kamu tidak punya akses ke TKP ini.' using errcode = '42501';
  end if;

  -- Rotate any unused invite so only the newest code works.
  update public.wallet_invites
  set used_at = now()
  where wallet_id = p_wallet_id and used_at is null;

  loop
    v_attempt := v_attempt + 1;
    v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));
    begin
      insert into public.wallet_invites (code, wallet_id, created_by)
      values (v_code, p_wallet_id, v_user);
      return v_code;
    exception when unique_violation then
      if v_attempt >= 8 then
        raise exception 'Gagal membuat kode undangan. Coba lagi.';
      end if;
    end;
  end loop;
end;
$$;

create or replace function public.join_wallet_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_invite public.wallet_invites%rowtype;
  v_email text;
  v_name text;
  v_avatar text;
begin
  if v_user is null then
    raise exception 'Masuk terlebih dahulu.' using errcode = '42501';
  end if;

  select *
  into v_invite
  from public.wallet_invites
  where code = upper(trim(p_code))
  for update;

  if not found
     or v_invite.used_at is not null
     or v_invite.expires_at <= now() then
    raise exception 'Kode undangan tidak valid atau sudah kedaluwarsa.'
      using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.wallets
    where id = v_invite.wallet_id and deleted_at is null
  ) then
    raise exception 'TKP tidak lagi tersedia.' using errcode = '22023';
  end if;

  select
    coalesce(u.email, ''),
    coalesce(
      nullif(trim(u.raw_user_meta_data ->> 'display_name'), ''),
      split_part(coalesce(u.email, ''), '@', 1),
      'Investigator'
    ),
    nullif(u.raw_user_meta_data ->> 'avatar_url', '')
  into v_email, v_name, v_avatar
  from auth.users u
  where u.id = v_user;

  insert into public.wallet_members (
    wallet_id, user_id, role, display_name, email, avatar_url
  )
  values (
    v_invite.wallet_id, v_user, 'editor',
    coalesce(v_name, 'Investigator'),
    coalesce(v_email, ''),
    v_avatar
  )
  on conflict (wallet_id, user_id) do nothing;

  update public.wallet_invites
  set used_at = now(), used_by = v_user
  where code = v_invite.code;

  update public.wallets
  set is_shared = true
  where id = v_invite.wallet_id;

  return v_invite.wallet_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.wallets enable row level security;
alter table public.categories enable row level security;
alter table public.wallet_members enable row level security;
alter table public.wallet_invites enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;
alter table public.recurring_rules enable row level security;
alter table public.case_notes enable row level security;
alter table public.receipts enable row level security;
alter table public.reports enable row level security;

-- wallets ------------------------------------------------------------------
drop policy if exists wallets_select on public.wallets;
create policy wallets_select on public.wallets
  for select to authenticated
  using (public.can_view_wallet(id));

drop policy if exists wallets_insert on public.wallets;
create policy wallets_insert on public.wallets
  for insert to authenticated
  with check (owner_id = auth.uid());

drop policy if exists wallets_update on public.wallets;
create policy wallets_update on public.wallets
  for update to authenticated
  using (public.can_edit_wallet(id))
  with check (public.can_edit_wallet(id));

drop policy if exists wallets_delete on public.wallets;
create policy wallets_delete on public.wallets
  for delete to authenticated
  using (owner_id = auth.uid());

-- categories ---------------------------------------------------------------
drop policy if exists categories_select on public.categories;
create policy categories_select on public.categories
  for select to authenticated
  using (is_system or owner_id = auth.uid());

drop policy if exists categories_insert on public.categories;
create policy categories_insert on public.categories
  for insert to authenticated
  with check (not is_system and owner_id = auth.uid());

drop policy if exists categories_update on public.categories;
create policy categories_update on public.categories
  for update to authenticated
  using (not is_system and owner_id = auth.uid())
  with check (not is_system and owner_id = auth.uid());

drop policy if exists categories_delete on public.categories;
create policy categories_delete on public.categories
  for delete to authenticated
  using (not is_system and owner_id = auth.uid());

-- wallet members -----------------------------------------------------------
drop policy if exists wallet_members_select on public.wallet_members;
create policy wallet_members_select on public.wallet_members
  for select to authenticated
  using (public.can_view_wallet(wallet_id));

drop policy if exists wallet_members_insert on public.wallet_members;
create policy wallet_members_insert on public.wallet_members
  for insert to authenticated
  with check (public.can_manage_wallet(wallet_id));

drop policy if exists wallet_members_update on public.wallet_members;
create policy wallet_members_update on public.wallet_members
  for update to authenticated
  using (public.can_manage_wallet(wallet_id))
  with check (public.can_manage_wallet(wallet_id));

drop policy if exists wallet_members_delete on public.wallet_members;
create policy wallet_members_delete on public.wallet_members
  for delete to authenticated
  using (user_id = auth.uid() or public.can_manage_wallet(wallet_id));

-- wallet invites have no direct client access; use the RPCs above.
drop policy if exists wallet_invites_no_direct_access on public.wallet_invites;
create policy wallet_invites_no_direct_access on public.wallet_invites
  for all to authenticated using (false) with check (false);

-- wallet scoped data -------------------------------------------------------
drop policy if exists transactions_select on public.transactions;
create policy transactions_select on public.transactions
  for select to authenticated using (public.can_view_wallet(wallet_id));

drop policy if exists transactions_insert on public.transactions;
create policy transactions_insert on public.transactions
  for insert to authenticated with check (public.can_edit_wallet(wallet_id));

drop policy if exists transactions_update on public.transactions;
create policy transactions_update on public.transactions
  for update to authenticated
  using (public.can_edit_wallet(wallet_id))
  with check (public.can_edit_wallet(wallet_id));

drop policy if exists transactions_delete on public.transactions;
create policy transactions_delete on public.transactions
  for delete to authenticated using (public.can_edit_wallet(wallet_id));

drop policy if exists budgets_select on public.budgets;
create policy budgets_select on public.budgets
  for select to authenticated
  using (
    owner_id = auth.uid()
    or (wallet_id is not null and public.can_view_wallet(wallet_id))
  );

drop policy if exists budgets_insert on public.budgets;
create policy budgets_insert on public.budgets
  for insert to authenticated
  with check (
    owner_id = auth.uid()
    and (wallet_id is null or public.can_edit_wallet(wallet_id))
  );

drop policy if exists budgets_update on public.budgets;
create policy budgets_update on public.budgets
  for update to authenticated
  using (
    owner_id = auth.uid()
    or (wallet_id is not null and public.can_edit_wallet(wallet_id))
  )
  with check (
    owner_id = auth.uid()
    or (wallet_id is not null and public.can_edit_wallet(wallet_id))
  );

drop policy if exists budgets_delete on public.budgets;
create policy budgets_delete on public.budgets
  for delete to authenticated
  using (
    owner_id = auth.uid()
    or (wallet_id is not null and public.can_edit_wallet(wallet_id))
  );

drop policy if exists recurring_rules_select on public.recurring_rules;
create policy recurring_rules_select on public.recurring_rules
  for select to authenticated using (public.can_view_wallet(wallet_id));

drop policy if exists recurring_rules_insert on public.recurring_rules;
create policy recurring_rules_insert on public.recurring_rules
  for insert to authenticated with check (public.can_edit_wallet(wallet_id));

drop policy if exists recurring_rules_update on public.recurring_rules;
create policy recurring_rules_update on public.recurring_rules
  for update to authenticated
  using (public.can_edit_wallet(wallet_id))
  with check (public.can_edit_wallet(wallet_id));

drop policy if exists recurring_rules_delete on public.recurring_rules;
create policy recurring_rules_delete on public.recurring_rules
  for delete to authenticated using (public.can_edit_wallet(wallet_id));

drop policy if exists case_notes_select on public.case_notes;
create policy case_notes_select on public.case_notes
  for select to authenticated using (public.can_view_wallet(wallet_id));

drop policy if exists case_notes_insert on public.case_notes;
create policy case_notes_insert on public.case_notes
  for insert to authenticated
  with check (user_id = auth.uid() and public.can_view_wallet(wallet_id));

drop policy if exists case_notes_update on public.case_notes;
create policy case_notes_update on public.case_notes
  for update to authenticated
  using (user_id = auth.uid() and public.can_view_wallet(wallet_id))
  with check (user_id = auth.uid() and public.can_view_wallet(wallet_id));

drop policy if exists case_notes_delete on public.case_notes;
create policy case_notes_delete on public.case_notes
  for delete to authenticated using (user_id = auth.uid());

drop policy if exists receipts_select on public.receipts;
create policy receipts_select on public.receipts
  for select to authenticated
  using (
    owner_id = auth.uid()
    or (wallet_id is not null and public.can_view_wallet(wallet_id))
  );

drop policy if exists receipts_insert on public.receipts;
create policy receipts_insert on public.receipts
  for insert to authenticated
  with check (
    owner_id = auth.uid()
    and (wallet_id is null or public.can_view_wallet(wallet_id))
  );

drop policy if exists receipts_update on public.receipts;
create policy receipts_update on public.receipts
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists receipts_delete on public.receipts;
create policy receipts_delete on public.receipts
  for delete to authenticated using (owner_id = auth.uid());

drop policy if exists reports_select on public.reports;
create policy reports_select on public.reports
  for select to authenticated
  using (
    owner_id = auth.uid()
    or (wallet_id is not null and public.can_view_wallet(wallet_id))
  );

drop policy if exists reports_insert on public.reports;
create policy reports_insert on public.reports
  for insert to authenticated
  with check (
    owner_id = auth.uid()
    and (wallet_id is null or public.can_view_wallet(wallet_id))
  );

drop policy if exists reports_update on public.reports;
create policy reports_update on public.reports
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists reports_delete on public.reports;
create policy reports_delete on public.reports
  for delete to authenticated using (owner_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

revoke all on public.wallet_invites from anon, authenticated;
revoke all on public.wallets, public.categories, public.wallet_members,
  public.transactions, public.budgets, public.recurring_rules,
  public.case_notes, public.receipts, public.reports
  from anon;
grant select, insert, update, delete on public.wallets, public.categories,
  public.wallet_members, public.transactions, public.budgets,
  public.recurring_rules, public.case_notes, public.receipts, public.reports
  to authenticated;

revoke execute on function public.is_wallet_member(uuid, uuid) from public, anon;
revoke execute on function public.wallet_role(uuid, uuid) from public, anon;
revoke execute on function public.can_view_wallet(uuid, uuid) from public, anon;
revoke execute on function public.can_edit_wallet(uuid, uuid) from public, anon;
revoke execute on function public.can_manage_wallet(uuid, uuid) from public, anon;
revoke execute on function public.create_wallet_invite(uuid) from public, anon;
revoke execute on function public.join_wallet_by_code(text) from public, anon;
grant execute on function public.is_wallet_member(uuid, uuid) to authenticated;
grant execute on function public.wallet_role(uuid, uuid) to authenticated;
grant execute on function public.can_view_wallet(uuid, uuid) to authenticated;
grant execute on function public.can_edit_wallet(uuid, uuid) to authenticated;
grant execute on function public.can_manage_wallet(uuid, uuid) to authenticated;
grant execute on function public.create_wallet_invite(uuid) to authenticated;
grant execute on function public.join_wallet_by_code(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Realtime publication
-- ---------------------------------------------------------------------------

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    execute 'alter publication supabase_realtime add table '
      'public.wallets, public.categories, public.wallet_members, '
      'public.transactions, public.budgets, public.recurring_rules, '
      'public.case_notes, public.receipts, public.reports';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Receipt storage
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'receipts',
  'receipts',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists receipts_storage_select on storage.objects;
create policy receipts_storage_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists receipts_storage_insert on storage.objects;
create policy receipts_storage_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists receipts_storage_update on storage.objects;
create policy receipts_storage_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists receipts_storage_delete on storage.objects;
create policy receipts_storage_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
