class SignupApiService {
  Future<bool> signup(String email, String password) async {
    // Mock signup logic
    await Future.delayed(const Duration(milliseconds: 1000));
    return true;
  }
}
