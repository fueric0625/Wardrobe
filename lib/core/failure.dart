sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class ImageDecodeFailure extends AppFailure {
  const ImageDecodeFailure(super.message, {super.cause});
}

class ModelLoadFailure extends AppFailure {
  const ModelLoadFailure(super.message, {super.cause});
}

class InferenceFailure extends AppFailure {
  const InferenceFailure(super.message, {super.cause});
}

class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.cause});
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.cause});
}
