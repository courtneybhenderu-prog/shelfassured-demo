-- stores schema
select column_name, data_type
from information_schema.columns
where table_name='stores' order by 1;

-- sample stores
select id, banner_id, store_chain, name, address, city, state, zip_code
from stores order by created_at desc nulls last limit 25;

-- canonical banners
select rb.id as banner_id, rb.name as banner_name, r.name as parent
from retailer_banners rb join retailers r on r.id = rb.retailer_id
order by banner_name;

-- view output
select * from v_distinct_banners order by 1;

-- mismatches: store_chain that don't match any banner name (case-insensitive)
with chains as (
  select lower(store_chain) as chain from stores
  where store_chain is not null group by 1
),
banners as (
  select lower(name) as banner from retailer_banners
)
select c.chain from chains c
where c.chain not in (select banner from banners);

