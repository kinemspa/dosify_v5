# Skedux Website Launch Kit

Date: 2026-03-15

## Recommendation

For launch, do not build a full marketing site.

Use a minimal public website with these pages:

1. Home
2. Privacy Policy
3. Terms of Use
4. Support

This can be a single-page site plus 2 to 3 plain legal/support pages. A static host is enough.

## Good Low-Effort Hosting Options

1. GitHub Pages
2. Netlify
3. Cloudflare Pages
4. Carrd, if you want the absolute fastest non-technical landing page

If you want the cleanest launch path, use a static host and a custom domain.

## Public URLs To Prepare

These are the URLs you should expect to need or strongly benefit from in Google Play Console:

1. Privacy Policy URL
2. Website URL or marketing URL
3. Support contact email
4. Optional support website URL

The hard requirement depends on your final Play declarations and SDK usage, but given billing, ads, and optional backup/sign-in features, you should assume the Privacy Policy URL is required.

## Minimum Site Structure

### 1. Home

Purpose:
- explain what Skedux is
- set expectations clearly
- link to privacy, terms, and support

Suggested URL:
- `/`

Suggested sections:
- hero
- core features
- who it is for
- important disclaimer summary
- support and legal links

### 2. Privacy Policy

Purpose:
- public privacy URL for Play Console
- explain local storage, Google Play billing, ads, and optional Google Drive backup

Suggested URL:
- `/privacy`

Source of truth:
- mirror the substance of [lib/src/core/legal/disclaimer_strings.dart](lib/src/core/legal/disclaimer_strings.dart)

### 3. Terms of Use

Purpose:
- public legal terms page
- describe that the app is a tracking/reference tool, not medical advice

Suggested URL:
- `/terms`

Source of truth:
- mirror the substance of [lib/src/core/legal/disclaimer_strings.dart](lib/src/core/legal/disclaimer_strings.dart)

### 4. Support

Purpose:
- provide a visible support path for users and Play review
- keep support simple at launch

Suggested URL:
- `/support`

Suggested content:
- support email
- expected response window
- basic help topics
- restore/purchase/support guidance

## Homepage Copy Draft

### Hero

Headline:

`Track medication schedules, entries, inventory, and reconstitution references in one place.`

Subheading:

`Skedux is a research reference, organization, and tracking app for medication records. Manage schedules, reminders, entry logs, stock, and vial or reconstitution-related values from a single app.`

Primary CTA:

`Get the app on Google Play`

Secondary CTA:

`Read the privacy policy`

### Feature Section

Section title:

`What Skedux helps you manage`

Bullets:

- `Schedules and reminders for recurring entries`
- `Entry logging and history tracking`
- `Medication inventory and low-stock visibility`
- `Vial and reconstitution reference calculations`
- `Backup and restore options for your records`

### Positioning Section

Section title:

`Built for organization and reference`

Paragraph:

`Skedux is designed for people who want a structured way to track medication-related records, schedules, inventory details, and reconstitution reference values. It is intended for organization, research, and recordkeeping workflows.`

### Disclaimer Summary Section

Section title:

`Important notice`

Paragraph:

`Skedux is a research reference and tracking tool. It does not provide medical advice, diagnosis, treatment, clinical decision support, or emergency care. Always verify all medication names, concentrations, units, schedules, reminders, and reconstitution values with a qualified healthcare professional and official labeling.`

### Footer Links

Include links to:

- `Privacy Policy`
- `Terms of Use`
- `Support`
- `Contact`

## Privacy Policy Intro Draft

`Skedux stores the medication records, schedules, inventory details, and related information that you enter locally on your device inside an encrypted database. Skedux does not operate its own cloud sync or central application server for your primary records.`

`Skedux may integrate with Google Play Billing, Google AdMob, and optional Google Drive backup features. If you use those features, Google or other platform providers may process account, purchase, advertising, device, sign-in, or backup metadata under their own terms and privacy policies.`

`If you enable optional Google Drive backup, backup files are uploaded to app storage in your Google Drive account. If you choose password-protected backup, the exported backup payload is encrypted before export or upload.`

## Terms Of Use Intro Draft

`Skedux is provided as a research, organization, and tracking tool only. It is not a substitute for professional medical judgment, diagnosis, treatment, or emergency care.`

`You are responsible for verifying entered data, calculations, concentrations, schedules, reminders, and inventory records before relying on them.`

`Features may change, be limited, or be removed without notice.`

## Support Page Draft

Headline:

`Skedux Support`

Support copy:

`For support requests, contact: support@YOURDOMAIN.com`

`Please include your device model, Android version, app version, and a short description of the problem.`

Suggested FAQ items:

1. `How do I restore a backup?`
2. `How do I restore my Pro purchase?`
3. `Why are reminders not appearing reliably?`
4. `How do I export or delete backups?`

Suggested support note:

`Reminder delivery can be affected by Android battery optimization, notification permissions, and manufacturer-specific background restrictions.`

## Play Console Mapping

Use these site assets in Play Console:

1. Website URL: home page
2. Privacy Policy URL: privacy page
3. Support contact: support email and optional support page URL

## Launch Checklist

1. Register domain
2. Publish home, privacy, terms, and support pages
3. Add support email to the site footer
4. Verify privacy and terms text matches the in-app legal content
5. Paste the privacy URL into Play Console
6. Paste the website URL into Play Console
7. Test each URL in an incognito browser before publishing

## Recommendation On Scope

Do not delay launch to build a full brand site.

For first publish, a clean static site with clear legal pages and a support path is enough.