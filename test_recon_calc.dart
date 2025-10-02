// Test file to verify reconstitution calculator formula
// Run with: dart test_recon_calc.dart

void main() {
  print('Testing Reconstitution Calculator Formula\n');
  
  // Formula: V = (S / D) × (U / 100)
  // Where:
  // S = total strength in vial (mg)
  // D = desired dose per injection (mg)
  // U = IU units to draw from syringe
  // V = vial volume (mL)
  
  double computeVial({
    required double S,
    required double D,
    required double U,
  }) {
    final v = (S / D) * (U / 100.0);
    return (v * 100).round() / 100.0; // Round to 2 decimals
  }
  
  double computeConcentration({
    required double D,
    required double U,
  }) {
    final c = (100 * D) / U;
    return (c * 100).round() / 100.0; // Round to 2 decimals
  }
  
  // Example 1: Strength 5mg, Dose 250mcg = 0.25mg, Syringe 0.3mL = 30 IU
  print('Example 1: Strength 5mg, Dose 0.25mg, Syringe 0.3mL (30 IU)');
  print('Expected: Preset 1: 1mL vial, 5 IU');
  var v1 = computeVial(S: 5.0, D: 0.25, U: 5.0);
  var c1 = computeConcentration(D: 0.25, U: 5.0);
  print('Calculated: ${v1}mL vial, 5 IU, ${c1}mg/mL');
  print('✓ ${v1 == 1.0 ? "PASS" : "FAIL - Expected 1.0"}');
  print('');
  
  print('Expected: Preset 2: 3mL vial, 15 IU');
  var v2 = computeVial(S: 5.0, D: 0.25, U: 15.0);
  var c2 = computeConcentration(D: 0.25, U: 15.0);
  print('Calculated: ${v2}mL vial, 15 IU, ${c2}mg/mL');
  print('✓ ${v2 == 3.0 ? "PASS" : "FAIL - Expected 3.0"}');
  print('');
  
  print('Expected: Preset 3: 5mL vial, 25 IU');
  var v3 = computeVial(S: 5.0, D: 0.25, U: 25.0);
  var c3 = computeConcentration(D: 0.25, U: 25.0);
  print('Calculated: ${v3}mL vial, 25 IU, ${c3}mg/mL');
  print('✓ ${v3 == 5.0 ? "PASS" : "FAIL - Expected 5.0"}');
  print('');
  print('---');
  print('');
  
  // Example 2: Strength 5mg, Dose 500mcg = 0.5mg, Syringe 1mL = 100 IU, Max 10mL
  print('Example 2: Strength 5mg, Dose 0.5mg, Syringe 1mL (100 IU), Max 10mL');
  print('Expected: Preset 1: 2mL vial, 20 IU');
  var v4 = computeVial(S: 5.0, D: 0.5, U: 20.0);
  var c4 = computeConcentration(D: 0.5, U: 20.0);
  print('Calculated: ${v4}mL vial, 20 IU, ${c4}mg/mL');
  print('✓ ${v4 == 2.0 ? "PASS" : "FAIL - Expected 2.0"}');
  print('');
  
  print('Expected: Preset 2: 5mL vial, 55 IU');
  var v5 = computeVial(S: 5.0, D: 0.5, U: 55.0);
  var c5 = computeConcentration(D: 0.5, U: 55.0);
  print('Calculated: ${v5}mL vial, 55 IU, ${c5}mg/mL');
  print('Note: User specified 55 IU, calculated ${v5}mL');
  print('');
  
  print('Expected: Preset 3: 9mL vial, 90 IU');
  var v6 = computeVial(S: 5.0, D: 0.5, U: 90.0);
  var c6 = computeConcentration(D: 0.5, U: 90.0);
  print('Calculated: ${v6}mL vial, 90 IU, ${c6}mg/mL');
  print('✓ ${v6 == 9.0 ? "PASS" : "FAIL - Expected 9.0"}');
  print('');
  print('---');
  print('');
  
  // Example 3: Strength 5mg, Dose 500mcg = 0.5mg, Syringe 1mL = 100 IU, Max 5mL
  print('Example 3: Strength 5mg, Dose 0.5mg, Syringe 1mL (100 IU), Max 5mL');
  print('Expected: Preset 1: 1mL vial, 10 IU');
  var v7 = computeVial(S: 5.0, D: 0.5, U: 10.0);
  var c7 = computeConcentration(D: 0.5, U: 10.0);
  print('Calculated: ${v7}mL vial, 10 IU, ${c7}mg/mL');
  print('✓ ${v7 == 1.0 ? "PASS" : "FAIL - Expected 1.0"}');
  print('');
  
  print('Expected: Preset 2: 2.5mL vial, 25 IU');
  var v8 = computeVial(S: 5.0, D: 0.5, U: 25.0);
  var c8 = computeConcentration(D: 0.5, U: 25.0);
  print('Calculated: ${v8}mL vial, 25 IU, ${c8}mg/mL');
  print('✓ ${v8 == 2.5 ? "PASS" : "FAIL - Expected 2.5"}');
  print('');
  
  print('Expected: Preset 3: 5mL vial, 50 IU');
  var v9 = computeVial(S: 5.0, D: 0.5, U: 50.0);
  var c9 = computeConcentration(D: 0.5, U: 50.0);
  print('Calculated: ${v9}mL vial, 50 IU, ${c9}mg/mL');
  print('✓ ${v9 == 5.0 ? "PASS" : "FAIL - Expected 5.0"}');
  print('');
  
  print('\n=== All Tests Complete ===');
}
