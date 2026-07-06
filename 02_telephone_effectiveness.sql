-- ============================================================================
-- Q2: How effective are after-hours telephone appointments (after 5:30pm)?
--
-- Definition: an appointment is "effective" if the same patient has NO
-- follow-up appointment (of any type) within the following 7 days.
-- Approach: self-join each telephone visit to any later visit by the same
--           patient within a 7-day window. No match => resolved.
-- ============================================================================

create view clinic_telephone_effectiveness_view as
with temp as (
    select
        facility,
        department,
        provider_id,
        appointment_date as appt_date,
        cast(appointment_time as varchar) as appt_time,
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
    p1.appt_date,
    p1.appt_time,
    p1.patient_id,
    p1.appointment_type,
    max(case
        when p2.appt_date > p1.appt_date
         and date_diff('day', p1.appt_date, p2.appt_date) <= 7 then 1
        else 0
    end) as had_any_7day_followup
from temp p1
left join temp p2
    on p1.patient_id = p2.patient_id
where p1.appointment_type = 'Telephone Visit'
  and p1.appt_time >= '17:30:00'
group by 1, 2, 3, 4, 5, 6, 7;

-- Result: total after-hours phone visits, resolved vs. unresolved, and the
-- overall effectiveness rate.
-- Output -> total_after_hours_phone_visits: 3534 | completely_resolved_visits: 2749
--        -> unresolved_visits_with_followup: 785 | program_effectiveness_rate: 77.79%
select
    count(*) as total_after_hours_phone_visits,
    sum(case when had_any_7day_followup = 0 then 1 else 0 end) as completely_resolved_visits,
    sum(case when had_any_7day_followup = 1 then 1 else 0 end) as unresolved_visits_with_followup,
    round(
        sum(case when had_any_7day_followup = 0 then 1 else 0 end) * 100.0 / count(*),
        2
    ) as program_effectiveness_rate
from clinic_telephone_effectiveness_view;
