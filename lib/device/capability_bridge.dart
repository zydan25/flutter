import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CapabilityBridge {
  CapabilityBridge({ImagePicker? imagePicker, LocalAuthentication? localAuth})
    : _imagePicker = imagePicker ?? ImagePicker(),
      _localAuth = localAuth ?? LocalAuthentication();

  final ImagePicker _imagePicker;
  final LocalAuthentication _localAuth;

  Future<dynamic> execute(
    BuildContext context,
    String capability,
    Map<String, dynamic> args,
  ) async {
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
        final text = args['text']?.toString();
        final uriText = args['uri']?.toString();
        final title = args['title']?.toString();
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            uri: uriText == null ? null : Uri.tryParse(uriText),
            subject: title,
          ),
        );
        return true;
      case 'camera':
        final image = await _imagePicker.pickImage(source: ImageSource.camera);
        return image?.path;
      case 'gallery':
        final image = await _imagePicker.pickImage(source: ImageSource.gallery);
        return image?.path;
      case 'files':
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: args['multiple'] == true,
          withData: args['with_data'] == true,
        );
        if (result == null) return null;
        return result.files
            .map(
              (file) => <String, dynamic>{
                'name': file.name,
                'path': file.path,
                'size': file.size,
              },
            )
            .toList();
      case 'biometric':
        final canCheck = await _localAuth.canCheckBiometrics;
        final supported = await _localAuth.isDeviceSupported();
        if (!canCheck && !supported) return false;
        return _localAuth.authenticate(
          localizedReason: '${args['reason'] ?? 'تحقق من هويتك للمتابعة'}',
          persistAcrossBackgrounding: true,
        );
      case 'location':
        var serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await Geolocator.openLocationSettings();
          if (!serviceEnabled && !await Geolocator.isLocationServiceEnabled()) {
            return null;
          }
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
        final position = await Geolocator.getCurrentPosition();
        return <String, dynamic>{
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        };
      case 'qr':
        return _scanQr(context);
      case 'deep_link':
        final uri = Uri.tryParse('${args['url'] ?? ''}');
        if (uri == null) return false;
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      default:
        throw UnsupportedError('Unknown device capability: $capability');
    }
  }

  Future<String?> _scanQr(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 320,
          height: 420,
          child: MobileScanner(
            onDetect: (capture) {
              final code = capture.barcodes
                  .map((barcode) => barcode.rawValue)
                  .firstWhere(
                    (value) => value != null && value!.isNotEmpty,
                    orElse: () => null,
                  );
              if (code != null) Navigator.of(context).pop(code);
            },
          ),
        ),
      ),
    );
  }
}
