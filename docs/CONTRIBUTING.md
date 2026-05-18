# Contributing / Adding Content

## Workflow for a new course or certification

1. **Pick the right domain folder** — `sql/`, `python/`, `cloud/`, `data-engineering/`, `cybersecurity/`, etc.

2. **Create a notes file** using the template:

   ```
   _templates/course-notes.md  →  <domain>/notes/<course-slug>.md
   ```

3. **If you earned a certification**, also create:

   ```
   _templates/certification-summary.md  →  <domain>/certifications/<cert-slug>.md
   ```

   Store the PDF/image credential in the same folder: `<domain>/certifications/<cert-slug>.pdf`

4. **Update the domain README** — add a row to the courses table.

5. **Update the root README** — add a row to the Certifications table if applicable.

6. **Commit with a descriptive message**, e.g.:
   ```
   docs(sql): add notes for Mode Analytics SQL Tutorial
   docs(cloud/aws): add AWS Cloud Practitioner certification summary
   ```

---

## File naming convention

| Type | Pattern | Example |
|---|---|---|
| Notes | `<topic-slug>.md` | `window-functions.md` |
| Certification summary | `<cert-slug>.md` | `aws-cloud-practitioner.md` |
| Credential file | `<cert-slug>_<issuer>_<year>.pdf` | `aws-cloud-practitioner_amazon_2026.pdf` |
| Exercise | `<topic-slug>_<number>.sql` | `joins_01.sql` |

---

## Commit message convention

```
docs(<domain>): <action> <subject>

Examples:
  docs(python): add notes for Python for Data Engineers course
  docs(cybersecurity): add TryHackMe SOC Level 1 certification
  feat(data-engineering): add Airflow DAG exercise
```
