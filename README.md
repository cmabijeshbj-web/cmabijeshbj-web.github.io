# Bijesh BJ — Finance & FP&A Portfolio

Static site (HTML/CSS/JS only) — ready for GitHub Pages.

## Deploy to cmabijeshbj-web.github.io

1. Copy everything in this folder into the root of your `cmabijeshbj-web.github.io` repo
   (replacing what's there now), keeping the folder structure:
   ```
   index.html
   about.html
   experience.html
   projects.html
   certifications.html     (now "Education & Certifications")
   resume.html
   contact.html
   css/style.css
   js/site.js               (nav, footer, theme toggle — single source of truth)
   projects/*.html
   assets/downloads/*       (Excel workbooks, SQL file, CSVs, resume PDF)
   assets/certificates/*    (put certificate scans here — see EDITING-GUIDE.md)
   ```
2. Commit and push to the `main` branch. GitHub Pages will publish automatically
   at https://cmabijeshbj-web.github.io/.

## Making future edits

See **`EDITING-GUIDE.md`** in this folder — it covers editing text, adding
photos or certificate scans, adding a new section or page, and how the
navigation menu now updates from a single file (`js/site.js`) instead of
being copy-pasted across all 14 pages.

An editable Word document with all the site's current text (`Portfolio-Content.docx`)
is also included, in case you'd rather revise the wording offline and hand
it back for the site to be updated.

## About the profile photo

The photo URL currently points to a Google Drive link, converted to a direct-view
format. Google Drive sometimes blocks hotlinking (loading the image on another
site), which can make it fail to display. **The more reliable option:**

1. Save your photo into this repo at `assets/profile.jpg`.
2. In `index.html`, find the `<img class="hero-photo" src="...">` tag and change
   the `src` to `assets/profile.jpg`.

If the photo fails to load for any reason, the site automatically falls back to
a navy circle with your initials — so the page never breaks either way.

## What's in assets/downloads/

| File | Project |
|---|---|
| `FPA_Variance_KPI_Analysis.xlsx` | FP&A Performance, Variance & KPI Analysis |
| `Integrated_Financial_Model.xlsx` | 3-Statement Financial Model & DCF Valuation |
| `UAE_VAT_Calculation_Reconciliation.xlsx` | UAE VAT Calculation & Reconciliation |
| `UAE_Corporate_Tax_Computation.xlsx` | UAE Corporate Tax Computation Model |
| `financial_data_analysis.sql` + `sales_transactions.csv` | Financial Data Analysis Using SQL |
| `bu_monthly_pl.csv` | Underlying dataset for the interactive Power BI-style dashboard |
| `Bijesh_BJ_CMA_Resume.pdf` | Downloadable résumé |

All figures, company names, and clients in every workbook are **synthetic —
generated for this portfolio, not real employer or client data.**

## Notes

- Light/dark mode toggle is saved per-visitor in their browser (no server needed).
- The interactive dashboard (`projects/powerbi-dashboard-live.html`) loads
  Chart.js from a CDN — it needs an internet connection to render the charts,
  which GitHub Pages visitors will have.
- Still open / not filled in: a **Projects section** in the résumé-style
  content was intentionally left empty (per your instruction) and can be
  added later the same way these six were.
- The three certification cards on the Education & Certifications page
  currently show a placeholder icon — drop your real certificate scans
  into `assets/certificates/` (see EDITING-GUIDE.md) to replace them.
