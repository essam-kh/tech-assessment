create or replace function calc_line(
  p_base_price    numeric,
  p_exchange_rate numeric,
  p_qty           integer,
  p_tax_mode      tax_mode,
  p_tax_rate      numeric
)
returns table (unit_price numeric, line_net numeric, line_tax numeric, line_total numeric)
language plpgsql
immutable
as $$
declare
  v_rate numeric := p_tax_rate / 100;
begin
  unit_price := round(p_base_price / p_exchange_rate, 2);

  if p_tax_mode = 'exclusive' then
    line_net   := unit_price * p_qty;
    line_tax   := round(line_net * v_rate, 2);
    line_total := line_net + line_tax;
  else
    line_total := unit_price * p_qty;
    line_net   := round(line_total / (1 + v_rate), 2);
    line_tax   := line_total - line_net;
  end if;

  return next;
end;
$$;

create or replace function create_invoice(
  p_prefix        text,
  p_customer_name text,
  p_currency_code text,
  p_exchange_rate numeric,
  p_tax_mode      tax_mode,
  p_tax_rate      numeric,
  p_lines         jsonb
)
returns invoices
language plpgsql
as $$
declare
  v_user     uuid    := auth.uid();
  v_year     integer := extract(year from current_date)::integer;
  v_rate     numeric := round(p_exchange_rate, 4);
  v_tax_rate numeric := round(p_tax_rate, 2);
  v_number   integer;
  v_count    integer;
  v_invoice  invoices;
begin
  if v_user is null then
    raise exception 'Not signed in';
  end if;
  if p_prefix is null or p_prefix !~ '^[A-Z]{1,6}$' then
    raise exception 'Prefix must be 1 to 6 capital letters';
  end if;
  if btrim(coalesce(p_customer_name, '')) = '' then
    raise exception 'Customer name is required';
  end if;
  if not exists (select 1 from currencies where code = upper(p_currency_code)) then
    raise exception 'Unknown currency';
  end if;
  if v_rate is null or v_rate <= 0 then
    raise exception 'Exchange rate must be above 0';
  end if;
  if v_tax_rate is null or v_tax_rate < 0 or v_tax_rate > 100 then
    raise exception 'Tax rate must be between 0 and 100';
  end if;
  if p_lines is null or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) = 0 then
    raise exception 'Add at least one item';
  end if;
  if exists (
    select 1
    from jsonb_to_recordset(p_lines) as l(item_id uuid, qty integer)
    where l.item_id is null or l.qty is null or l.qty < 1
  ) then
    raise exception 'Each line needs an item and a quantity of at least 1';
  end if;

  insert into invoice_sequences (user_id, prefix, year, last_number)
  values (v_user, p_prefix, v_year, 1)
  on conflict (user_id, prefix, year)
  do update set last_number = invoice_sequences.last_number + 1
  returning last_number into v_number;

  insert into invoices (
    created_by, prefix, invoice_no, customer_name,
    currency_code, exchange_rate, tax_mode, tax_rate
  )
  values (
    v_user, p_prefix, p_prefix || '-' || v_year || '-' || lpad(v_number::text, 6, '0'),
    btrim(p_customer_name), upper(p_currency_code), v_rate, p_tax_mode, v_tax_rate
  )
  returning * into v_invoice;

  insert into invoice_items (
    invoice_id, line_no, item_id, item_name,
    unit_price, qty, line_net, line_tax, line_total
  )
  select v_invoice.id, l.line_no::smallint, i.id, i.name,
         c.unit_price, l.qty, c.line_net, c.line_tax, c.line_total
  from (
    select e.line_no,
           (e.elem ->> 'item_id')::uuid as item_id,
           (e.elem ->> 'qty')::integer  as qty
    from jsonb_array_elements(p_lines) with ordinality as e(elem, line_no)
  ) l
  join items i on i.id = l.item_id
  cross join lateral calc_line(i.unit_price, v_rate, l.qty, p_tax_mode, v_tax_rate) c;

  get diagnostics v_count = row_count;
  if v_count <> jsonb_array_length(p_lines) then
    raise exception 'One or more items do not exist';
  end if;

  update invoices
  set subtotal  = t.net,
      tax_total = t.tax,
      total     = t.total
  from (
    select sum(line_net) as net, sum(line_tax) as tax, sum(line_total) as total
    from invoice_items
    where invoice_id = v_invoice.id
  ) t
  where invoices.id = v_invoice.id
  returning invoices.* into v_invoice;

  return v_invoice;
end;
$$;

create or replace function get_invoice(p_id uuid)
returns jsonb
language sql
stable
as $$
  select to_jsonb(i) || jsonb_build_object(
    'items',
    coalesce(
      (select jsonb_agg(to_jsonb(l) order by l.line_no)
       from invoice_items l
       where l.invoice_id = i.id),
      '[]'::jsonb
    )
  )
  from invoices i
  where i.id = p_id and i.created_by = auth.uid();
$$;

create or replace function list_invoices(
  p_status invoice_status default null,
  p_search text           default null,
  p_limit  integer        default 50,
  p_offset integer        default 0
)
returns setof invoices
language sql
stable
as $$
  select *
  from invoices
  where created_by = auth.uid()
    and (p_status is null or status = p_status)
    and (
      nullif(btrim(p_search), '') is null
      or strpos(lower(invoice_no), lower(btrim(p_search))) > 0
      or strpos(lower(customer_name), lower(btrim(p_search))) > 0
    )
  order by created_at desc, invoice_no desc
  limit p_limit offset p_offset;
$$;

create or replace function approve_invoice(p_id uuid)
returns invoices
language plpgsql
as $$
declare
  v_invoice invoices;
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;

  select * into v_invoice
  from invoices
  where id = p_id and created_by = auth.uid()
  for update;

  if not found then
    raise exception 'Invoice not found';
  end if;
  if v_invoice.status <> 'draft' then
    raise exception 'Only draft invoices can be approved';
  end if;

  update invoices
  set status = 'approved'
  where id = p_id
  returning * into v_invoice;

  return v_invoice;
end;
$$;

create or replace function cancel_invoice(p_id uuid, p_reason text)
returns invoices
language plpgsql
as $$
declare
  v_invoice invoices;
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;
  if btrim(coalesce(p_reason, '')) = '' then
    raise exception 'A cancel reason is required';
  end if;

  select * into v_invoice
  from invoices
  where id = p_id and created_by = auth.uid()
  for update;

  if not found then
    raise exception 'Invoice not found';
  end if;
  if v_invoice.status = 'approved' then
    raise exception 'Approved invoices cannot be cancelled';
  end if;
  if v_invoice.status = 'cancelled' then
    raise exception 'Invoice is already cancelled';
  end if;

  update invoices
  set status = 'cancelled',
      cancel_reason = btrim(p_reason)
  where id = p_id
  returning * into v_invoice;

  return v_invoice;
end;
$$;

create or replace function lock_invoice()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'Invoices cannot be deleted. Cancel them instead.';
  end if;
  if old.status <> 'draft' then
    raise exception 'Only draft invoices can be changed';
  end if;
  if new.invoice_no <> old.invoice_no
     or new.prefix <> old.prefix
     or new.created_by <> old.created_by then
    raise exception 'Invoice number and owner cannot be changed';
  end if;
  if new.status = 'cancelled' and btrim(coalesce(new.cancel_reason, '')) = '' then
    raise exception 'A cancel reason is required';
  end if;
  return new;
end;
$$;

drop trigger if exists invoices_lock on invoices;
create trigger invoices_lock
  before update or delete on invoices
  for each row execute function lock_invoice();

create or replace function lock_invoice_items()
returns trigger
language plpgsql
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    if (select status from invoices where id = old.invoice_id) is distinct from 'draft' then
      raise exception 'Only draft invoices can be changed';
    end if;
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    if (select status from invoices where id = new.invoice_id) is distinct from 'draft' then
      raise exception 'Only draft invoices can be changed';
    end if;
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

drop trigger if exists invoice_items_lock on invoice_items;
create trigger invoice_items_lock
  before insert or update or delete on invoice_items
  for each row execute function lock_invoice_items();
