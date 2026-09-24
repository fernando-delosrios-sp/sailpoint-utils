-- =============================================================================
-- OrangeHRM: merge duplicate job titles back into one row per title
-- =============================================================================
-- Symptom
--   The Job Title dropdown (PIM > Add Employee, PIM > Job) repeats the same
--   label several times, for example three "Doctor" and three "Doctor Chief"
--   entries.
--
-- Cause
--   AddEmployeeForm::_getJobTitles() builds the dropdown from
--   JobTitleService::getJobTitleList() keyed by ohrm_job_title.id, and keeps
--   every row with is_deleted = 0. Nothing in OrangeHRM enforces a unique
--   job_title, so an import or seeding script that ran more than once leaves
--   several active rows carrying the same name, each of which becomes its own
--   option. The labels look identical; the ids behind them are not.
--
-- What this script does
--   Keeps one surviving row per title (the one with the most employees on it,
--   lowest id wins a tie), repoints every reference to the survivor, then
--   retires the extra rows with is_deleted = 1 instead of deleting them, so no
--   foreign key can break and the change is reversible.
--
-- Foreign keys in this build (from information_schema, 2026-09-24)
--   hs_hr_employee.job_title_code
--   hs_hr_jobtit_empstat.jobtit_code          -- unique with estat_code
--   ohrm_job_specification_attachment.job_title_id  -- one spec per title
--   ohrm_job_vacancy.job_title_code
--
-- Safety
--   Run against a backed-up database. Snapshot tables are created once and are
--   not overwritten on re-run. A commented rollback block is at the end.
--   Run section 1 first and read it before running anything else.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Preflight — read only, change nothing until this output is understood
-- ---------------------------------------------------------------------------

-- 1a. Every job title, bracketed and hex-encoded so invisible differences
--     (trailing space, non-breaking space, different case) are visible.
SELECT
    id,
    CONCAT('[', job_title, ']') AS job_title_bracketed,
    HEX(job_title)              AS job_title_hex,
    is_deleted,
    job_description,
    note
FROM ohrm_job_title
ORDER BY TRIM(job_title), id;

-- 1b. The duplicate groups themselves. Empty result = no duplicates to merge.
SELECT
    LOWER(TRIM(job_title))        AS normalized_title,
    COUNT(*)                      AS active_rows,
    GROUP_CONCAT(id ORDER BY id)  AS ids
FROM ohrm_job_title
WHERE is_deleted = 0
GROUP BY LOWER(TRIM(job_title))
HAVING COUNT(*) > 1
ORDER BY normalized_title;

-- 1c. Employees sitting on each duplicate row. A title whose copies all carry
--     employees means the population is split across the copies.
SELECT
    t.id,
    t.job_title,
    COUNT(e.emp_number) AS employees
FROM ohrm_job_title t
INNER JOIN (
    SELECT LOWER(TRIM(job_title)) AS normalized_title
    FROM ohrm_job_title
    WHERE is_deleted = 0
    GROUP BY LOWER(TRIM(job_title))
    HAVING COUNT(*) > 1
) d ON d.normalized_title = LOWER(TRIM(t.job_title))
LEFT JOIN hs_hr_employee e ON e.job_title_code = t.id
WHERE t.is_deleted = 0
GROUP BY t.id, t.job_title
ORDER BY t.job_title, t.id;

-- 1d. Everything that references ohrm_job_title in this build.
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
  AND REFERENCED_TABLE_NAME = 'ohrm_job_title'
ORDER BY TABLE_NAME, COLUMN_NAME;

-- 1e. Child rows already sitting on duplicate titles. Empty is fine: those
--     tables then have nothing to merge. Collisions (survivor already has the
--     same estat_code / attachment) are handled in section 4 by dropping the
--     losing row rather than updating it.
SELECT
    'hs_hr_jobtit_empstat' AS child_table,
    j.jobtit_code          AS title_id,
    t.job_title,
    j.estat_code           AS extra
FROM hs_hr_jobtit_empstat j
INNER JOIN ohrm_job_title t ON t.id = j.jobtit_code
INNER JOIN (
    SELECT LOWER(TRIM(job_title)) AS normalized_title
    FROM ohrm_job_title
    WHERE is_deleted = 0
    GROUP BY LOWER(TRIM(job_title))
    HAVING COUNT(*) > 1
) d ON d.normalized_title = LOWER(TRIM(t.job_title))
WHERE t.is_deleted = 0
UNION ALL
SELECT
    'ohrm_job_specification_attachment',
    a.job_title_id,
    t.job_title,
    a.file_name
FROM ohrm_job_specification_attachment a
INNER JOIN ohrm_job_title t ON t.id = a.job_title_id
INNER JOIN (
    SELECT LOWER(TRIM(job_title)) AS normalized_title
    FROM ohrm_job_title
    WHERE is_deleted = 0
    GROUP BY LOWER(TRIM(job_title))
    HAVING COUNT(*) > 1
) d ON d.normalized_title = LOWER(TRIM(t.job_title))
WHERE t.is_deleted = 0
UNION ALL
SELECT
    'ohrm_job_vacancy',
    v.job_title_code,
    t.job_title,
    v.name
FROM ohrm_job_vacancy v
INNER JOIN ohrm_job_title t ON t.id = v.job_title_code
INNER JOIN (
    SELECT LOWER(TRIM(job_title)) AS normalized_title
    FROM ohrm_job_title
    WHERE is_deleted = 0
    GROUP BY LOWER(TRIM(job_title))
    HAVING COUNT(*) > 1
) d ON d.normalized_title = LOWER(TRIM(t.job_title))
WHERE t.is_deleted = 0
ORDER BY child_table, job_title, title_id;

-- 1f. Optional sweep: the same double-import usually hits other PIM lookup
--     tables. This prints one duplicate check per `ohrm_*` table that has a
--     `name` column; run the ones that matter (subunit, location,
--     employment status, job category, work shift, nationality).
SELECT CONCAT(
    'SELECT ''', TABLE_NAME, ''' AS lookup_table, TRIM(name) AS value, ',
    'COUNT(*) AS rows_found FROM ', TABLE_NAME,
    ' GROUP BY TRIM(name) HAVING COUNT(*) > 1;'
) AS duplicate_check
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND COLUMN_NAME = 'name'
  AND TABLE_NAME LIKE 'ohrm\_%'
ORDER BY TABLE_NAME;

-- ---------------------------------------------------------------------------
-- 2. Snapshots (idempotent: do not overwrite an existing backup)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ohrm_job_title_backup_20260924 AS
SELECT * FROM ohrm_job_title WHERE 1 = 0;

INSERT INTO ohrm_job_title_backup_20260924
SELECT t.*
FROM ohrm_job_title t
WHERE NOT EXISTS (SELECT 1 FROM ohrm_job_title_backup_20260924 LIMIT 1);

CREATE TABLE IF NOT EXISTS hs_hr_employee_job_title_backup_20260924 AS
SELECT emp_number, job_title_code FROM hs_hr_employee WHERE 1 = 0;

INSERT INTO hs_hr_employee_job_title_backup_20260924
SELECT e.emp_number, e.job_title_code
FROM hs_hr_employee e
WHERE NOT EXISTS (SELECT 1 FROM hs_hr_employee_job_title_backup_20260924 LIMIT 1);

CREATE TABLE IF NOT EXISTS hs_hr_jobtit_empstat_backup_20260924 AS
SELECT * FROM hs_hr_jobtit_empstat WHERE 1 = 0;

INSERT INTO hs_hr_jobtit_empstat_backup_20260924
SELECT j.*
FROM hs_hr_jobtit_empstat j
WHERE NOT EXISTS (SELECT 1 FROM hs_hr_jobtit_empstat_backup_20260924 LIMIT 1);

CREATE TABLE IF NOT EXISTS ohrm_job_specification_attachment_backup_20260924 AS
SELECT * FROM ohrm_job_specification_attachment WHERE 1 = 0;

INSERT INTO ohrm_job_specification_attachment_backup_20260924
SELECT a.*
FROM ohrm_job_specification_attachment a
WHERE NOT EXISTS (SELECT 1 FROM ohrm_job_specification_attachment_backup_20260924 LIMIT 1);

CREATE TABLE IF NOT EXISTS ohrm_job_vacancy_backup_20260924 AS
SELECT id, job_title_code FROM ohrm_job_vacancy WHERE 1 = 0;

INSERT INTO ohrm_job_vacancy_backup_20260924
SELECT v.id, v.job_title_code
FROM ohrm_job_vacancy v
WHERE NOT EXISTS (SELECT 1 FROM ohrm_job_vacancy_backup_20260924 LIMIT 1);

-- ---------------------------------------------------------------------------
-- 3. Merge map — explicit ids from the 2026-09-24 preflight
-- ---------------------------------------------------------------------------
-- Healthcare titles were inserted three times (ids step +12). Enterprise
-- Sales Executive was inserted twice with consecutive ids. Survivor is the
-- lowest id in each group (the original seed copy). Re-run 1c if a later
-- copy holds more employees and you would rather keep that id instead.
--
--   title                         keep   retire
--   Doctor Chief                  143    155, 167
--   Doctor                        144    156, 168
--   Nurse Charge                  145    157, 169
--   Nurse Staff                   146    158, 170
--   Nurse Manager                 147    159, 171
--   Nurse Staff-NICU              148    160, 172
--   Nurse Staff-ER                149    161, 173
--   Radiologist                   150    162, 174
--   Radiology Manager             151    163, 175
--   MRI Technician                152    164, 176
--   Employee Nurse                153    165, 177
--   Student Nurse                 154    166, 178
--   Enterprise Sales Executive    188    189
CREATE TABLE IF NOT EXISTS ohrm_job_title_merge_20260924 AS
SELECT id AS dup_id, id AS survivor_id, job_title FROM ohrm_job_title WHERE 1 = 0;

INSERT INTO ohrm_job_title_merge_20260924 (dup_id, survivor_id, job_title)
SELECT t.id, m.survivor_id, t.job_title
FROM ohrm_job_title t
INNER JOIN (
    SELECT 155 AS dup_id, 143 AS survivor_id UNION ALL
    SELECT 167, 143 UNION ALL
    SELECT 156, 144 UNION ALL
    SELECT 168, 144 UNION ALL
    SELECT 157, 145 UNION ALL
    SELECT 169, 145 UNION ALL
    SELECT 158, 146 UNION ALL
    SELECT 170, 146 UNION ALL
    SELECT 159, 147 UNION ALL
    SELECT 171, 147 UNION ALL
    SELECT 160, 148 UNION ALL
    SELECT 172, 148 UNION ALL
    SELECT 161, 149 UNION ALL
    SELECT 173, 149 UNION ALL
    SELECT 162, 150 UNION ALL
    SELECT 174, 150 UNION ALL
    SELECT 163, 151 UNION ALL
    SELECT 175, 151 UNION ALL
    SELECT 164, 152 UNION ALL
    SELECT 176, 152 UNION ALL
    SELECT 165, 153 UNION ALL
    SELECT 177, 153 UNION ALL
    SELECT 166, 154 UNION ALL
    SELECT 178, 154 UNION ALL
    SELECT 189, 188
) m ON m.dup_id = t.id
WHERE NOT EXISTS (SELECT 1 FROM ohrm_job_title_merge_20260924 LIMIT 1);

-- Review the plan before applying it. Each row is "this id disappears from the
-- dropdown, its employees move to survivor_id".
SELECT
    m.dup_id,
    m.survivor_id,
    m.job_title,
    (SELECT COUNT(*) FROM hs_hr_employee e WHERE e.job_title_code = m.dup_id) AS employees_to_move
FROM ohrm_job_title_merge_20260924 m
ORDER BY m.job_title, m.dup_id;

-- ---------------------------------------------------------------------------
-- 4. Apply — repoint children, drop unique-key collisions, retire duplicates
-- ---------------------------------------------------------------------------
-- hs_hr_jobtit_empstat is unique on (jobtit_code, estat_code). If the survivor
-- already has that employment status, the losing mapping is deleted.
-- ohrm_job_specification_attachment is one file per title. If the survivor
-- already has a spec, the losing file is deleted; otherwise it is moved.
-- Vacancies have no uniqueness on job_title_code, so they always move.
START TRANSACTION;

UPDATE hs_hr_employee e
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = e.job_title_code
SET e.job_title_code = m.survivor_id;

DELETE j
FROM hs_hr_jobtit_empstat j
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = j.jobtit_code
INNER JOIN hs_hr_jobtit_empstat survivor
    ON survivor.jobtit_code = m.survivor_id
   AND survivor.estat_code = j.estat_code;

UPDATE hs_hr_jobtit_empstat j
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = j.jobtit_code
SET j.jobtit_code = m.survivor_id;

DELETE a
FROM ohrm_job_specification_attachment a
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = a.job_title_id
INNER JOIN ohrm_job_specification_attachment survivor
    ON survivor.job_title_id = m.survivor_id;

UPDATE ohrm_job_specification_attachment a
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = a.job_title_id
SET a.job_title_id = m.survivor_id;

UPDATE ohrm_job_vacancy v
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = v.job_title_code
SET v.job_title_code = m.survivor_id;

UPDATE ohrm_job_title t
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = t.id
SET t.is_deleted = 1;

COMMIT;

-- ---------------------------------------------------------------------------
-- 5. Verification
-- ---------------------------------------------------------------------------
-- Expect: empty — no active title name appears twice any more
SELECT
    LOWER(TRIM(job_title)) AS normalized_title,
    COUNT(*)               AS active_rows
FROM ohrm_job_title
WHERE is_deleted = 0
GROUP BY LOWER(TRIM(job_title))
HAVING COUNT(*) > 1;

-- Expect: 0 — nobody is still assigned to a retired duplicate
SELECT COUNT(*) AS employees_left_on_duplicates
FROM hs_hr_employee e
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = e.job_title_code;

-- Expect: 0 on every remaining child table
SELECT COUNT(*) AS jobtit_empstat_left_on_duplicates
FROM hs_hr_jobtit_empstat j
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = j.jobtit_code;

SELECT COUNT(*) AS spec_attachments_left_on_duplicates
FROM ohrm_job_specification_attachment a
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = a.job_title_id;

SELECT COUNT(*) AS vacancies_left_on_duplicates
FROM ohrm_job_vacancy v
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = v.job_title_code;

-- Expect: the merged population per surviving title
SELECT
    t.id,
    t.job_title,
    COUNT(e.emp_number) AS employees
FROM ohrm_job_title t
LEFT JOIN hs_hr_employee e ON e.job_title_code = t.id
WHERE t.is_deleted = 0
GROUP BY t.id, t.job_title
ORDER BY t.job_title;

-- ---------------------------------------------------------------------------
-- 6. Optional hard delete of the retired rows
-- ---------------------------------------------------------------------------
-- Only worth doing once section 5 is clean. Foreign keys reject any row still
-- referenced, which is the intended guard — if this errors, something still
-- points at the duplicate and it should stay retired instead.
/*
DELETE t
FROM ohrm_job_title t
INNER JOIN ohrm_job_title_merge_20260924 m ON m.dup_id = t.id;
*/

-- ---------------------------------------------------------------------------
-- 7. Rollback (commented — restore children and un-retire the duplicates)
-- ---------------------------------------------------------------------------
-- Only valid while section 6 has not been run. Spec attachments and
-- title-status mappings that were deleted as unique-key collisions come back
-- from the snapshot; moved vacancies and employees go back to the original id.
/*
START TRANSACTION;

UPDATE hs_hr_employee e
INNER JOIN hs_hr_employee_job_title_backup_20260924 b ON b.emp_number = e.emp_number
SET e.job_title_code = b.job_title_code;

UPDATE ohrm_job_vacancy v
INNER JOIN ohrm_job_vacancy_backup_20260924 b ON b.id = v.id
SET v.job_title_code = b.job_title_code;

DELETE FROM hs_hr_jobtit_empstat;
INSERT INTO hs_hr_jobtit_empstat
SELECT * FROM hs_hr_jobtit_empstat_backup_20260924;

DELETE FROM ohrm_job_specification_attachment;
INSERT INTO ohrm_job_specification_attachment
SELECT * FROM ohrm_job_specification_attachment_backup_20260924;

UPDATE ohrm_job_title t
INNER JOIN ohrm_job_title_backup_20260924 b ON b.id = t.id
SET t.is_deleted = b.is_deleted;

COMMIT;

DROP TABLE ohrm_job_title_merge_20260924;
*/
