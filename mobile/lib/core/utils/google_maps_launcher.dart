import 'package:url_launcher/url_launcher.dart';

Future<bool> openGoogleMaps({
  required String query,
}) async {
  final normalized = query.trim();
  if (normalized.isEmpty) {
    return false;
  }

  final uri = Uri.https('www.google.com', '/maps/search/', <String, String>{
    'api': '1',
    'query': normalized,
  });

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
