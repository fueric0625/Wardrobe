import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

typedef _LoadNative = Int32 Function(Pointer<Utf16> modelPath);
typedef _LoadDart = int Function(Pointer<Utf16> modelPath);
typedef _LoadNamedNative = Int32 Function(Pointer<Utf8> name, Pointer<Utf16> modelPath);
typedef _LoadNamedDart = int Function(Pointer<Utf8> name, Pointer<Utf16> modelPath);
typedef _RunNative = Int32 Function(
  Pointer<Float> input,
  Int32 inputCount,
  Pointer<Float> output,
  Int32 outputCount,
);
typedef _RunDart = int Function(
  Pointer<Float> input,
  int inputCount,
  Pointer<Float> output,
  int outputCount,
);
typedef _RunNamedNative = Int32 Function(
  Pointer<Utf8> name,
  Int32 nIn,
  Pointer<Pointer<Utf8>> inNames,
  Pointer<Pointer<Float>> inData,
  Pointer<Int32> inCounts,
  Pointer<Int64> inShapes,
  Pointer<Int32> inRanks,
  Int32 nOut,
  Pointer<Pointer<Utf8>> outNames,
  Pointer<Pointer<Float>> outData,
  Pointer<Int32> outMax,
  Pointer<Int32> outWritten,
);
typedef _RunNamedDart = int Function(
  Pointer<Utf8> name,
  int nIn,
  Pointer<Pointer<Utf8>> inNames,
  Pointer<Pointer<Float>> inData,
  Pointer<Int32> inCounts,
  Pointer<Int64> inShapes,
  Pointer<Int32> inRanks,
  int nOut,
  Pointer<Pointer<Utf8>> outNames,
  Pointer<Pointer<Float>> outData,
  Pointer<Int32> outMax,
  Pointer<Int32> outWritten,
);
typedef _VoidNative = Void Function();
typedef _VoidDart = void Function();
typedef _CloseNamedNative = Void Function(Pointer<Utf8> name);
typedef _CloseNamedDart = void Function(Pointer<Utf8> name);
typedef _IoCountNative = Int32 Function(Pointer<Utf8> name, Pointer<Int32> nIn, Pointer<Int32> nOut);
typedef _IoCountDart = int Function(Pointer<Utf8> name, Pointer<Int32> nIn, Pointer<Int32> nOut);
typedef _IoNameNative = Pointer<Utf8> Function(Pointer<Utf8> name, Int32 output, Int32 index);
typedef _IoNameDart = Pointer<Utf8> Function(Pointer<Utf8> name, int output, int index);
typedef _ErrNative = Pointer<Utf8> Function();
typedef _ErrDart = Pointer<Utf8> Function();

class OnnxUnavailableException implements Exception {
  OnnxUnavailableException(this.message);
  final String message;
  @override
  String toString() => message;
}

class OnnxTensor {
  OnnxTensor(this.name, this.shape, this.values);

  final String name;
  final List<int> shape;
  final List<double> values;
}

/// Thin FFI to the `garment_onnx_*` exports compiled into the Windows runner.
class OnnxRuntime {
  OnnxRuntime._();

  static _LoadDart? _load;
  static _LoadNamedDart? _loadNamed;
  static _RunDart? _run;
  static _RunNamedDart? _runNamed;
  static _VoidDart? _close;
  static _CloseNamedDart? _closeNamed;
  static _ErrDart? _lastError;
  static _IoCountDart? _ioCount;
  static _IoNameDart? _ioName;

  static bool get isBound {
    try {
      _ensure();
      return true;
    } catch (_) {
      return false;
    }
  }

  static void _ensure() {
    if (_load != null) return;
    final lib = _open();
    _load = lib.lookupFunction<_LoadNative, _LoadDart>('garment_onnx_load');
    _loadNamed = lib.lookupFunction<_LoadNamedNative, _LoadNamedDart>(
      'garment_onnx_session_load',
    );
    _run = lib.lookupFunction<_RunNative, _RunDart>('garment_onnx_run');
    _runNamed = lib.lookupFunction<_RunNamedNative, _RunNamedDart>(
      'garment_onnx_session_run',
    );
    _close = lib.lookupFunction<_VoidNative, _VoidDart>('garment_onnx_close');
    _closeNamed = lib.lookupFunction<_CloseNamedNative, _CloseNamedDart>(
      'garment_onnx_session_close',
    );
    _lastError = lib.lookupFunction<_ErrNative, _ErrDart>('garment_onnx_last_error');
    _ioCount = lib.lookupFunction<_IoCountNative, _IoCountDart>(
      'garment_onnx_session_io_count',
    );
    _ioName = lib.lookupFunction<_IoNameNative, _IoNameDart>(
      'garment_onnx_session_io_name',
    );
  }

  static DynamicLibrary _open() {
    try {
      return DynamicLibrary.executable();
    } catch (_) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return DynamicLibrary.open(p.join(exeDir, 'wardrobe.exe'));
    }
  }

  static String lastError() {
    final fn = _lastError;
    if (fn == null) return 'ONNX 未加载';
    final ptr = fn();
    if (ptr == nullptr) return '';
    return ptr.toDartString();
  }

  static void load(String modelPath) {
    loadSession('u2net', modelPath);
  }

  static void loadSession(String name, String modelPath) {
    _ensure();
    final namePtr = name.toNativeUtf8();
    final path = modelPath.toNativeUtf16();
    try {
      final rc = _loadNamed!(namePtr, path);
      if (rc != 0) {
        throw OnnxUnavailableException(lastError());
      }
    } finally {
      malloc.free(namePtr);
      malloc.free(path);
    }
  }

  static List<double> run(List<double> input, int outputCount) {
    _ensure();
    final inPtr = malloc<Float>(input.length);
    final outPtr = malloc<Float>(outputCount);
    try {
      for (var i = 0; i < input.length; i++) {
        inPtr[i] = input[i];
      }
      final rc = _run!(inPtr, input.length, outPtr, outputCount);
      if (rc != 0) {
        throw OnnxUnavailableException(lastError());
      }
      return [for (var i = 0; i < outputCount; i++) outPtr[i].toDouble()];
    } finally {
      malloc.free(inPtr);
      malloc.free(outPtr);
    }
  }

  static List<OnnxTensor> runSession({
    required String name,
    required List<OnnxTensor> inputs,
    required List<String> outputNames,
    required List<int> outputCounts,
  }) {
    _ensure();
    if (inputs.isEmpty || outputNames.isEmpty || outputNames.length != outputCounts.length) {
      throw OnnxUnavailableException('invalid session tensors');
    }
    final namePtr = name.toNativeUtf8();
    final nIn = inputs.length;
    final nOut = outputNames.length;
    final inNameHeap = <Pointer<Utf8>>[];
    final outNameHeap = <Pointer<Utf8>>[];
    final inBufs = <Pointer<Float>>[];
    final outBufs = <Pointer<Float>>[];
    final inNames = malloc<Pointer<Utf8>>(nIn);
    final inData = malloc<Pointer<Float>>(nIn);
    final inCounts = malloc<Int32>(nIn);
    final inRanks = malloc<Int32>(nIn);
    var shapeLen = 0;
    for (final tensor in inputs) {
      shapeLen += tensor.shape.length;
    }
    final inShapes = malloc<Int64>(shapeLen);
    final outNames = malloc<Pointer<Utf8>>(nOut);
    final outData = malloc<Pointer<Float>>(nOut);
    final outMax = malloc<Int32>(nOut);
    final outWritten = malloc<Int32>(nOut);
    try {
      var shapeOffset = 0;
      for (var i = 0; i < nIn; i++) {
        final tensor = inputs[i];
        final n = tensor.name.toNativeUtf8();
        inNameHeap.add(n);
        inNames[i] = n;
        final buf = malloc<Float>(tensor.values.length);
        inBufs.add(buf);
        for (var k = 0; k < tensor.values.length; k++) {
          buf[k] = tensor.values[k];
        }
        inData[i] = buf;
        inCounts[i] = tensor.values.length;
        inRanks[i] = tensor.shape.length;
        for (final dim in tensor.shape) {
          inShapes[shapeOffset++] = dim;
        }
      }
      for (var i = 0; i < nOut; i++) {
        final n = outputNames[i].toNativeUtf8();
        outNameHeap.add(n);
        outNames[i] = n;
        final buf = malloc<Float>(outputCounts[i]);
        outBufs.add(buf);
        outData[i] = buf;
        outMax[i] = outputCounts[i];
        outWritten[i] = 0;
      }
      final rc = _runNamed!(
        namePtr,
        nIn,
        inNames,
        inData,
        inCounts,
        inShapes,
        inRanks,
        nOut,
        outNames,
        outData,
        outMax,
        outWritten,
      );
      if (rc != 0) {
        throw OnnxUnavailableException(lastError());
      }
      return [
        for (var i = 0; i < nOut; i++)
          OnnxTensor(
            outputNames[i],
            const [],
            [for (var k = 0; k < outWritten[i]; k++) outBufs[i][k].toDouble()],
          ),
      ];
    } finally {
      malloc.free(namePtr);
      malloc.free(inNames);
      malloc.free(inData);
      malloc.free(inCounts);
      malloc.free(inRanks);
      malloc.free(inShapes);
      malloc.free(outNames);
      malloc.free(outData);
      malloc.free(outMax);
      malloc.free(outWritten);
      for (final ptr in inNameHeap) {
        malloc.free(ptr);
      }
      for (final ptr in outNameHeap) {
        malloc.free(ptr);
      }
      for (final ptr in inBufs) {
        malloc.free(ptr);
      }
      for (final ptr in outBufs) {
        malloc.free(ptr);
      }
    }
  }

  static ({List<String> inputs, List<String> outputs}) sessionIo(String name) {
    _ensure();
    final namePtr = name.toNativeUtf8();
    final nIn = malloc<Int32>();
    final nOut = malloc<Int32>();
    try {
      final rc = _ioCount!(namePtr, nIn, nOut);
      if (rc != 0) {
        throw OnnxUnavailableException(lastError());
      }
      final inputs = <String>[];
      final outputs = <String>[];
      for (var i = 0; i < nIn.value; i++) {
        final ptr = _ioName!(namePtr, 0, i);
        if (ptr != nullptr) inputs.add(ptr.toDartString());
      }
      for (var i = 0; i < nOut.value; i++) {
        final ptr = _ioName!(namePtr, 1, i);
        if (ptr != nullptr) outputs.add(ptr.toDartString());
      }
      return (inputs: inputs, outputs: outputs);
    } finally {
      malloc.free(namePtr);
      malloc.free(nIn);
      malloc.free(nOut);
    }
  }

  static void closeSession(String name) {
    _ensure();
    final namePtr = name.toNativeUtf8();
    try {
      _closeNamed!(namePtr);
    } finally {
      malloc.free(namePtr);
    }
  }

  static void close() {
    _close?.call();
  }
}
