class ApiServices {
  static Future<Map<String, dynamic>> get(String endpoint) async {
    // Mock HTTP get helper
    return {'status': 'success', 'data': []};
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    // Mock HTTP post helper
    return {'status': 'success', 'data': []};
  }
}
