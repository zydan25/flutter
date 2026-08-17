import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';

class TransferService {
  TransferService(this.api);

  final ApiClient api;

  Future<Response<dynamic>> upload({
    required String path,
    required String filePath,
    String field = 'file',
    Map<String, dynamic>? fields,
  }) {
    return api.dio.post<dynamic>(
      path,
      data: FormData.fromMap({
        if (fields != null) ...fields,
        field: MultipartFile.fromFileSync(
          filePath,
          filename: filePath.split(Platform.pathSeparator).last,
        ),
      }),
      options: Options(headers: {'Authorization': 'Bearer'}),
    );
  }

  Future<String> download({required String path, String? fileName}) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeName = (fileName == null || fileName.isEmpty)
        ? 'runtime_${DateTime.now().millisecondsSinceEpoch}.bin'
        : fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final target = '${directory.path}/$safeName';
    await api.dio.download(path, target);
    return target;
  }
}
