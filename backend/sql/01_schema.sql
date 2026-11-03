
create type invoice_status as enum ('draft', 'approved', 'cancelled');
create type tax_mode       as enum ('exclusive', 'inclusive');

create table currencies (
  code    char(3) primary key,
  name    text    not null,
  symbol  text    not null
);

create table items (
  id          uuid          primary key default gen_random_uuid(),
  barcode     text          not null unique,
  name        text          not null,
  unit_price  numeric(12,2) not null check (unit_price >= 0)
);

create table users (
  id                uuid         primary key references auth.users(id) on delete cascade,
  username          text         not null,
  email             text         not null unique,
  default_currency  char(3)      not null default 'USD' references currencies(code),
  default_tax_mode  tax_mode     not null default 'exclusive',
  default_tax_rate  numeric(5,2) not null default 15
);

create table invoice_sequences (
  user_id      uuid    not null references users(id),
  prefix       text    not null,
  year         integer not null,
  last_number  integer not null default 0,
  primary key (user_id, prefix, year)
);

create table invoices (
  id             uuid           primary key default gen_random_uuid(),
  created_by     uuid           not null default auth.uid() references users(id),
  prefix         text           not null,
  invoice_no     text           not null,                          -- INV-2026-000001
  status         invoice_status not null default 'draft',
  invoice_date   date           not null default current_date,
  customer_name  text           not null,

  currency_code  char(3)        not null references currencies(code),
  exchange_rate  numeric(12,4)  not null check (exchange_rate > 0), -- USD per 1 unit of invoice currency
  tax_mode       tax_mode       not null,
  tax_rate       numeric(5,2)   not null check (tax_rate between 0 and 100),

  subtotal       numeric(12,2)  not null default 0,
  tax_total      numeric(12,2)  not null default 0,
  total          numeric(12,2)  not null default 0,

  cancel_reason  text,
  created_at     timestamptz    not null default now(),

  unique (created_by, invoice_no)
);

create index on invoices (created_by, status, created_at desc);

create table invoice_items (
  id          uuid          primary key default gen_random_uuid(),
  invoice_id  uuid          not null references invoices(id),
  line_no     smallint      not null,
  item_id     uuid          not null references items(id),
  item_name   text          not null,
  unit_price  numeric(12,2) not null check (unit_price >= 0),
  qty         integer       not null check (qty > 0),
  line_net    numeric(12,2) not null,
  line_tax    numeric(12,2) not null,
  line_total  numeric(12,2) not null,
  unique (invoice_id, line_no)
);
