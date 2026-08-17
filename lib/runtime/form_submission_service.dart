import '../data/api/api_client.dart';
import '../data/local/drift_store.dart';
import 'form_controller.dart';

class FormSubmissionResult {
  const FormSubmissionResult({required this.data, required this.statusCode});

  final dynamic data;
  final int statusCode;
}

class FormSubmissionService {
  FormSubmissionService({required this.api, required this.store});

  final ApiClient api;
  final DriftStore store;

  Future<FormSubmissionResult> submit({
    required DynamicFormController controller,
    required String path,
    String method = 'POST',
    Map<String, dynamic>? mapping,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    String? localResourceId,
    int localVersion = 0,
    String localChecksum = '',
  }) async {
    controller.removeHiddenValues();
    final errors = controller.validate();
    if (errors.isNotEmpty) {
      throw FormValidationException(errors);
    }

    final payload = controller.submission(mapping: mapping);
    final response = await api.request(
      method: method,
      path: path,
      query: query,
      headers: headers,
      body: payload,
    );
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      throw StateError('Form submission failed with HTTP $status');
    }

    if (localResourceId != null && response.data is Map) {
      await store.saveResource(
        id: localResourceId,
        version: localVersion,
        checksum: localChecksum,
        payload: (response.data as Map).cast<String, dynamic>(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
    }

    return FormSubmissionResult(data: response.data, statusCode: status);
  }
}
