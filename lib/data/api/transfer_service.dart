import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';

class TransferService {
  TransferService(this.api, {this.accessTokenProvider});

  final ApiClient api;
  final Future<String?> Function()? accessTokenProvider;

  Future<Response<dynamic>> upload({
    required String path,
    required String filePath,
    String field = 'file',
    Map<String, dynamic>? fields,
  }) async {
    final token = await accessTokenProvider?.call();
    return api.dio.post<dynamic>(
      path,
      data: FormData.fromMap({
        if (fields != null) ...fields,
        field: MultipartFile.fromFileSync(
          filePath,
          filename: filePath.split(Platform.pathSeparator).last,
        ),
      }),
      options: Options(
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<String> download({required String path, String? fileName}) async {
    final directory = await getApplicationDocumentsDirectory();
    final token = await accessTokenProvider?.call();
    final safeName = (fileName == null || fileName.isEmpty)
        ? 'runtime_${DateTime.now().millisecondsSinceEpoch}.bin'
        : fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final target = '${directory.path}/$safeName';
    await api.dio.download(
      path,
      target,
      options: Options(
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
    );
    return target;
  }
}
