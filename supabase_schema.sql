-- 1. Cinemas Table (Tenants)
create table if not exists public.cinemas (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  location text not null,
  rating text default '5.0',
  feature text,
  image_url text,
  owner_id uuid references auth.users(id),
  created_at timestamptz default now()
);

-- 2. Screens Table
create table if not exists public.screens (
  id uuid default gen_random_uuid() primary key,
  cinema_id uuid references public.cinemas(id) on delete cascade,
  name text not null,
  floor text,
  tag text,
  created_at timestamptz default now()
);

-- 3. Food Items Table
create table if not exists public.food_items (
  id uuid default gen_random_uuid() primary key,
  cinema_id uuid references public.cinemas(id) on delete cascade,
  name text not null,
  description text,
  price double precision not null,
  image_url text,
  category text not null,
  is_available boolean default true,
  created_at timestamptz default now()
);

-- 4. Orders Table
create table if not exists public.orders (
  id uuid default gen_random_uuid() primary key,
  cinema_id uuid references public.cinemas(id) on delete cascade,
  customer_id uuid references auth.users(id),
  items jsonb not null default '[]'::jsonb,
  total_amount double precision not null default 0,
  status text not null default 'PENDING',
  location text not null, -- Hall selection/Seat info
  payment_status text not null default 'PENDING',
  payment_method text not null default 'DEMO_UPI',
  customer_phone text not null,
  timestamp timestamptz not null default now()
);

-- Row Level Security (RLS)
alter table public.cinemas enable row level security;
alter table public.screens enable row level security;
alter table public.food_items enable row level security;
alter table public.orders enable row level security;

-- Policies for Cinemas and Screens (Publicly Readable)
create policy "Public can view cinemas"
on public.cinemas for select
using (true);

create policy "Public can view screens"
on public.screens for select
using (true);

-- Policies for Food Items (Publicly Readable for the specific cinema)
create policy "Public can view food items"
on public.food_items for select
using (true);

-- Policies for Orders (Customers see their own, Cinemas see theirs)
create policy "Customers can view their own orders"
on public.orders for select
using (auth.uid() = customer_id);

create policy "Cinemas can view their own orders"
on public.orders for select
using (
  exists (
    select 1 from public.cinemas
    where public.cinemas.id = public.orders.cinema_id
    and public.cinemas.owner_id = auth.uid()
  )
);

