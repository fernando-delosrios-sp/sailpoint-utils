begin;

select plan(9);

select has_table('public', 'MelonHRM', 'Account table exists');

select columns_are(
    'public'::name,
    'MelonHRM'::name,
    array[
        'employee_id', 'employeenumber', 'givenName', 'familyName', 'middlename',
        'nickname', 'email', 'other_email', 'title', 'country', 'city', 'manager',
        'type', 'empstatus', 'otherid', 'zipcode', 'home_phone', 'mobile',
        'telephone', 'username', 'department', 'term', 'ftostart', 'ftoend',
        'contractStartDate', 'contractEndDate', 'category'
    ],
    'Table matches the HR account schema attributes'
);

select results_eq(
    'select count(*) from public."MelonHRM"',
    array[30::bigint],
    'Feed contains exactly 30 identities'
);

select is_empty(
    $$select employee_id from public."MelonHRM" where employee_id = '0001'$$,
    'Admin employee 0001 is not in the feed'
);

select results_eq(
    $$select employee_id from public."MelonHRM" where manager is null$$,
    array['MEL0001'],
    'Only MEL0001 has no manager'
);

select results_eq(
    $$select count(*) from public."MelonHRM" where manager is not null$$,
    array[29::bigint],
    'Every other identity has a manager'
);

select results_eq(
    $$select username from public."MelonHRM" where employee_id = 'MEL0013'$$,
    array['maria.white'],
    'Accented names store an ASCII username'
);

select results_eq(
    $$select count(*) from public."MelonHRM" where term = 'true'$$,
    array[1::bigint],
    'Exactly one identity is terminated, and term is the string true'
);

select results_eq(
    $$select count(*) from public."MelonHRM" where city is null and country is null$$,
    array[2::bigint],
    'Two identities have no location'
);

select * from finish();

rollback;
