-- Baza klientów weryfikatora: tabela spraw i zasady dostępu.
-- Wklej całość w Supabase → SQL Editor → New query → Run.

create table if not exists public.sprawy (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  utworzono   timestamptz not null default now(),
  zmieniono   timestamptz not null default now(),
  klient      text,
  telefon     text,
  email       text,
  polozenie   text,
  dzialka     text,
  status      text not null default 'Nowa',
  notatka     text,
  kwota       numeric,
  ocena       text,
  dane        jsonb not null default '{}'::jsonb
);

create index if not exists sprawy_user_zmieniono on public.sprawy (user_id, zmieniono desc);

-- data ostatniej zmiany ustawia się sama
create or replace function public.sprawy_zmieniono() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.zmieniono := now();
  return new;
end $$;

drop trigger if exists sprawy_zmieniono on public.sprawy;
create trigger sprawy_zmieniono before update on public.sprawy
  for each row execute function public.sprawy_zmieniono();

-- każdy zalogowany widzi i zmienia tylko własne sprawy, niezalogowany nic
alter table public.sprawy enable row level security;

drop policy if exists "sprawy odczyt" on public.sprawy;
drop policy if exists "sprawy dodanie" on public.sprawy;
drop policy if exists "sprawy zmiana" on public.sprawy;
drop policy if exists "sprawy usuniecie" on public.sprawy;
create policy "sprawy odczyt"    on public.sprawy for select to authenticated using (user_id = (select auth.uid()));
create policy "sprawy dodanie"   on public.sprawy for insert to authenticated with check (user_id = (select auth.uid()));
create policy "sprawy zmiana"    on public.sprawy for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "sprawy usuniecie" on public.sprawy for delete to authenticated using (user_id = (select auth.uid()));

revoke all on public.sprawy from anon;
grant select, insert, update, delete on public.sprawy to authenticated;
