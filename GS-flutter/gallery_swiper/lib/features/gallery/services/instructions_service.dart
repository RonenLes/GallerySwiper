import 'package:shared_preferences/shared_preferences.dart';

class InstructionsService {
  static const _preferenceKey = 'show_instructions';

  Future<bool> shouldShow() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_preferenceKey) ?? true;
  }

  Future<void> hide() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, false);
  }

  Future<void> enable() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, true);
  }
}
