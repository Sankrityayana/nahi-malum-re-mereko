-- Supabase schema for Speech Practice App

-- Ensure pgcrypto for gen_random_uuid
create extension if not exists pgcrypto;

create table if not exists public.words (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  lang text not null check (lang in ('en','hi')),
  difficulty int not null default 1,
  created_at timestamp with time zone default now()
);

create table if not exists public.progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  word_id uuid,
  target_text text,
  score numeric not null,
  created_at timestamp with time zone default now()
);

create or replace view public.leaderboard as
select p.user_id, u.email, sum(p.score) as total_score, count(*) as attempts
from public.progress p
join auth.users u on u.id = p.user_id
group by p.user_id, u.email
order by total_score desc;

-- Policies
alter table public.words enable row level security;
alter table public.progress enable row level security;

create policy "words are readable by all" on public.words for select using (true);
create policy "insert progress for self" on public.progress for insert with check (auth.uid() = user_id);
create policy "read own progress" on public.progress for select using (auth.uid() = user_id);

-- RPC for leaderboard (optional, else use view)
create or replace function public.get_leaderboard(limit_count int default 20)
returns table(user_id uuid, email text, total_score numeric, attempts bigint)
language sql stable as $$
  select * from public.leaderboard limit limit_count;
$$;

-- Random words RPC (to avoid client-side random ordering limits)
create or replace function public.get_random_words(p_lang text, p_limit int default 10)
returns setof public.words
language sql stable as $$
  select * from public.words where lang = p_lang order by random() limit p_limit;
$$;

-- User stats for gamification (cross-device sync)
create table if not exists public.user_stats (
  user_id uuid primary key references auth.users(id) on delete cascade,
  streak integer not null default 0,
  coins integer not null default 0,
  last_practice_date date
);

alter table public.user_stats enable row level security;

create policy "read own stats" on public.user_stats for select using (auth.uid() = user_id);
create policy "insert own stats" on public.user_stats for insert with check (auth.uid() = user_id);
create policy "update own stats" on public.user_stats for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Badges master table
create table if not exists public.badges (
  code text primary key,
  name text not null,
  description text,
  icon text default '🏅'
);

-- User earned badges
create table if not exists public.user_badges (
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_code text not null references public.badges(code) on delete cascade,
  earned_at timestamp with time zone default now(),
  primary key (user_id, badge_code)
);

alter table public.badges enable row level security;
alter table public.user_badges enable row level security;

create policy "badges readable" on public.badges for select using (true);
create policy "read own user_badges" on public.user_badges for select using (auth.uid() = user_id);
create policy "insert own user_badges" on public.user_badges for insert with check (auth.uid() = user_id);

-- Seed common badges (idempotent)
insert into public.badges (code, name, description, icon) values
('first_practice','First Practice','Completed your first practice','🎉'),
('streak_3','Streak 3','Practiced 3 days in a row','🔥'),
('streak_7','Streak 7','Practiced 7 days in a row','🔥'),
('streak_30','Streak 30','Practiced 30 days in a row','🔥'),
('accuracy_80','Sharp Ear','Hit 80% accuracy','⭐'),
('accuracy_90','Golden Tongue','Hit 90% accuracy','🏆'),
('attempts_10','Getting Warm','10 practice attempts','🌱'),
('attempts_50','On a Roll','50 practice attempts','🌿'),
('attempts_100','Centurion','100 practice attempts','🌳')
on conflict (code) do nothing;

-- Progress stats RPC to help badge logic
create or replace function public.get_progress_stats(p_user uuid)
returns table(attempts bigint, best_score numeric, last_score numeric)
language sql stable as $$
  select
    (select count(*) from public.progress pr where pr.user_id = p_user) as attempts,
    coalesce((select max(score) from public.progress pr where pr.user_id = p_user), 0) as best_score,
    coalesce((select score from public.progress pr where pr.user_id = p_user order by created_at desc limit 1), 0) as last_score;
$$;

-- Atomically compute and award badges; returns newly awarded badges
create or replace function public.compute_and_award_badges(p_user uuid)
returns table(code text, name text, icon text)
language plpgsql volatile as $$
declare
  v_attempts bigint := 0;
  v_last numeric := 0;
  v_streak int := 0;
begin
  select count(*) into v_attempts from public.progress where user_id = p_user;
  select coalesce(score, 0) into v_last from public.progress where user_id = p_user order by created_at desc limit 1;
  select coalesce(streak, 0) into v_streak from public.user_stats where user_id = p_user;

  return query
  with candidate(code) as (
    select 'first_practice' where v_attempts >= 1
    union all select 'streak_3' where v_streak >= 3
    union all select 'streak_7' where v_streak >= 7
    union all select 'streak_30' where v_streak >= 30
    union all select 'accuracy_80' where v_last >= 80
    union all select 'accuracy_90' where v_last >= 90
    union all select 'attempts_10' where v_attempts >= 10
    union all select 'attempts_50' where v_attempts >= 50
    union all select 'attempts_100' where v_attempts >= 100
  ),
  ins as (
    insert into public.user_badges(user_id, badge_code)
    select p_user, c.code from candidate c
    on conflict do nothing
    returning badge_code
  )
  select b.code, b.name, b.icon from public.badges b join ins i on i.badge_code = b.code;
end;
$$;
