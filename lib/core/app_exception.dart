/// Base exception untuk aplikasi JELO.
/// Melakukan override pada `toString()` untuk mengembalikan pesan tanpa prefix "Exception: ".
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class LocationException extends AppException {
  const LocationException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class DatabaseException extends AppException {
  const DatabaseException(super.message);
}
