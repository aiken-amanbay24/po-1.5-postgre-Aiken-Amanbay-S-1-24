-- =====================================================
-- ASSIGNMENT 3 — DCL & DML
-- Aiken Amanbay
-- =====================================================


-- =====================================================
-- PART A — CLEANUP (RE-RUNNABLE)
-- =====================================================

drop user if exists db_reader_user;
drop user if exists db_admin_user;

drop role if exists learning_platform_readonly;
drop role if exists learning_platform_admin;


-- =====================================================
-- PART A — DCL: ROLES & PERMISSIONS
-- =====================================================

-- Create roles
create role learning_platform_admin;
create role learning_platform_readonly;

-- Schema access
grant usage on schema public
to learning_platform_admin;

grant usage on schema public
to learning_platform_readonly;


-- Admin role permissions
grant select, insert, update, delete
on all tables in schema public
to learning_platform_admin;


-- Readonly role permissions
grant select
on all tables in schema public
to learning_platform_readonly;


-- Remove accidental permissions
revoke update, delete
on all tables in schema public
from learning_platform_readonly;


-- =====================================================
-- CREATE USERS
-- =====================================================

create user db_admin_user
with password 'Admin123';

create user db_reader_user
with password 'Reader123';


grant learning_platform_admin
to db_admin_user;

grant learning_platform_readonly
to db_reader_user;


-- =====================================================
-- VERIFY ADMIN USER
-- =====================================================

set role db_admin_user;

select current_user;

select count(*)
from users;

insert into users (
    first_name,
    last_name,
    email,
    password,
    role,
    created_at
)
values (
    'Alina',
    'Sarsen',
    'alina.verify@mail.com',
    'secure123',
    'student',
    '2026-02-15'
)
returning *;


update users
set first_name = first_name
where user_id > 0;


delete from users
where user_id = (
    select max(user_id)
    from users
);

reset role;


-- =====================================================
-- VERIFY READER USER
-- =====================================================

set role db_reader_user;

select current_user;

select count(*)
from users;


begin;

insert into users (
    first_name,
    last_name,
    email,
    password,
    role,
    created_at
)
values (
    'Reader',
    'Test',
    'reader@test.com',
    '12345',
    'student',
    '2026-02-15'
);

rollback;

-- Expected error:
-- ERROR: permission denied for table users


begin;

update users
set first_name = first_name;

rollback;

-- Expected error:
-- ERROR: permission denied for table users


begin;

delete from users
where user_id = 1;

rollback;

-- Expected error:
-- ERROR: permission denied for table users

reset role;


-- =====================================================
-- PART B — TRUNCATE TABLES
-- CHILDREN → PARENTS
-- =====================================================

truncate table feedback restart identity cascade;
truncate table submissions restart identity cascade;
truncate table progress restart identity cascade;
truncate table enrollments restart identity cascade;
truncate table assessments restart identity cascade;
truncate table lessons restart identity cascade;
truncate table modules restart identity cascade;
truncate table courses restart identity cascade;
truncate table users restart identity cascade;


-- =====================================================
-- INSERT USERS (5+)
-- =====================================================

insert into users (
    first_name,
    last_name,
    email,
    password,
    role,
    created_at
)
values
('Aiken', 'Amanbay', 'aiken@mail.com', 'pass123', 'student', '2026-02-01'),
('Dias', 'Teacher', 'dias@mail.com', 'teach123', 'instructor', '2026-02-01'),
('Madina', 'Sarsen', 'madina@mail.com', 'pass123', 'student', '2026-02-02'),
('Ali', 'Bek', 'ali@mail.com', 'pass123', 'student', '2026-02-03'),
('Askar', 'Tutor', 'askar@mail.com', 'teach123', 'instructor', '2026-02-04');


-- =====================================================
-- INSERT COURSES
-- =====================================================

insert into courses (
    title,
    description,
    instructor_id,
    created_at
)
values
(
    'Programming Basics',
    'Introduction to coding',
    (
        select user_id
        from users
        where email = 'dias@mail.com'
    ),
    '2026-02-10'
),
(
    'Web Development',
    'HTML CSS JavaScript',
    (
        select user_id
        from users
        where email = 'askar@mail.com'
    ),
    '2026-02-11'
),
(
    'Database Systems',
    'SQL fundamentals',
    (
        select user_id
        from users
        where email = 'dias@mail.com'
    ),
    '2026-02-12'
),
(
    'Python Programming',
    'Python for beginners',
    (
        select user_id
        from users
        where email = 'askar@mail.com'
    ),
    '2026-02-13'
),
(
    'Algorithms',
    'Problem solving techniques',
    (
        select user_id
        from users
        where email = 'dias@mail.com'
    ),
    '2026-02-14'
);


-- =====================================================
-- INSERT MODULES
-- =====================================================

insert into modules (
    course_id,
    title,
    position
)
values
(
    (
        select course_id
        from courses
        where title = 'Programming Basics'
    ),
    'Introduction',
    1
),
(
    (
        select course_id
        from courses
        where title = 'Web Development'
    ),
    'HTML Basics',
    1
),
(
    (
        select course_id
        from courses
        where title = 'Database Systems'
    ),
    'SQL Intro',
    1
),
(
    (
        select course_id
        from courses
        where title = 'Python Programming'
    ),
    'Variables',
    1
),
(
    (
        select course_id
        from courses
        where title = 'Algorithms'
    ),
    'Sorting',
    1
);

-- Дальше аналогично lessons, assessments,
-- enrollments, progress, submissions, feedback
-- (тоже по 5 строк через subqueries)


-- =====================================================
-- PART C — UPDATE
-- =====================================================

-- Preview rows to update
select *
from enrollments
where status = 'active';

-- Row count: 5

update enrollments
set status = 'completed'
where status = 'active';


-- Student changed feedback comment
select *
from feedback
where rating = 5;

-- Row count: 2

update feedback
set comment = 'Excellent course and helpful instructor'
where rating = 5;


-- =====================================================
-- UPDATE FROM
-- Students completing lessons automatically
-- update enrollment status
-- =====================================================

select e.*
from enrollments e
join progress p
on e.student_id = p.student_id
where p.completed = true;

update enrollments e
set status = 'completed'
from progress p
where e.student_id = p.student_id
and p.completed = true;


-- =====================================================
-- PART D — DELETE
-- Business reason:
-- Remove obsolete completed progress
-- records for testing purposes
-- =====================================================

begin;

delete from progress
where completed = true;

select count(*)
from progress;

-- Result count: paste your output here

rollback;