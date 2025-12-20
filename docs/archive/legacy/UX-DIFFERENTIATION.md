# UI Domain Differentiation

Status: Active

Summary
- Removed the previous left accent stripes from list cards (Medications, Schedules, Supplies). These were too visually heavy and were not preferred.
- Replaced with a subtle, consistent approach using avatar/icon container gradients per domain:
  - Medications: primaryContainer → primary
  - Schedules: secondaryContainer → secondary
  - Supplies: tertiaryContainer → tertiary
- This provides quick domain recognition without adding noise or altering card layout/spacing.

Rationale
- Maintain Material 3 aesthetic with minimal visual distractions.
- Keep card layout identical across domains for muscle memory and scanability.
- Use existing color semantics (primary/secondary/tertiary) to indicate domain, concentrated in a small focal area (icon/avatar), instead of large stripes.

Implementation Notes
- Medications list cards already used a primary-tinted avatar container.
- Schedules list cards: avatar container updated to use secondary gradient.
- Supplies list cards: avatar container updated to use tertiary gradient.
- Removed any Positioned left-edge Containers (3px accent) previously used for domain differentiation.

Design Rules Reinforced
- No bottom-sheet popups for summaries or transient UI (see docs/agent.md rules).
- Subtle differentiation preferred over heavy, persistent chroma.

QA Checklist
- Cards render without left stripe on all three list screens.
- Avatar/icon container shows the expected domain tint.
- No regressions in layout alignment, padding, or hit targets.

Change History
- 2025-09-26: Introduced avatar gradient differentiation; removed left accent stripes.
