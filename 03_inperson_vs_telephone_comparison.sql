-- ============================================================================
-- Q3: In-person vs. telephone visit effectiveness, across all hours and
--     restricted to after-hours (post-17:30).
--
-- Same 7-day-no-followup definition as Q2, but grouped by appointment_type
-- instead of filtered to telephone only, so both modes can be compared
-- directly.
-- ============================================================================

-- 3a. All operating hours
with data as (
    select
        facility,
        department,
        provider_id,
        cast(appointment_date as date) as appt_date,
        cast(appointment_time as varchar) as appt_time,
        cast(patient_id as varchar) as patient_id_str,
        appointment_type,
        show_code
    from raw_appointments
    where show_code = 'Y'
)
select
    p1.appointment_type,
    count(distinct p1.patient_id_str || '-' || cast(p1.appt_date as varchar) || '-' || p1.appt_time)
        as total_appointments,
    sum(case when p2.appt_date is null then 1 else 0 end) as successful_resolutions,
    count(distinct p2.patient_id_str || '-' || cast(p2.appt_date as varchar) || '-' || p2.appt_time)
        as appointments_with_followup,
    round(
        sum(case when p2.appt_date is null then 1 else 0 end) * 100.0 /
        count(distinct p1.patient_id_str || '-' || cast(p1.appt_date as varchar) || '-' || p1.appt_time),
        2
    ) as effectiveness_rate_percentage
from data p1
left join data p2
    on p1.patient_id_str = p2.patient_id_str
   and p2.appt_date > p1.appt_date
   and date_diff('day', p1.appt_date, p2.appt_date) <= 7
group by p1.appointment_type;
-- Result: Telephone Visit 81.16% (8,766 / 10,801) | In-Person Visit 94.56% (95,526 / 101,019)

-- 3b. After-hours only (post-17:30)
with data as (
    select
        facility,
        department,
        provider_id,
        cast(appointment_date as date) as appt_date,
        cast(appointment_time as varchar) as appt_time,
        cast(patient_id as varchar) as patient_id_str,
        appointment_type,
        show_code
    from raw_appointments
    where show_code = 'Y'
)
select
    p1.appointment_type,
    count(distinct p1.patient_id_str || '-' || cast(p1.appt_date as varchar) || '-' || p1.appt_time)
        as total_appointments,
    sum(case when p2.appt_date is null then 1 else 0 end) as successful_resolutions,
    count(distinct p2.patient_id_str || '-' || cast(p2.appt_date as varchar) || '-' || p2.appt_time)
        as appointments_with_followup,
    round(
        sum(case when p2.appt_date is null then 1 else 0 end) * 100.0 /
        count(distinct p1.patient_id_str || '-' || cast(p1.appt_date as varchar) || '-' || p1.appt_time),
        2
    ) as effectiveness_rate_percentage
from data p1
left join data p2
    on p1.patient_id_str = p2.patient_id_str
   and p2.appt_date > p1.appt_date
   and date_diff('day', p1.appt_date, p2.appt_date) <= 7
where p1.appt_time >= '17:30:00'
group by p1.appointment_type;
-- Result: Telephone Visit 77.79% (2,749 / 3,534) | In-Person Visit 87.62% (2,145 / 2,448)

-- 3c. Follow-up destination breakdown (for Q4): of the unresolved after-hours
-- telephone visits, how many patients actually came back, and via which channel?
select appointment_date, substring(appointment_time, 1, 2) as ti, count(patient_id) as nump
from raw_appointments
where show_code = 'Y'
  and appointment_type = 'Telephone Visit'
  and appointment_time >= '17:30:00'
group by appointment_date, substring(appointment_time, 1, 2)
order by count(patient_id) desc;
