-- ============================================================================
-- FINAL PROJECT: ONLINE SHOP DATABASE SCHEMA
-- Author: Aiken Amanbay
-- Group: PO-1-24
-- 
-- DATABASE NAME: onlineshop_db
-- SCHEMA NAME:   onlineshop_schema
-- ============================================================================

-- ===== PART 1: SCHEMA SETUP =====

-- Establish a dedicated schema domain safely
create schema if not exists onlineshop_schema;

-- Route all future structural assignments to the new domain
set search_path to onlineshop_schema;


-- ===== PART 2: CREATE TABLES WITH CONSTRAINTS =====

create table if not exists onlineshop_schema.customer (
    customer_id serial,
    name varchar(50) not null,
    surname varchar(50) not null,
    email varchar(100) not null,
    phone varchar(11) not null,
    personal_id varchar(12) not null,
    
    constraint customer_pk primary key (customer_id),
    constraint customer_email_unique unique (email),
    constraint customer_personal_id_unique unique (personal_id)
);

create table if not exists onlineshop_schema.addresses (
    address_id serial,
    customer_id int,
    city varchar(50) not null,
    street_address varchar(150) not null,
    
    constraint addresses_pk primary key (address_id),
    constraint addresses_customer_fk foreign key (customer_id) 
        references onlineshop_schema.customer(customer_id) on delete cascade
);

create table if not exists onlineshop_schema.supplier (
    supplier_id serial,
    company_name varchar(100) not null,
    contact_name varchar(100) not null,
    phone varchar(11) not null,
    
    constraint supplier_pk primary key (supplier_id),
    constraint supplier_company_name_unique unique (company_name)
);

create table if not exists onlineshop_schema.employee (
    employee_id serial,
    name varchar(50) not null,
    surname varchar(50) not null,
    role varchar(50) not null,
    date_of_birth date not null,
    personal_id varchar(12) not null,
    
    constraint employee_pk primary key (employee_id),
    constraint employee_personal_id_unique unique (personal_id),
    constraint employee_role_check check (role in ('Manager', 'Courier', 'Seller'))
);

create table if not exists onlineshop_schema.category (
    category_id serial,
    name varchar(100) not null,
    
    constraint category_pk primary key (category_id),
    constraint category_name_unique unique (name)
);

create table if not exists onlineshop_schema.product (
    product_id serial,
    name varchar(100) not null,
    category_id int not null,
    price numeric(10, 2) not null,
    production_year int not null,
    description text default 'No description',
    
    constraint product_pk primary key (product_id),
    constraint product_category_fk foreign key (category_id) 
        references onlineshop_schema.category(category_id) on delete restrict,
    constraint product_price_check check (price >= 0)
);

create table if not exists onlineshop_schema.orders (
    order_id serial,
    customer_id int,
    order_date date not null default current_date,
    status varchar(20) not null default 'Pending',
    address_id int,
    
    constraint orders_pk primary key (order_id),
    constraint orders_customer_fk foreign key (customer_id) 
        references onlineshop_schema.customer(customer_id) on delete restrict,
    constraint orders_address_fk foreign key (address_id) 
        references onlineshop_schema.addresses(address_id) on delete restrict,
    constraint orders_status_check check (status in ('Pending', 'Processing', 'Completed', 'Cancelled'))
);

create table if not exists onlineshop_schema.payment (
    payment_id serial,
    order_id int not null,
    amount numeric(10, 2) not null,
    payment_date date not null default current_date,
    status varchar(20) not null,
    
    constraint payment_pk primary key (payment_id),
    constraint payment_order_fk foreign key (order_id) 
        references onlineshop_schema.orders(order_id) on delete cascade,
    constraint payment_order_unique unique (order_id)
);

create table if not exists onlineshop_schema.delivery (
    delivery_id serial,
    order_id int,
    employee_id int,
    delivery_date date not null,
    status varchar(20) not null,
    
    constraint delivery_pk primary key (delivery_id),
    constraint delivery_order_fk foreign key (order_id) 
        references onlineshop_schema.orders(order_id) on delete cascade,
    constraint delivery_employee_fk foreign key (employee_id) 
        references onlineshop_schema.employee(employee_id) on delete set null,
    constraint delivery_date_check check (delivery_date > date '2026-01-01')
);

create table if not exists onlineshop_schema.order_items (
    order_item_id serial,
    order_id int,
    product_id int,
    quantity int not null,
    unit_price numeric(10, 2) not null,
    total_price numeric(10, 2) generated always as (quantity * unit_price) stored,
    
    constraint order_items_pk primary key (order_item_id),
    constraint order_items_order_fk foreign key (order_id) 
        references onlineshop_schema.orders(order_id) on delete cascade,
    constraint order_items_product_fk foreign key (product_id) 
        references onlineshop_schema.product(product_id) on delete restrict,
    constraint order_items_quantity_check check (quantity > 0)
);

create table if not exists onlineshop_schema.product_supplier (
    product_supplier_id serial,
    product_id int,
    supplier_id int,
    supply_date date not null default current_date,
    
    constraint product_supplier_pk primary key (product_supplier_id),
    constraint product_supplier_product_fk foreign key (product_id) 
        references onlineshop_schema.product(product_id) on delete restrict,
    constraint product_supplier_supplier_fk foreign key (supplier_id) 
        references onlineshop_schema.supplier(supplier_id) on delete cascade
);


-- ===== PART 3: ALTER TABLE OPERATIONS =====

-- 1. phone column was varchar(11) but expanding it to varchar(20) ensures support for spaces, dashes, or international prefix formats.
alter table onlineshop_schema.customer alter column phone type varchar(20);

-- 2. adding a new tracking column to calculate and support loyalty program points for user retention strategies.
alter table onlineshop_schema.customer add column if not exists loyalty_points int;

-- 3. setting a baseline default constraint so that new customer profiles register with 0 loyalty points instead of null.
alter table onlineshop_schema.customer alter column loyalty_points set default 0;

-- 4. renaming production_year to release_year safely using dynamic execution
do $$
begin
    if exists(select * from information_schema.columns where table_schema='onlineshop_schema' and table_name='product' and column_name='production_year') then
        execute 'alter table onlineshop_schema.product rename column production_year to release_year';
    end if;
end $$;

-- 5. imposing a stricter lower limit constraint on delivery schedules safely using dynamic execution
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'delivery_date_past_check') then
        execute 'alter table onlineshop_schema.delivery add constraint delivery_date_past_check check (delivery_date >= ''2026-01-01'')';
    end if;
end $$;


-- ===== PART 4: DATA INSERTION =====

-- safely purging old row instances and restarting sequences across all tables without executing table structural resets.
truncate table 
    onlineshop_schema.product_supplier, 
    onlineshop_schema.order_items, 
    onlineshop_schema.delivery, 
    onlineshop_schema.payment, 
    onlineshop_schema.orders, 
    onlineshop_schema.product, 
    onlineshop_schema.category, 
    onlineshop_schema.employee, 
    onlineshop_schema.supplier, 
    onlineshop_schema.addresses, 
    onlineshop_schema.customer 
restart identity cascade;

insert into onlineshop_schema.customer (name, surname, email, phone, personal_id, loyalty_points) values
('Диас', 'Ермеков', 'dias.ermekov@shop.kz', '77011112233', '040101500111', 150),
('Айкен', 'Аманбай', 'aiken.amanbay@shop.kz', '77022223344', '050202600222', 300),
('Асылай', 'Әміржанқызы', 'asylai.am@shop.kz', '77033334455', '040303500333', 50),
('Әсел', 'Балғабай', 'asel.balgabai@shop.kz', '77044445566', '040404600444', 120),
('Ильнур', 'Гарифов', 'ilnur.garifov@shop.kz', '77055556677', '030505500555', 0),
('Арслан', 'Гайниденұлы', 'arslan.g@shop.kz', '77066667788', '040606500666', 210),
('Каусар', 'Ерболатқызы', 'kausar.e@shop.kz', '77077778899', '050707600777', 95),
('Нұрдаулет', 'Жұмабай', 'nurdaulet.zh@shop.kz', '77088889900', '040808500888', 180),
('Асылай', 'Жумакулова', 'asylai.zh@shop.kz', '77099990011', '040909600999', 40),
('Айша', 'Жұмағали', 'aisha.zh@shop.kz', '77011122233', '051010601000', 340);

insert into onlineshop_schema.addresses (customer_id, city, street_address) values
((select customer_id from onlineshop_schema.customer where email = 'dias.ermekov@shop.kz'), 'Almaty', 'Abay Avenue 45, App 12'),
((select customer_id from onlineshop_schema.customer where email = 'aiken.amanbay@shop.kz'), 'Astana', 'Mangilik El Avenue 23, App 89'),
((select customer_id from onlineshop_schema.customer where email = 'asel.balgabai@shop.kz'), 'Atyrau', 'Satpayev Street 15, App 4'),
((select customer_id from onlineshop_schema.customer where email = 'arslan.g@shop.kz'), 'Shymkent', 'Tauke Khan Avenue 102, App 55'),
((select customer_id from onlineshop_schema.customer where email = 'nurdaulet.zh@shop.kz'), 'Karaganda', 'Bukhar-Zhyrau Avenue 12, App 34');

insert into onlineshop_schema.supplier (company_name, contact_name, phone) values
('Tech Wholesale KZ', 'Артур Курмашев', '77051111111'),
('Global Fashion Logistics', 'Арнұр Қамай', '77052222222'),
('Eco Goods Distributing', 'Инабат Қайрақбай', '77053333333'),
('Smart Home Solutions', 'Сымбат Қадырғали', '77054444444'),
('Premium Import Almaty', 'Максим Ли', '77055555555');

insert into onlineshop_schema.employee (name, surname, role, date_of_birth, personal_id) values
('Молдир', 'Олжабаева', 'Manager', '1992-05-14', '920514400123'),
('Райхан', 'Сахташева', 'Seller', '1995-08-23', '950823400456'),
('Дауренбек', 'Табылды', 'Courier', '1998-11-02', '981102300789'),
('Саида', 'Тауман', 'Manager', '1994-03-19', '940319400321'),
('Аружан', 'Тулегеновна', 'Courier', '2000-01-30', '000130500654');

insert into onlineshop_schema.category (name) values
('Electronics'),
('Clothing & Apparel'),
('Home & Kitchen'),
('Books & Stationery'),
('Sports & Outdoors');

insert into onlineshop_schema.product (name, category_id, price, release_year, description) values
('Smartphone Galaxy X', (select category_id from onlineshop_schema.category where name = 'Electronics'), 450000.00, 2026, 'Flagship smartphone with AI features'),
('Wireless Noise-Canceling Headphones', (select category_id from onlineshop_schema.category where name = 'Electronics'), 120000.00, 2025, 'Premium audio experience'),
('Oversized Cotton Hoodie', (select category_id from onlineshop_schema.category where name = 'Clothing & Apparel'), 25000.00, 2026, 'Comfortable 100% cotton streetwear'),
('Slim Fit Denim Jeans', (select category_id from onlineshop_schema.category where name = 'Clothing & Apparel'), 35000.00, 2025, 'Classic durable blue jeans'),
('Smart Drip Coffee Maker', (select category_id from onlineshop_schema.category where name = 'Home & Kitchen'), 55000.00, 2026, 'Programmable brewer with Wi-Fi control'),
('Ergonomic Memory Foam Pillow', (select category_id from onlineshop_schema.category where name = 'Home & Kitchen'), 18000.00, 2025, 'Orthopedic neck support pillow'),
('Advanced Database Systems Textbook', (select category_id from onlineshop_schema.category where name = 'Books & Stationery'), 15000.00, 2024, 'Comprehensive guide to SQL and NoSQL'),
('Leather Bound Daily Planner 2026', (select category_id from onlineshop_schema.category where name = 'Books & Stationery'), 8500.00, 2025, 'Elegant agenda for professional tracking'),
('Waterproof Camping Tent 4-Person', (select category_id from onlineshop_schema.category where name = 'Sports & Outdoors'), 85000.00, 2025, 'Double layer wind-resistant structure'),
('Stainless Steel Vacuum Water Bottle', (select category_id from onlineshop_schema.category where name = 'Sports & Outdoors'), 12000.00, 2026, 'Keeps beverages cold up to 24 hours');

insert into onlineshop_schema.orders (customer_id, order_date, status, address_id) values
(
    (select customer_id from onlineshop_schema.customer where email = 'aiken.amanbay@shop.kz'), 
    '2026-06-01', 'Processing', 
    (select address_id from onlineshop_schema.addresses where customer_id = (select customer_id from onlineshop_schema.customer where email = 'aiken.amanbay@shop.kz'))
),
(
    (select customer_id from onlineshop_schema.customer where email = 'dias.ermekov@shop.kz'), 
    '2026-06-02', 'Pending', 
    (select address_id from onlineshop_schema.addresses where customer_id = (select customer_id from onlineshop_schema.customer where email = 'dias.ermekov@shop.kz'))
),
(
    (select customer_id from onlineshop_schema.customer where email = 'asel.balgabai@shop.kz'), 
    '2026-06-03', 'Completed', 
    (select address_id from onlineshop_schema.addresses where customer_id = (select customer_id from onlineshop_schema.customer where email = 'asel.balgabai@shop.kz'))
),
(
    (select customer_id from onlineshop_schema.customer where email = 'arslan.g@shop.kz'), 
    '2026-06-04', 'Cancelled', 
    (select address_id from onlineshop_schema.addresses where customer_id = (select customer_id from onlineshop_schema.customer where email = 'arslan.g@shop.kz'))
),
(
    (select customer_id from onlineshop_schema.customer where email = 'nurdaulet.zh@shop.kz'), 
    '2026-06-04', 'Pending', 
    (select address_id from onlineshop_schema.addresses where customer_id = (select customer_id from onlineshop_schema.customer where email = 'nurdaulet.zh@shop.kz'))
);

insert into onlineshop_schema.payment (order_id, amount, payment_date, status) values
((select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'aiken.amanbay@shop.kz') and order_date = '2026-06-01'), 450000.00, '2026-06-01', 'Paid'),
((select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'dias.ermekov@shop.kz') and order_date = '2026-06-02'), 25000.00, '2026-06-02', 'Awaiting Payment'),
((select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'asel.balgabai@shop.kz') and order_date = '2026-06-03'), 53000.00, '2026-06-03', 'Paid'),
((select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'arslan.g@shop.kz') and order_date = '2026-06-04'), 85000.00, '2026-06-04', 'Refunded'),
((select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'nurdaulet.zh@shop.kz') and order_date = '2026-06-04'), 12000.00, '2026-06-04', 'Awaiting Payment');

insert into onlineshop_schema.delivery (order_id, employee_id, delivery_date, status) values
(
    (select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'aiken.amanbay@shop.kz') and order_date = '2026-06-01'),
    (select employee_id from onlineshop_schema.employee where personal_id = '981102300789'), '2026-06-05', 'In Transit'
),
(
    (select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'asel.balgabai@shop.kz') and order_date = '2026-06-03'),
    (select employee_id from onlineshop_schema.employee where personal_id = '000130500654'), '2026-06-04', 'Delivered'
),
(
    (select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'dias.ermekov@shop.kz') and order_date = '2026-06-02'),
    (select employee_id from onlineshop_schema.employee where personal_id = '981102300789'), '2026-06-06', 'Scheduled'
),
(
    (select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'nurdaulet.zh@shop.kz') and order_date = '2026-06-04'),
    (select employee_id from onlineshop_schema.employee where personal_id = '000130500654'), '2026-06-07', 'Scheduled'
),
(
    (select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'arslan.g@shop.kz') and order_date = '2026-06-04'),
    null, '2026-06-04', 'Cancelled'
);

insert into onlineshop_schema.order_items (order_id, product_id, quantity, unit_price) values
(
    (select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'aiken.amanbay@shop.kz') and order_date = '2026-06-01'),
    (select product_id from onlineshop_schema.product where name = 'Smartphone Galaxy X'), 1, 450000.00
),
(
    (select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'dias.ermekov@shop.kz') and order_date = '2026-06-02'),
    (select product_id from onlineshop_schema.product where name = 'Oversized Cotton Hoodie'), 1, 25000.00
),
(
    (select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'asel.balgabai@shop.kz') and order_date = '2026-06-03'),
    (select product_id from onlineshop_schema.product where name = 'Slim Fit Denim Jeans'), 1, 35000.00
),
(
    (select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'asel.balgabai@shop.kz') and order_date = '2026-06-03'),
    (select product_id from onlineshop_schema.product where name = 'Ergonomic Memory Foam Pillow'), 1, 18000.00
),
(
    (select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'nurdaulet.zh@shop.kz') and order_date = '2026-06-04'),
    (select product_id from onlineshop_schema.product where name = 'Stainless Steel Vacuum Water Bottle'), 1, 12000.00
);

insert into onlineshop_schema.product_supplier (product_id, supplier_id, supply_date)
select p.product_id, s.supplier_id, current_date
from onlineshop_schema.product as p
cross join onlineshop_schema.supplier as s
where (p.name like '%Galaxy%' and s.company_name = 'Tech Wholesale KZ')
   or (p.name like '%Headphones%' and s.company_name = 'Tech Wholesale KZ')
   or (p.name like '%Hoodie%' and s.company_name = 'Global Fashion Logistics')
   or (p.name like '%Jeans%' and s.company_name = 'Global Fashion Logistics')
   or (p.name like '%Bottle%' and s.company_name = 'Eco Goods Distributing');


-- ===== PART 5: UPDATE & DELETE OPERATIONS =====

-- change order workflows status tracking properties to complete once validated payments process.
update onlineshop_schema.orders 
set status = 'Completed' 
where order_id = (select order_id from onlineshop_schema.orders where customer_id = (select customer_id from onlineshop_schema.customer where email = 'aiken.amanbay@shop.kz') and order_date = '2026-06-01');

-- systematically allocate 100 loyalty bonuses to accounts processing distinct active orders on specific dates.
update onlineshop_schema.customer
set loyalty_points = loyalty_points + 100
where customer_id in (
    select customer_id 
    from onlineshop_schema.orders 
    where order_date = '2026-06-03'
);

-- Delete cancelled orders and return their data (Executes normally without manual rollback triggers)
delete from onlineshop_schema.orders
where status = 'Cancelled'
returning order_id, customer_id, order_date;


-- ===== PART 6: GRANT & REVOKE =====

-- execute conditional role construction safely using dynamic SQL
do $$
begin
    if not exists (select from pg_catalog.pg_roles where rolname = 'onlineshop_readonly') then
        execute 'create role onlineshop_readonly';
    end if;

    if not exists (select from pg_catalog.pg_roles where rolname = 'onlineshop_writer') then
        execute 'create role onlineshop_writer';
    end if;
end
$$;

-- dispatch read-only lookup scopes across the public data entities schemas to reporting groups.
grant select on all tables in schema onlineshop_schema to onlineshop_readonly;

-- dispatch specific entry creation permissions across primary transactional layers to service programs.
grant insert, update on onlineshop_schema.orders to onlineshop_writer;
grant insert, update on onlineshop_schema.order_items to onlineshop_writer;

-- strip update controls from service application entities to guarantee chronological data tracking is immutable.
revoke update on onlineshop_schema.orders from onlineshop_writer;
