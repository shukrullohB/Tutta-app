class ApiResponseParser {
  const ApiResponseParser._();

  static Map<String, dynamic> extractMap(Map<String, dynamic> response) {
    final candidates = <Object?>[
      response['data'],
      response['result'],
      response['payload'],
      response['item'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        return candidate;
      }
    }

    return response;
  }

  static List<Map<String, dynamic>> extractList(Map<String, dynamic> response) {
    final candidates = <Object?>[
      response['items'],
      response['data'],
      response['results'],
      response['list'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate.whereType<Map<String, dynamic>>().toList(
          growable: false,
        );
      }
    }

    return <Map<String, dynamic>>[];
  }
}
