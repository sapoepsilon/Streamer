import 'package:shared_preferences/shared_preferences.dart';

// Saving credentials
void saveCredentials(String username, String password, String server) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString("username", username);
  prefs.setString("password", password);
  prefs.setString("server", server);
}

// Retrieving credentials
Future<Map<String, String>> getCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString("username");
  final password = prefs.getString("password");
  final server = prefs.getString("server");
  return {
    "username": username ?? "noUsername",
    "password": password ?? "noPassword",
    "server": server ?? "noServer"
  };
}
