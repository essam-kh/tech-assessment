
insert into currencies (code, name, symbol) values
  ('USD', 'US Dollar',      '$'),
  ('EUR', 'Euro',           '€'),
  ('SAR', 'Saudi Riyal',    '﷼'),
  ('EGP', 'Egyptian Pound', 'E£');

insert into items (barcode, name, unit_price) values
  ('6281001234567', 'Arabic Coffee 500g', 12.50),
  ('6281009876543', 'Dates Box 1kg',      18.00),
  ('5449000000996', 'Cola 330ml',          0.90),
  ('4006381333931', 'Marker Pen Set (6)',  6.40),
  ('8901234567890', 'Notebook A5',         3.25),
  ('6281002345678', 'Olive Oil 1L',       14.90),
  ('6281004567890', 'Black Tea 100 bags',  4.80),
  ('6281006789012', 'Chocolate Bar 100g',  1.75),
  ('6281007890123', 'Dish Soap 750ml',     3.10);

insert into users (id, username, email)
select id, 'essam khader', email from auth.users where email = 'essamgt123@gmail.com';
