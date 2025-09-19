import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  // Keys
  static const String strengthInputStyleKey = 'strength_input_style_index';
  static const String formFieldStyleKey = 'form_field_style_index';

  // Defaults
  static const int defaultStrengthInputStyle = 0;
  static const int defaultFormFieldStyle = 0;

  static Future<int> getStrengthInputStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(strengthInputStyleKey) ?? defaultStrengthInputStyle;
    }

  static Future<void> setStrengthInputStyle(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(strengthInputStyleKey, index);
  }

  static Future<int> getFormFieldStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(formFieldStyleKey) ?? defaultFormFieldStyle;
  }

  static Future<void> setFormFieldStyle(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(formFieldStyleKey, index);
  }
}
