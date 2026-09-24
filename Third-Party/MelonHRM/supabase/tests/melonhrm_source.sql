begin;

select plan(14);

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
    array[15::bigint],
    'Feed contains exactly 15 identities'
);

select is_empty(
    $$select employee_id from public."MelonHRM" where employee_id = '0001'$$,
    'Admin employee 0001 is not in the feed'
);

select results_eq(
    $$select employee_id from public."MelonHRM" where manager is null$$,
    array['MEL0001'],
    'Only MEL0001 (Elena Varga) has no manager'
);

select results_eq(
    $$select count(*) from public."MelonHRM" where manager is not null$$,
    array[14::bigint],
    'Every other identity has a manager'
);

select results_eq(
    $$select manager
        from public."MelonHRM"
       where manager is not null
       group by manager
       order by manager$$,
    array['MEL0001', 'MEL0006'],
    'Only MEL0001 and MEL0006 are referenced as managers'
);

select results_eq(
    $$select count(*) from public."MelonHRM"
      where username in (
          'elena.varga', 'hugo.moretti', 'keiko.sato', 'amara.diallo', 'noah.lindberg'
      )$$,
    array[5::bigint],
    'Five MelonHRM-only non-matches'
);

select results_eq(
    $$select count(*) from public."MelonHRM"
      where username in (
          'jerry.bennett', 'aaron.nichols', 'jane.grant', 'carolyn.perry'
      )$$,
    array[4::bigint],
    'Four natural account-name correlations'
);

select results_eq(
    $$select count(*) from public."MelonHRM"
      where username in ('nadia.petrova', 'nadya.petrova')$$,
    array[2::bigint],
    'Two reciprocal deferred-match accounts'
);

select results_eq(
    $$select count(*) from public."MelonHRM"
      where username in ('deb.wood', 'randall.knight')$$,
    array[2::bigint],
    'Two automatic-match accounts'
);

select results_eq(
    $$select count(*) from public."MelonHRM"
      where username in ('patti.jones', 'kate.simmons')$$,
    array[2::bigint],
    'One true-positive and one false-positive manual candidate'
);

select results_eq(
    $$select count(*) from public."MelonHRM"
      where country is not null
        and country !~ '^[A-Z]{2}$'$$,
    array[15::bigint],
    'Every identity uses a full country name, not an ISO code'
);

select results_eq(
    $$select count(*) from public."MelonHRM" t
      where (t.username, t.title) in (
          ('jerry.bennett', 'Chief Executive'),
          ('aaron.nichols', 'Head of Operations'),
          ('jane.grant', 'Access Certification Reviewer'),
          ('carolyn.perry', 'Release Staging Lead'),
          ('deb.wood', 'Inventory Analyst'),
          ('randall.knight', 'Director of Operations'),
          ('patti.jones', 'Finance Manager')
      )
      and t.title not in (
          'Senior Executive',
          'Operations Manager',
          'SOX Access Reviewer',
          'Staging Manager',
          'Inventory Analyst I',
          'Operations Director',
          'Senior Finance Manager'
      )$$,
    array[7::bigint],
    'Positive-match titles differ from OrangeHRM candidates but use the planned Melon values'
);

select * from finish();

rollback;
