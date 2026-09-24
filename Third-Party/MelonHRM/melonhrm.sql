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

-- Lock down before DML. ALTER TABLE after INSERT fails in one transaction
-- ("pending trigger events") on hosted Supabase.
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

-- 15-account Fusion demo population.
-- Managers: MEL0001 (Elena Varga, MelonHRM-only root) and MEL0006 (Jerry Bennett, natural correlation).
-- Positive-match titles differ from OrangeHRM candidates but stay semantically similar.
insert into public."MelonHRM" (
    employee_id, employeenumber, "givenName", "familyName", middlename, nickname,
    email, other_email, title, country, city, manager, type, empstatus,
    otherid, zipcode, home_phone, mobile, telephone, username, department,
    term, ftostart, ftoend, "contractStartDate", "contractEndDate", category
) values
    -- 5 new non-matches
    ('MEL0001', '101', 'Elena', 'Varga', null, null, 'elena.varga@melonhrm.example', 'Elena.Varga@melonmail.example', 'People Operations Director', 'Belgium', 'Brussels', null, 'Active Employee', '5', 'HR-1001', null, null, '+32 470 00 00 01', '+32 2 555 0101', 'elena.varga', 'Human Resources', 'false', '2014-05-12', null, null, null, null),
    ('MEL0002', '102', 'Hugo', 'Moretti', null, null, 'hugo.moretti@melonhrm.example', 'Hugo.Moretti@melonmail.example', 'Compensation Analyst', 'Belgium', 'Brussels', 'MEL0001', 'Active Employee', '5', null, '1000', null, '+32 470 00 00 02', '+32 2 555 0102', 'hugo.moretti', 'Human Resources', 'false', '2021-03-08', null, null, null, null),
    ('MEL0003', '103', 'Keiko', 'Sato', null, null, 'keiko.sato@melonhrm.example', 'Keiko.Sato@melonmail.example', 'Learning Specialist', 'Japan', 'Tokyo', 'MEL0001', 'Active Employee', '5', null, null, null, '+81 90 0000 0003', '+81 3 5550 0103', 'keiko.sato', 'Human Resources', 'false', '2022-08-22', null, null, null, null),
    ('MEL0004', '104', 'Amara', 'Diallo', null, null, 'amara.diallo@melonhrm.example', 'Amara.Diallo@melonmail.example', 'Employee Relations Partner', 'United States', 'Austin', 'MEL0001', 'Active Employee', '5', null, '78701', null, null, null, 'amara.diallo', 'Human Resources', 'false', '2023-01-16', null, null, null, null),
    ('MEL0005', '105', 'Noah', 'Lindberg', null, null, 'noah.lindberg@melonhrm.example', 'Noah.Lindberg@melonmail.example', 'HRIS Analyst', 'Singapore', 'Singapore', 'MEL0001', 'Active Contractor', '6', null, '018956', null, '+65 8000 0005', '+65 6555 0105', 'noah.lindberg', 'Human Resources', 'false', '2024-02-01', null, '2024-02-01', '2026-01-31', null),
    -- 4 natural account-name correlations (titles vary from OrangeHRM)
    ('MEL0006', '106', 'Jerry', 'Bennett', null, null, 'jerry.bennett@melonhrm.example', 'Jerry.Bennett@sailpointdemo.com', 'Chief Executive', 'Belgium', 'Brussels', 'MEL0001', 'Active Employee', '5', 'HR-1006', null, null, null, null, 'jerry.bennett', 'Executive Management', 'false', '2015-03-02', null, null, null, null),
    ('MEL0007', '107', 'Aaron', 'Nichols', null, null, 'aaron.nichols@melonhrm.example', 'Aaron.Nichols@sailpointdemo.com', 'Head of Operations', 'Singapore', 'Singapore', 'MEL0006', 'Active Employee', '5', null, '018956', null, '+65 8000 0007', '+65 6555 0107', 'aaron.nichols', 'Executive Management', 'false', '2016-06-13', null, null, null, null),
    ('MEL0008', '108', 'Jane', 'Grant', null, null, 'jane.grant@melonhrm.example', 'Jane.Grant@sailpointdemo.com', 'Access Certification Reviewer', 'Singapore', 'Singapore', 'MEL0006', 'Active Employee', '5', null, null, null, null, null, 'jane.grant', 'Regional Operations', 'false', '2018-09-03', null, null, null, null),
    ('MEL0009', '109', 'Carolyn', 'Perry', null, null, 'carolyn.perry@melonhrm.example', 'Carolyn.Perry@sailpointdemo.com', 'Release Staging Lead', 'Belgium', 'Brussels', 'MEL0006', 'Active Employee', '5', null, null, null, '+32 470 00 00 09', '+32 2 555 0109', 'carolyn.perry', 'Engineering', 'false', '2020-02-17', null, null, null, null),
    -- 2 reciprocal deferred matches (non-matching to baseline; match each other)
    ('MEL0010', '110', 'Nadia', 'Petrova', null, null, 'nadia.petrova@melonhrm.example', 'Nadia.Petrova@melonmail.example', 'Workforce Analytics Lead', 'Germany', 'Munich', 'MEL0001', 'Active Employee', '5', 'HR-1010', null, null, '+49 151 0000 0010', '+49 89 5550 0110', 'nadia.petrova', 'Human Resources', 'false', '2023-04-10', null, null, null, null),
    ('MEL0011', '111', 'Nadya', 'Petrova', null, null, 'nadya.petrova@melonhrm.example', 'Nadya.Petrova@melonmail.example', 'Workforce Analytics Lead', 'Germany', 'Munich', 'MEL0001', 'Active Employee', '5', 'HR-1011', null, null, '+49 151 0000 0011', '+49 89 5550 0111', 'nadya.petrova', 'Human Resources', 'false', '2023-04-10', null, null, null, null),
    -- 2 automatic matches (titles vary from OrangeHRM)
    ('MEL0012', '112', 'Deb', 'Wood', null, 'Debra', 'deb.wood@melonhrm.example', 'Deb.Wood@sailpointdemo.com', 'Inventory Analyst', 'Belgium', 'Brussels', 'MEL0006', 'Active Employee', '5', 'HR-1012', null, null, '+32 470 00 00 12', '+32 2 555 0112', 'deb.wood', 'Regional Operations', 'false', '2016-11-07', null, null, null, null),
    ('MEL0013', '113', 'Randall', 'Knight', null, 'Randy', 'randall.knight@melonhrm.example', 'Randall.Knight@sailpointdemo.com', 'Director of Operations', 'Japan', 'Tokyo', 'MEL0006', 'Active Employee', '5', null, null, null, '+81 90 0000 0013', '+81 3 5550 0113', 'randall.knight', 'Regional Operations', 'false', '2017-02-20', null, null, null, null),
    -- 1 true-positive manual match (title varies from OrangeHRM)
    ('MEL0014', '114', 'Patti', 'Jones', null, 'Patricia', 'patti.jones@melonhrm.example', 'Patti.Jones@sailpointdemo.com', 'Finance Manager', 'United States', 'San Jose', 'MEL0006', 'Active Employee', '5', 'HR-1014', '95113', null, null, null, 'patti.jones', 'Regional Operations', 'false', '2016-08-08', null, null, null, null),
    -- 1 false-positive manual match: new Melon-only Kate Simmons vs OrangeHRM Catherine Simmons.
    -- Johnny/Jon Williams auto-merged into John Williams (>=95); Kate/Catherine should land in review.
    ('MEL0015', '115', 'Kate', 'Simmons', null, null, 'kate.simmons@melonhrm.example', 'Kate.Simmons@melonmail.example', 'Network Technician', 'United Kingdom', 'Manchester', 'MEL0001', 'Active Employee', '5', null, 'M1 1AE', null, '+44 7700 900115', '+44 161 555 0115', 'kate.simmons', 'Information Technology', 'false', '2023-08-14', null, null, null, null);

commit;
