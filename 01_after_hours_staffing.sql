-- ============================================================================
-- Q1: How many physicians are needed to staff the after-hours telephone
--     clinic (appointments after 5:30pm)?
--
-- Assumption: 1 physician can handle 4 telephone visits per hour.
-- Approach: build a view of all completed evening visits, then aggregate
--           average visits per hour to size physician coverage hour-by-hour
--           rather than relying on a single daily average.
-- ============================================================================

create view evening_visits_view as
with temp as (
    select
        facility,
        department,
        provider_id,
        appointment_date,
        cast(appointment_time as varchar) as appointment_time,
        patient_id,
        appointment_type,
        show_code
    from raw_appointments
    where show_code = 'Y'
)
select
    p1.facility,
    p1.department,
    p1.provider_id,
    p1.appointment_date,
    p1.appointment_time,
    p1.patient_id,
    p1.appointment_type,
    max(case
        when p2.appointment_date > p1.appointment_date
         and date_diff('day', p1.appointment_date, p2.appointment_date) <= 7 then 1
        else 0
    end) as had_7day_followup
from temp p1
left join temp p2
    on p1.patient_id = p2.patient_id
where p1.appointment_time >= '17:30:00'
group by 1, 2, 3, 4, 5, 6, 7;

-- Hourly staffing model: average visits/hour -> minimum physicians required
select
    substring(appointment_time, 1, 2) as appt_hour,
    count(patient_id) as total_historical_visits,
    count(distinct appointment_date) as total_days_operated,
    round(count(patient_id) / cast(count(distinct appointment_date) as double), 2)
        as avg_visits_at_this_hour,
    ceiling(
        (count(patient_id) / cast(count(distinct appointment_date) as double)) / 4.0
    ) as minimum_physicians_needed
from evening_visits_view
where appointment_type = 'Telephone Visit'
group by 1
order by appt_hour;
