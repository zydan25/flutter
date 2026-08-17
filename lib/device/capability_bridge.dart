import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CapabilityBridge {
  Future<dynamic> execute(String capability, Map<String, dynamic> args) async {
    switch (capability) {
      case 'clipboard.write':
        await Clipboard.setData(ClipboardData(text: '${args['text'] ?? ''}'));
        return true;
      case 'browser.open':
      case 'open_url':
        final uri = Uri.tryParse('${args['url'] ?? ''}');
        if (uri == null) return false;
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      case 'share':
      case 'camera':
      case 'gallery':
      case 'files':
      case 'biometric':
      case 'location':
      case 'qr':
      case 'deep_link':
        throw UnsupportedError('Capability "$capability" requires a platform adapter.');
      default:
        throw UnsupportedError('Unknown device capability: $capability');
    }
  }
}
