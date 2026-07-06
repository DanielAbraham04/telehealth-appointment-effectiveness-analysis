# Data Schema (assumed)

The source data isn't included in this repo (it's a proprietary clinical dataset), but every
query in `sql/` runs against a single table, `raw_appointments`, with this shape:

| Column | Type | Description |
|---|---|---|
| `facility` | varchar | Clinic/facility identifier |
| `department` | varchar | Department within the facility |
| `provider_id` | varchar | Physician/provider identifier |
| `appointment_date` | date | Calendar date of the appointment |
| `appointment_time` | varchar/time | Scheduled time (`HH:mm[:ss]`) |
| `patient_id` | varchar/bigint | Unique patient identifier |
| `appointment_type` | varchar | `'Telephone Visit'` or `'In-Person Visit'` |
| `show_code` | varchar | `'Y'` if the patient showed up, otherwise a no-show code |

Queried via **AWS Athena** on top of data cataloged with **AWS Glue** from raw files in **S3**.

If you want to run these queries yourself against a similar dataset (e.g. a synthetic EHR
appointment dataset), point `raw_appointments` at any table matching this schema — the SQL
is otherwise self-contained.
