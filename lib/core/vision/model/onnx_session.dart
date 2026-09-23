import 'package:wardrobe/core/vision/model/model_status.dart';
import 'package:wardrobe/core/vision/onnx/onnx_runtime.dart';

/// A named ONNX session. FFI buffers stay inside [OnnxRuntime].
class OnnxSession {
  OnnxSession(this.name);

  final String name;
  ModelStatus status = ModelStatus.unloaded;

  void load(String modelPath) {
    status = ModelStatus.loading;
    try {
      OnnxRuntime.loadSession(name, modelPath);
      status = ModelStatus.ready;
    } catch (error) {
      status = ModelStatus.failed;
      rethrow;
    }
  }

  List<OnnxTensor> run({
    required List<OnnxTensor> inputs,
    required List<String> outputNames,
    required List<int> outputCounts,
  }) {
    try {
      return OnnxRuntime.runSession(
        name: name,
        inputs: inputs,
        outputNames: outputNames,
        outputCounts: outputCounts,
      );
    } catch (error) {
      status = ModelStatus.failed;
      rethrow;
    }
  }

  ({List<String> inputs, List<String> outputs}) get io =>
      OnnxRuntime.sessionIo(name);

  void close() {
    OnnxRuntime.closeSession(name);
    status = ModelStatus.unloaded;
  }
}
