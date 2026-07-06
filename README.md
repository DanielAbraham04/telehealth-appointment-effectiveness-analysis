# Telehealth vs. In-Person Appointment Effectiveness Analysis

A SQL-driven analysis of appointment data for an outpatient clinic network offering both
in-person and after-hours telephone visits. The project evaluates staffing needs, measures
how effective telephone visits are at resolving patient issues, compares them against
in-person care, and recommends operational changes to close the gap.

This project was built as an independent case study using the same analytical approach I'd
apply to a real operations/clinical-analytics problem: define the metric, write the SQL to
prove it, visualize it, and turn the numbers into a recommendation.

> **Note on data:** The underlying appointment data is proprietary and not included in this
> repo. The `sql/` folder contains the actual queries used, and the numbers quoted in this
> README are the real output of those queries, so the logic and results are fully
> reproducible against any dataset with the same schema (see [`docs/data_schema.md`](docs/data_schema.md)).

## Tech Stack

- **AWS S3 + Glue** — raw appointment data storage and cataloging
- **AWS Athena (Presto SQL)** — querying, window functions, self-joins for follow-up detection
- **Tableau** — visualization of staffing curves and effectiveness comparisons
- **Excel** — quick validation and pivot cross-checks

## Business Questions & Findings

### 1. How many physicians are needed to staff the after-hours telephone clinic?

Assuming 1 physician can handle 4 telephone visits/hour, a simple daily average suggests
**2 physicians**. But averages hide the peak: broken out by hour, demand is front-loaded
right after 5:30pm and tapers off late in the evening.

| Hour | Avg. patients/hour | Physicians required |
|------|--------------------:|---------------------:|
| 17:00 | 6.5 | 2 |
| 18:00 | 8.8 | 3 |
| 19:00 | 5.9 | 2 |
| 20:00 | 3.3 | 1 |

**Takeaway:** staff to the hourly curve, not the nightly average — 3 physicians from
6–7pm, scaling down to 1 after 8pm, covers peak demand without overstaffing the quiet hours.

### 2. How effective are after-hours telephone appointments?

Effectiveness is defined as *no follow-up visit within 7 days*. Of 3,534 after-hours
telephone visits, 2,749 needed no follow-up — a **77.79% effectiveness rate**. Roughly 4 in
5 calls fully resolve the issue; 1 in 5 requires the patient to be seen again within a week.

### 3. In-person vs. telephone visits — which is more effective?

In-person visits outperform telephone visits at every time window, and the gap is worse
after hours:

| Window | In-Person | Telephone |
|---|---:|---:|
| All operating hours | 94.56% | 81.16% |
| After-hours (post-17:30) | 87.62% | 77.79% |

Show-rate (did the patient actually attend?) tells a related story:

| Appointment Type | Scheduled | Completed | Show Rate |
|---|---:|---:|---:|
| In-Person | 111,834 | 101,019 | 90.33% |
| Telephone | 13,219 | 10,801 | 81.71% |

**Takeaway:** telephone visits are the dominant mode after-hours (~60% of evening volume)
but have both a lower resolution rate and a lower show-rate — nearly 1 in 5 scheduled phone
appointments never happen at all. Patients treat the lower-friction booking option with
less commitment, and clinically, a portion of phone visits likely need a hands-on exam that
a call can't substitute for.

### 4. How can telephone appointment effectiveness be improved?

Of the 785 unresolved after-hours telephone visits, only 60 patients booked a proper
follow-up (23 in-person, 37 by phone). **725 patients simply didn't come back** — the data
suggests they sought care elsewhere rather than re-booking.

Three concrete recommendations to close that gap:

1. **Pre-screen bookings with a symptom checklist.** Block patients from selecting a
   telephone slot if their symptoms likely require a physical exam, and route them to
   in-person scheduling instead.
2. **Build a warm hand-off to walk-in clinics.** Give the after-hours phone physician a
   tool to instantly book the patient an early-morning slot at a partner walk-in clinic
   when a call isn't enough.
3. **Move telephone visits to video.** Visual examination over video should catch more of
   what a phone call misses, increasing both physician confidence and first-call
   resolution.

## Repo Structure

```
telehealth-appointment-effectiveness-analysis/
├── README.md
├── sql/
│   ├── 01_after_hours_staffing.sql          -- hourly staffing model
│   ├── 02_telephone_effectiveness.sql       -- after-hours phone effectiveness rate
│   ├── 03_inperson_vs_telephone_comparison.sql  -- effectiveness, all hours vs after-hours
│   └── 04_show_rate_comparison.sql          -- scheduled vs completed by appointment type
└── docs/
    └── data_schema.md                       -- assumed source table schema
```

## Methodology Notes

- "Effectiveness" for a visit is computed with a self-join: each visit is joined to any
  later visit by the same patient within a 7-day window; if none exists, the visit is
  counted as resolved.
- All queries filter on `show_code = 'Y'` for effectiveness metrics (only completed visits
  can be judged on outcome), but the show-rate query intentionally uses the *full* scheduled
  population to measure no-shows.
- Hour-of-day staffing uses `ceiling(avg_visits_per_hour / 4)` to size physician coverage
  conservatively — rounding up rather than down to avoid understaffing peak demand.

## Author

Daniel Abraham
