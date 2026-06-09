-- Run in Supabase SQL editor

create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  name text,
  goal text default 'maintain',
  weight_kg float,
  height_cm float,
  age int,
  tdee int default 2000,
  weekly_budget float default 50,
  allergies text[] default '{}',
  diet_type text default 'omnivore',
  meal_variety text default 'rotate',
  profile_complete boolean default false,
  xp int default 0,
  level int default 1,
  streak int default 0,
  banned_meals text[] default '{}',
  favourite_meals text[] default '{}',
  nutrition_mode text default 'cook_myself',
  dietary_restrictions text default 'none',
  created_at timestamptz default now()
);

create table if not exists public.daily_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  date date default current_date,
  calories_logged int default 0,
  protein_logged float default 0,
  carbs_logged float default 0,
  fat_logged float default 0,
  food_log jsonb default '[]',
  meals jsonb default '{}',
  created_at timestamptz default now(),
  unique(user_id, date)
);

create table if not exists public.weight_history (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  date date default current_date,
  weight_kg float not null,
  created_at timestamptz default now(),
  unique(user_id, date)
);

create table if not exists public.personal_records (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  exercise text not null,
  weight_kg float not null,
  reps int,
  date date default current_date,
  created_at timestamptz default now()
);

create table if not exists public.feed_posts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  author_name text,
  content text not null,
  likes int default 0,
  liked_by uuid[] default '{}',
  created_at timestamptz default now()
);

create table if not exists public.weekly_plans (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  week_start date,
  plan jsonb not null,
  created_at timestamptz default now(),
  unique(user_id, week_start)
);

alter table public.profiles enable row level security;
alter table public.daily_logs enable row level security;
alter table public.weight_history enable row level security;
alter table public.personal_records enable row level security;
alter table public.feed_posts enable row level security;
alter table public.weekly_plans enable row level security;

create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

create policy "Users can manage own logs" on public.daily_logs for all using (auth.uid() = user_id);
create policy "Users can manage own weight" on public.weight_history for all using (auth.uid() = user_id);
create policy "Users can manage own PRs" on public.personal_records for all using (auth.uid() = user_id);
create policy "Users can manage own plans" on public.weekly_plans for all using (auth.uid() = user_id);

create policy "Anyone can read feed" on public.feed_posts for select using (true);
create policy "Users can create posts" on public.feed_posts for insert with check (auth.uid() = user_id);
create policy "Users can update own posts" on public.feed_posts for update using (auth.uid() = user_id);
