# Reconstitution Calculator

This dialog chooses solvent volume and resulting concentration to meet a desired dose using a syringe with IU markings. This section is final and implementable for rebuild.

Key formulas
- mL per IU assumed: 0.01 mL (100 IU per mL)
- Concentration (per mL): C = Dose / (Units × mL_per_IU) = 100 × Dose / Units
- Solvent volume (to add to vial): V = Strength_in_vial / C

Presets (Final)
- Compute allowed IU range [minIU, maxIU], where maxIU respects vial size (if provided)
- Choose three points evenly across the range: min, midpoint, max
- Show IU on each chip along with concentration and computed mL

Constraints
- Units are clamped between 5% and 100% of the syringe’s total IU
- If Vial Size is provided, solvent volume must be ≤ vial size

Outputs
- Concentration per mL (same unit as dose/strength input)
- Solvent volume to add (mL)
- Recommended IU on the selected syringe size

Integration
- Accessed from the Multi Dose Vial screen via the "Reconstitution Calculator" button
- On submit, it populates the per mL concentration field and shows a summary

Notes
- All values are rounded to 2 decimals for display
- The calculator currently assumes insulin-like syringes (100 IU per mL mapping)

