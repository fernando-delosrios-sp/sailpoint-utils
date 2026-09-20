-- Generic HR account feed for a SailPoint Web Services source.
-- Vanilla PostgreSQL: drop, create, and load in one script.
-- Re-runnable. On Supabase, also locks the table down to service_role when that role exists.

begin;

drop table if exists public."MelonHRM" cascade;
drop table if exists public.melonhrm cascade;

create table public."MelonHRM" (
    employee_id text primary key,
    employeenumber text not null unique,
    "givenName" text not null,
    "familyName" text not null,
    middlename text,
    nickname text,
    email text,
    other_email text,
    title text,
    country text,
    city text,
    manager text,
    type text,
    empstatus text,
    otherid text,
    zipcode text,
    home_phone text,
    mobile text,
    telephone text,
    username text not null,
    department text,
    term text not null default 'false' check (term in ('true', 'false')),
    ftostart text,
    ftoend text,
    "contractStartDate" text,
    "contractEndDate" text,
    category text,
    constraint melonhrm_manager_fkey
        foreign key (manager) references public."MelonHRM" (employee_id)
        deferrable initially deferred
);

create index melonhrm_manager_idx on public."MelonHRM" (manager);

comment on table public."MelonHRM" is
    'Read-only HR account feed. One row per identity; all attributes are text.';

insert into public."MelonHRM" (
    employee_id, employeenumber, "givenName", "familyName", middlename, nickname,
    email, other_email, title, country, city, manager, type, empstatus,
    otherid, zipcode, home_phone, mobile, telephone, username, department,
    term, ftostart, ftoend, "contractStartDate", "contractEndDate", category
) values
    ('MEL0001', '101', 'Jerry', 'Bennett', null, null, 'jerry.bennett@melonhrm.example', 'Jerry.Bennett@sailpointdemo.com', 'Senior Executive', 'BE', 'Brussels', null, 'Active Employee', '5', 'HR-1001', null, null, null, null, 'jerry.bennett', 'Executive Management', 'false', '2015-03-02', null, null, null, null),
    ('MEL0002', '102', 'Aaron', 'Nichols', null, null, 'aaron.nichols@melonhrm.example', 'Aaron.Nichols@sailpointdemo.com', 'Operations Manager', 'SG', 'Singapore', 'MEL0001', 'Active Employee', '5', null, '018956', null, '+65 8000 0002', '+65 6555 0102', 'aaron.nichols', 'Executive Management', 'false', '2016-06-13', null, null, null, null),
    ('MEL0003', '103', 'Jane', 'Grant', null, null, 'jane.grant@melonhrm.example', 'Jane.Grant@sailpointdemo.com', 'SOX Access Reviewer', 'SG', 'Singapore', 'MEL0002', 'Active Employee', '5', null, null, null, null, null, 'jane.grant', 'Regional Operations', 'false', '2018-09-03', null, null, null, null),
    ('MEL0004', '104', 'Randall', 'Knight', null, 'Randy', 'randall.knight@melonhrm.example', 'Randall.Knight@sailpointdemo.com', 'Operations Director', 'JP', 'Tokyo', 'MEL0002', 'Active Employee', '5', null, null, null, '+81 90 0000 0004', '+81 3 5550 0104', 'randall.knight', 'Regional Operations', 'false', '2017-02-20', null, null, null, null),
    ('MEL0005', '105', 'Lori', 'Ferguson', null, null, 'lori.ferguson@melonhrm.example', 'Lori.Ferguson@sailpointdemo.com', 'Operations Analyst', 'CN', 'Taipei', 'MEL0002', 'Active Employee', '5', null, '100', null, null, null, 'lori.ferguson', 'Regional Operations', 'false', '2019-04-15', null, null, null, null),
    ('MEL0006', '106', 'Deb', 'Wood', null, 'Debra', 'deb.wood@melonhrm.example', 'Deb.Wood@sailpointdemo.com', 'Inventory Analyst I', 'BE', 'Brussels', 'MEL0001', 'Active Employee', '5', 'HR-1006', null, null, '+32 470 00 00 06', '+32 2 555 0106', 'deb.wood', 'Regional Operations', 'false', '2016-11-07', null, null, null, null),
    ('MEL0007', '107', 'Walter', 'Henderson', null, null, 'walter.henderson@melonhrm.example', 'Walter.Henderson@sailpointdemo.com', 'Security Architect', 'BE', 'Brussels', 'MEL0006', 'Active Employee', '5', null, null, null, null, null, 'walter.henderson', 'Information Technology', 'false', '2018-01-22', null, null, null, 'Professionals'),
    ('MEL0008', '108', 'Steph', 'Coleman', null, 'Stephanie', 'steph.coleman@melonhrm.example', 'Steph.Coleman@sailpointdemo.com', 'Telecommunications and Network Manager', 'BE', 'Brussels', 'MEL0006', 'Active Employee', '5', null, '1000', null, '+32 470 00 00 08', '+32 2 555 0108', 'steph.coleman', 'Information Technology', 'false', '2019-07-01', null, null, null, null),
    ('MEL0009', '109', 'Patrick', 'Jenkins', null, null, 'patrick.jenkins@melonhrm.example', 'Patrick.Jenkins@sailpointdemo.com', 'Staging Manager', 'BE', 'Brussels', 'MEL0006', 'Active Employee', '5', null, null, null, null, null, 'patrick.jenkins', 'Engineering', 'false', '2017-05-29', null, null, null, null),
    ('MEL0010', '110', 'Carolyn', 'Perry', null, null, 'carolyn.perry@melonhrm.example', 'Carolyn.Perry@sailpointdemo.com', 'Staging Manager', 'BE', 'Brussels', 'MEL0006', 'Active Employee', '5', null, null, null, '+32 470 00 00 10', '+32 2 555 0110', 'carolyn.perry', 'Engineering', 'false', '2020-02-17', null, null, null, null),
    ('MEL0011', '111', 'Patti', 'Jones', null, 'Patricia', 'patti.jones@melonhrm.example', 'Patti.Jones@sailpointdemo.com', 'Senior Finance Manager', 'US', 'San Jose', 'MEL0001', 'Active Employee', '5', 'HR-1011', '95113', null, null, null, 'patti.jones', 'Regional Operations', 'false', '2016-08-08', null, null, null, null),
    ('MEL0012', '112', 'Rick', 'Jackson', null, 'Richard', 'rick.jackson@melonhrm.example', 'Rick.Jackson@sailpointdemo.com', 'Treasury Analyst', 'US', 'San Jose', 'MEL0011', 'Active Employee', '5', null, null, null, '+1 408 555 0112', '+1 408 555 0212', 'rick.jackson', 'Accounting', 'false', '2018-03-12', null, null, null, null),
    ('MEL0013', '113', 'María', 'White', null, 'Maria', 'maria.white@melonhrm.example', 'Maria.White@sailpointdemo.com', 'Treasury Analyst', 'US', 'San Jose', 'MEL0011', 'Active Employee', '5', null, null, null, null, null, 'maria.white', 'Accounting', 'false', '2019-10-21', null, null, null, null),
    ('MEL0014', '114', 'Charlie', 'Harris', null, 'Charles', 'charlie.harris@melonhrm.example', 'Charlie.Harris@sailpointdemo.com', 'Treasury Researcher', 'US', 'San Jose', 'MEL0011', 'Active Employee', '5', null, '95113', null, '+1 408 555 0114', '+1 408 555 0214', 'charlie.harris', 'Finance', 'false', '2017-09-18', null, null, null, null),
    ('MEL0015', '115', 'Susan', 'Martin', null, null, 'susan.martin@melonhrm.example', 'Susan.Martin@sailpointdemo.com', 'Financial Planning Analyst', 'US', 'San Jose', 'MEL0011', 'Active Employee', '5', null, null, null, null, null, 'susan.martin', 'Finance', 'false', '2020-06-01', null, null, null, null),
    ('MEL0016', '116', 'Susan', 'Martin', null, null, 'susan.martin2@melonhrm.example', 'Susan.Martin@melonmail.example', 'Account Executive', 'DE', 'Munich', 'MEL0021', 'Active Employee', '5', 'HR-1016', null, null, '+49 151 0000 0016', '+49 89 5550 0116', 'susan.martin', 'Sales', 'false', '2023-01-16', null, null, null, null),
    ('MEL0017', '117', 'John', 'Williams', null, null, 'john.williams@melonhrm.example', 'John.Williams@melonmail.example', 'IT Support Specialist', 'DE', 'Munich', 'MEL0002', 'Active Employee', '5', null, '80331', null, null, null, 'john.williams', 'Information Technology', 'false', '2022-05-09', null, null, null, null),
    ('MEL0018', '118', 'Michael', 'Miller', null, null, 'michael.miller@melonhrm.example', 'Michael.Miller@melonmail.example', 'Software Engineer', 'GB', 'London', 'MEL0007', 'Active Employee', '5', null, null, null, '+44 7700 900018', '+44 20 7946 0118', 'michael.miller', 'Engineering', 'false', '2021-11-15', null, null, null, null),
    ('MEL0019', '119', 'Neville', 'Kaufman', null, null, 'neville.kaufman@melonhrm.example', 'Neville.Kaufman@melonmail.example', 'Treasury Analyst', 'GB', 'London', 'MEL0011', 'Active Employee', '5', null, null, null, null, null, 'neville.kaufman', 'Accounting', 'false', '2023-03-27', null, null, null, null),
    ('MEL0020', '120', 'Priya', 'Nair', null, null, 'priya.nair@melonhrm.example', 'Priya.Nair@melonmail.example', 'HR Business Partner', 'GB', 'London', 'MEL0002', 'Active Employee', '5', null, 'EC2A 1AF', null, '+44 7700 900020', '+44 20 7946 0120', 'priya.nair', 'Human Resources', 'false', '2021-04-12', null, null, null, null),
    ('MEL0021', '121', 'Tomás', 'Ferreira', null, null, 'tomas.ferreira@melonhrm.example', 'Tomas.Ferreira@melonmail.example', 'Sales Manager', 'DE', 'Munich', 'MEL0001', 'Active Employee', '5', 'HR-1021', null, null, null, null, 'tomas.ferreira', 'Sales', 'false', '2019-01-14', null, null, null, null),
    ('MEL0022', '122', 'Yuki', 'Tanaka', null, null, 'yuki.tanaka@melonhrm.example', 'Yuki.Tanaka@melonmail.example', 'Software Engineer', null, null, 'MEL0009', 'Active Contractor', '6', null, null, null, '+44 7700 900022', '+44 20 7946 0122', 'yuki.tanaka', 'Engineering', 'false', '2023-10-02', null, '2023-10-02', '2026-10-01', null),
    ('MEL0023', '123', 'Grace', 'Okafor', null, null, 'grace.okafor@melonhrm.example', 'Grace.Okafor@melonmail.example', 'Financial Analyst', 'GB', 'London', 'MEL0014', 'Active Employee', '5', null, 'EC2A 1AF', null, null, null, 'grace.okafor', 'Finance', 'false', '2022-04-04', null, null, null, null),
    ('MEL0024', '124', 'Felix', 'Braun', null, null, 'felix.braun@melonhrm.example', 'Felix.Braun@melonmail.example', 'IT Support Specialist', 'DE', 'Munich', 'MEL0007', 'Active Contractor', '6', null, null, null, '+49 151 0000 0024', '+49 89 5550 0124', 'felix.braun', 'Information Technology', 'false', '2024-01-15', null, '2024-01-15', '2026-01-14', 'Technicians'),
    ('MEL0025', '125', 'Laura', 'Bianchi', null, null, 'laura.bianchi@melonhrm.example', 'Laura.Bianchi@melonmail.example', 'Product Designer', null, null, 'MEL0009', 'Active Employee', '5', null, null, null, null, null, 'laura.bianchi', 'Engineering', 'false', '2022-07-11', null, null, null, null),
    ('MEL0026', '126', 'Omar', 'Haddad', null, null, 'omar.haddad@melonhrm.example', 'Omar.Haddad@melonmail.example', 'Account Executive', 'GB', 'London', 'MEL0021', 'Active Employee', '5', 'HR-1026', 'EC2A 1AF', null, '+44 7700 900026', '+44 20 7946 0126', 'omar.haddad', 'Sales', 'false', '2023-02-20', null, null, null, null),
    ('MEL0027', '127', 'Clara', 'Nowak', null, null, 'clara.nowak@melonhrm.example', 'Clara.Nowak@melonmail.example', 'Talent Acquisition Partner', 'US', 'Austin', 'MEL0020', 'Active Contractor', '6', null, null, null, null, null, 'clara.nowak', 'Human Resources', 'false', '2024-03-11', null, '2024-03-11', '2026-03-10', null),
    ('MEL0028', '128', 'Diego', 'Fernández', null, null, 'diego.fernandez@melonhrm.example', 'Diego.Fernandez@melonmail.example', 'Account Executive', 'DE', 'Munich', 'MEL0021', 'Active Employee', '5', null, null, null, '+49 151 0000 0028', '+49 89 5550 0128', 'diego.fernandez', 'Sales', 'false', '2024-05-20', null, null, null, null),
    ('MEL0029', '129', 'Aisha', 'Rahman', null, null, 'aisha.rahman@melonhrm.example', 'Aisha.Rahman@melonmail.example', 'Data Analyst', 'SG', 'Singapore', 'MEL0012', 'Active Employee', '5', null, '018956', null, null, null, 'aisha.rahman', 'Accounting', 'false', '2023-06-05', null, null, null, null),
    ('MEL0030', '130', 'Leo', 'Martin', null, null, 'leo.martin@melonhrm.example', 'Leo.Martin@melonmail.example', 'IT Support Specialist', 'US', 'Austin', 'MEL0024', 'Inactive Employee', '7', null, null, null, '+1 512 555 0130', '+1 512 555 0230', 'leo.martin', 'Information Technology', 'true', '2022-09-19', '2025-11-28', null, null, 'Craft Workers');

do $$
begin
    if exists (select 1 from pg_roles where rolname = 'service_role') then
        alter table public."MelonHRM" enable row level security;
        revoke all on table public."MelonHRM" from public;
        if exists (select 1 from pg_roles where rolname = 'anon') then
            revoke all on table public."MelonHRM" from anon;
        end if;
        if exists (select 1 from pg_roles where rolname = 'authenticated') then
            revoke all on table public."MelonHRM" from authenticated;
        end if;
        grant select on table public."MelonHRM" to service_role;
    end if;
end $$;

commit;
