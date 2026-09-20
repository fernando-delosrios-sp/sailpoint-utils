-- Rename firstname / lastname to "givenName" / "familyName" on databases that were
-- seeded before the rename. Local resets recreate the table from ../melonhrm.sql with
-- the new names, and migrations run before the seed, so this is a no-op there.

do $$
begin
    if to_regclass('public."MelonHRM"') is null then
        return;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public'
          and table_name = 'MelonHRM'
          and column_name = 'firstname'
    ) then
        alter table public."MelonHRM" rename column firstname to "givenName";
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public'
          and table_name = 'MelonHRM'
          and column_name = 'lastname'
    ) then
        alter table public."MelonHRM" rename column lastname to "familyName";
    end if;
end $$;
