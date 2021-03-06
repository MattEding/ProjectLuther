SELECT DISTINCT test_type
FROM Sbac;
-- only test_type is 'B'

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

SELECT 
    grade
    , COUNT(*)
    , AVG(total_tested_at_entity_level)
    , AVG(total_tested_with_scores)
    , AVG(caaspp_reported_enrollment)
    , AVG(students_tested)
    , AVG(mean_scale_score)
FROM Sbac
GROUP BY grade;

-- As ML models need non-null values, I'll use only grade = 13 (all grades)
-- since no school does every grade. Thus I will not use mean_scale_score
-- because it only has values for specific grades


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

WITH AllStudents AS
(
    SELECT 
        cds_id
        , caaspp_reported_enrollment AS total
    FROM 
    (
        SELECT *
        FROM Sbac
        WHERE grade = 13 AND school_code != 0
        AND caaspp_reported_enrollment IS NOT NULL
    )
    JOIN Subgroup USING (subgroup_id)
    JOIN Cds USING (county_code, district_code, school_code)
    GROUP BY cds_id
    HAVING 
        subgroup = 'All Students'
)
, AllGrades AS 
(
    SELECT *
    FROM Sbac
    JOIN Cds USING (county_code, district_code, school_code)
    WHERE grade = 13 AND school_code != 0
)

SELECT 
    cds_id
    , subgroup_id
    , CAST(caaspp_reported_enrollment AS REAL) / total AS ethnicity_pct
FROM AllGrades
JOIN AllStudents USING (cds_id)
JOIN Subgroup USING (subgroup_id)
GROUP BY cds_id, subgroup_id
HAVING 
    description = 'Ethnicity'
    AND caaspp_reported_enrollment IS NOT NULL
-- note: subgroup percents don't total to 100%;
--       see next query for example why

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

SELECT 
    cds_id
    , grade
    , avg(caaspp_reported_enrollment) AS test_avg_enrollment
    , subgroup
FROM sbac 
JOIN cds USING (county_code, district_code, school_code) 
JOIN subgroup USING (subgroup_id)
GROUP BY cds_id, grade, subgroup_id
HAVING
    description in ('Ethnicity', 'All Students')
    AND caaspp_reported_enrollment IS NOT NULL
    AND cds_id = 120
ORDER BY grade, subgroup_id;
-- note: subgroup by enthnicty totals don't sum to all student 
--       total probably due to groups of 10 students or less 
--       omitted to preserve confidentiality