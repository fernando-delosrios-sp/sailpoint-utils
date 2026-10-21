-- =============================================================================
-- OrangeHRM: Organizational Reporting Structure Redesign (Final Clean Alignment)
-- Environment: resource.company24509-poc.demohub.sailpointtechnologies.com
-- Database: orangehrm_mysql
-- =============================================================================
-- Rules:
--   1. Jerry Bennett at the root with 1 Secretary + 5 Unit Top Managers
--   2. High-level Unit Managers have ONLY 1 Secretary + Department Managers
--   3. Department Managers have direct employees and sub-managers (5-10 span)
-- =============================================================================

START TRANSACTION;

-- Backup table
CREATE TABLE IF NOT EXISTS hs_hr_emp_reportto_backup_20261021 AS
SELECT * FROM hs_hr_emp_reportto WHERE 1 = 0;

INSERT INTO hs_hr_emp_reportto_backup_20261021
SELECT r.*
FROM hs_hr_emp_reportto r
WHERE NOT EXISTS (SELECT 1 FROM hs_hr_emp_reportto_backup_20261021 LIMIT 1);

-- Remove previous/conflicting supervisor links for all repointed staff
DELETE FROM hs_hr_emp_reportto
WHERE (erep_sup_emp_number = 57 AND erep_sub_emp_number IN (68, 69, 5, 4))   -- Henry Butler, Catherine Simmons, Patricia Jones, John Williams from Amanda Ross
   OR (erep_sup_emp_number = 55 AND erep_sub_emp_number IN (107, 58, 2, 8, 61, 60)) -- Jane Grant, Walter Henderson, Mary Johnson, Patrick Jenkins, Carolyn Perry from Debra Wood
   OR (erep_sup_emp_number = 900 AND erep_sub_emp_number IN (913, 908))      -- Nadine Cochran, Bruno Leblanc from Neville Kaufman
   OR (erep_sub_emp_number IN (215, 216, 217, 214, 402, 56, 112, 117, 4));

-- Insert aligned reporting structure (1 = Direct reporting)
INSERT INTO hs_hr_emp_reportto (erep_sup_emp_number, erep_sub_emp_number, erep_reporting_mode) VALUES
    -- Secretaries to High-Level Unit Managers
    (57,  215, 1), -- Diana Lawrence -> Amanda Ross (Corporate Services)
    (55,  216, 1), -- Lillian Austin -> Debra Wood (Technology)
    (106, 217, 1), -- Jimmy Peters -> Aaron Nichols (Operations)
    (900, 214, 1), -- Chris Greene -> Neville Kaufman (Commercial)
    (400, 402, 1), -- Danni Sullivan -> Bob Kelso (Healthcare)

    -- Department Managers to Corporate Services Unit Top Manager (Amanda Ross)
    (57,  109, 1), -- Lori Ferguson (Finance Dept Manager) -> Amanda Ross
    (57,  67,  1), -- Janet Washington (Accounting Dept Manager) -> Amanda Ross
    (57,  56,  1), -- Dennis Barnes (HR Dept Manager) -> Amanda Ross

    -- Sub-managers to Corporate Services Department Managers
    (109, 68,  1), -- Henry Butler -> Lori Ferguson (Finance)
    (109, 69,  1), -- Catherine Simmons -> Lori Ferguson (Finance)
    (109, 5,   1), -- Patricia Jones -> Lori Ferguson (Finance)
    (67,  66,  1), -- Douglas Flores -> Janet Washington (Accounting)
    (56,  4,   1), -- John Williams -> Dennis Barnes (HR)

    -- Department Managers to Technology Unit Top Manager (Debra Wood)
    (55,  112, 1), -- Eugene Hawkins (Engineering Dept Manager) -> Debra Wood
    (55,  59,  1), -- Stephanie Coleman (IT Dept Manager) -> Debra Wood

    -- Sub-managers to Technology Department Managers
    (112, 8,   1), -- Patrick Jenkins -> Eugene Hawkins (Engineering)
    (112, 61,  1), -- Carolyn Perry -> Eugene Hawkins (Engineering)
    (59,  107, 1), -- Jane Grant -> Stephanie Coleman (IT)
    (59,  58,  1), -- Walter Henderson -> Stephanie Coleman (IT)
    (59,  2,   1), -- Mary Johnson -> Stephanie Coleman (IT)
    (59,  110, 1), -- Howard Rose -> Stephanie Coleman (IT)
    (59,  6,   1), -- Robert Brown -> Stephanie Coleman (IT)
    (59,  7,   1), -- Linda Davis -> Stephanie Coleman (IT)
    (59,  111, 1), -- Rachel Stone -> Stephanie Coleman (IT)

    -- Department Managers to Operations Unit Top Manager (Aaron Nichols)
    (106, 108, 1), -- Randy Knight (Regional Ops Dept Manager) -> Aaron Nichols
    (106, 117, 1), -- Kathryn Gardner (Inventory Dept Manager) -> Aaron Nichols
    (106, 700, 1), -- Isabelle Lynch (Asset Mgmt Dept Manager) -> Aaron Nichols

    -- Department Managers to Commercial Unit Top Manager (Neville Kaufman)
    (900, 901, 1), -- Clinton Rush (Sales Dept Manager) -> Neville Kaufman
    (900, 800, 1), -- Martena Heath (Call Center Dept Manager) -> Neville Kaufman

    -- Sub-managers to Commercial Department Managers
    (901, 913, 1), -- Nadine Cochran -> Clinton Rush (Sales)
    (901, 908, 1), -- Bruno Leblanc -> Clinton Rush (Sales)

    -- Department Managers to Healthcare Unit Top Manager (Bob Kelso)
    (400, 414, 1), -- Perry Cox (Doctors Dept Manager) -> Bob Kelso
    (400, 401, 1); -- Jordan Sullivan (Nursing Dept Manager) -> Bob Kelso

COMMIT;
