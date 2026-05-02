-- 5. User Profiles & RBAC
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  full_name text,
  role text not null default 'CUSTOMER' check (role in ('CUSTOMER', 'SUPER_ADMIN', 'OUTLET_MANAGER')),
  cinema_id uuid references public.cinemas(id), -- Null for CUSTOMER and SUPER_ADMIN
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

-- Profile Policies
create policy "Users can view their own profile"
on public.profiles for select
using (auth.uid() = id);

create policy "Super admins can manage all profiles"
on public.profiles for all
using (
  exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'SUPER_ADMIN'
  )
);

-- Update Cinema Policies for Super Admin and Managers
drop policy if exists "Cinemas can view their own orders" on public.orders;

-- Ensure cinemas and screens are publicly readable for customer browsing
create policy if not exists "Public can view cinemas"
on public.cinemas for select
using (true);

create policy if not exists "Public can view screens"
on public.screens for select
using (true);

create policy "Staff can manage orders"
on public.orders for all
using (
  exists (
    select 1 from public.profiles
    where profiles.id = auth.uid() 
    and (
      profiles.role = 'SUPER_ADMIN' 
      or (profiles.role = 'OUTLET_MANAGER' and profiles.cinema_id = public.orders.cinema_id)
    )
  )
);

-- Function to handle new user creation
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role, cinema_id)
  values (
    new.id, 
    new.raw_user_meta_data->>'full_name', 
    coalesce(new.raw_user_meta_data->>'role', 'CUSTOMER'),
    (new.raw_user_meta_data->>'cinema_id')::uuid
  );
  return new;
end;
$$ language plpgsql security modeller;

-- Trigger to create profile on signup
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
