-- ============================================================================
-- Supporting metric: patient show-rate by appointment type.
--
-- Effectiveness metrics above only look at completed (show_code = 'Y') visits.
-- This query looks at the full scheduled population to see how often patients
-- actually show up for each appointment type -- a proxy for patient
-- commitment/accountability that helps explain the effectiveness gap.
-- ============================================================================

select
    appointment_type,
    count(*) as scheduled,
    sum(case when show_code = 'y' then 1 else 0 end) as completed,
    round(sum(case when show_code = 'y' then 1 else 0 end) * 100.0 / count(*), 2)
        as show_rate_pct
from raw_appointments
group by appointment_type;
-- Result: Telephone Visit 81.71% (10,801 / 13,219) | In-Person Visit 90.33% (101,019 / 111,834)
