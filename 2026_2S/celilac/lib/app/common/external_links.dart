import 'package:url_launcher/url_launcher.dart';

Uri phoneUri(String phone) {
  return Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));
}

Uri mapsUri(String address) {
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': address,
  });
}

Future<bool> openExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
