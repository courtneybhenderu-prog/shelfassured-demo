-- Fix Retailer Normalization and Unique Index
-- Run this in Supabase SQL editor

-- 1. Create retailers table
create table if not exists retailers (
  id uuid primary key default gen_random_uuid(),
  name text unique not null
);

-- 2. Create retailer_aliases table
create table if not exists retailer_aliases (
  alias text primary key,
  retailer_id uuid not null references retailers(id)
);

-- 3. Insert canonical retailers
insert into retailers(name) values ('H-E-B'), ('Kroger')
on conflict do nothing;

-- 4. Insert retailer aliases
insert into retailer_aliases(alias, retailer_id)
select x.alias, r.id
from (values
  ('heb','H-E-B'),
  ('h-e-b','H-E-B'),
  ('h e b','H-E-B'),
  ('heb grocery','H-E-B'),
  ('kroger','Kroger'),
  ('kroger marketplace','Kroger'),
  ('kroger co','Kroger')
) as x(alias, canon)
join retailers r on r.name = x.canon
on conflict do nothing;

-- 5. Add columns to stores table if they don't exist
alter table stores
  add column if not exists retailer_id uuid,
  add column if not exists street_norm text,
  add column if not exists city_norm text,
  add column if not exists state text,
  add column if not exists zip5 text;

-- 6. Update existing stores with retailer_id
update stores s
set retailer_id = ra.retailer_id
from retailer_aliases ra
where lower(coalesce(s.store_chain, s.retailer_norm)) = ra.alias
  and s.retailer_id is null;

-- 7. Backfill normalized address fields
update stores
set street_norm = lower(regexp_replace(address, '\s+', ' ', 'g')),
    city_norm   = lower(city),
    state       = upper(split_part(zip_code, ' ', 1))
where street_norm is null or city_norm is null or state is null;

update stores
set zip5 = left(regexp_replace(zip_code, '\D', '', 'g'), 5)
where zip5 is null and zip_code is not null;

-- 8. Drop old index if it exists
drop index if exists stores_unique_norm;

-- 9. Create new unique index using retailer_id
create unique index if not exists stores_unique_norm
on stores (retailer_id, street_norm, city_norm, state, zip5)
where retailer_id is not null and street_norm is not null 
  and city_norm is not null and state is not null and zip5 is not null;

-- 10. Verify
select 
  count(*) as total_stores,
  count(retailer_id) as stores_with_retailer_id,
  count(distinct retailer_id) as unique_retailers
from stores;

