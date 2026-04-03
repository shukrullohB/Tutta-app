import 'package:url_launcher/url_launcher.dart';

Future<bool> openGoogleMaps({
  required String query,
  double? latitude,
  double? longitude,
}) async {
  final normalized = query.trim();
  final hasCoordinates = latitude != null && longitude != null;
  if (normalized.isEmpty && !hasCoordinates) {
    return false;
  }

  final uri = Uri.https(
    'www.google.com',
    '/maps/search/',
    <String, String>{
      'api': '1',
      'query': hasCoordinates
          ? '${latitude!.toStringAsFixed(6)},${longitude!.toStringAsFixed(6)}'
          : normalized,
    },
  );

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
