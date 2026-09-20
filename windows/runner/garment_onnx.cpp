#include <cstdint>
#include <cstring>
#include <map>
#include <string>
#include <vector>

#include "../third_party/onnxruntime/include/onnxruntime_c_api.h"

namespace {

const OrtApi* g_api = nullptr;
OrtEnv* g_env = nullptr;
OrtAllocator* g_allocator = nullptr;
char g_last_error[512] = {0};

struct LoadedSession {
  OrtSession* session = nullptr;
  std::vector<char*> input_names;
  std::vector<char*> output_names;
};

std::map<std::string, LoadedSession> g_sessions;

void set_error(const char* message) {
  const char* src = message ? message : "unknown error";
  size_t n = 0;
  while (src[n] != '\0' && n < sizeof(g_last_error) - 1) {
    g_last_error[n] = src[n];
    ++n;
  }
  g_last_error[n] = '\0';
}

bool check(OrtStatus* status) {
  if (status == nullptr) {
    return true;
  }
  const char* msg = g_api ? g_api->GetErrorMessage(status) : "ORT status";
  set_error(msg);
  if (g_api) {
    g_api->ReleaseStatus(status);
  }
  return false;
}

bool ensure_env() {
  if (!g_api) {
    const OrtApiBase* base = OrtGetApiBase();
    if (!base) {
      set_error("OrtGetApiBase failed");
      return false;
    }
    g_api = base->GetApi(ORT_API_VERSION);
    if (!g_api) {
      set_error("OrtGetApi failed");
      return false;
    }
  }
  if (!g_env) {
    if (!check(g_api->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "wardrobe", &g_env))) {
      return false;
    }
  }
  if (!g_allocator) {
    if (!check(g_api->GetAllocatorWithDefaultOptions(&g_allocator))) {
      return false;
    }
  }
  return true;
}

void free_names(std::vector<char*>& names) {
  if (!g_api || !g_allocator) {
    names.clear();
    return;
  }
  for (char* name : names) {
    if (name) {
      g_allocator->Free(g_allocator, name);
    }
  }
  names.clear();
}

void release_loaded(LoadedSession& loaded) {
  if (!g_api) {
    loaded.session = nullptr;
    loaded.input_names.clear();
    loaded.output_names.clear();
    return;
  }
  free_names(loaded.input_names);
  free_names(loaded.output_names);
  if (loaded.session) {
    g_api->ReleaseSession(loaded.session);
    loaded.session = nullptr;
  }
}

void release_session_named(const std::string& name) {
  auto it = g_sessions.find(name);
  if (it == g_sessions.end()) {
    return;
  }
  release_loaded(it->second);
  g_sessions.erase(it);
}

void release_all_sessions() {
  for (auto& entry : g_sessions) {
    release_loaded(entry.second);
  }
  g_sessions.clear();
}

int load_session(const std::string& name, const wchar_t* model_path) {
  g_last_error[0] = '\0';
  if (name.empty()) {
    set_error("session name is empty");
    return 1;
  }
  if (model_path == nullptr) {
    set_error("model path is null");
    return 1;
  }
  if (!ensure_env()) {
    return 1;
  }

  release_session_named(name);

  OrtSessionOptions* options = nullptr;
  if (!check(g_api->CreateSessionOptions(&options))) {
    return 1;
  }
  g_api->SetIntraOpNumThreads(options, 2);
  g_api->SetSessionGraphOptimizationLevel(options, ORT_ENABLE_BASIC);

  OrtSession* session = nullptr;
  const int rc = check(g_api->CreateSession(g_env, model_path, options, &session)) ? 0 : 1;
  g_api->ReleaseSessionOptions(options);
  if (rc != 0) {
    return 1;
  }

  LoadedSession loaded;
  loaded.session = session;

  size_t in_count = 0;
  size_t out_count = 0;
  if (!check(g_api->SessionGetInputCount(session, &in_count)) ||
      !check(g_api->SessionGetOutputCount(session, &out_count))) {
    release_loaded(loaded);
    return 1;
  }
  loaded.input_names.resize(in_count, nullptr);
  loaded.output_names.resize(out_count, nullptr);
  for (size_t i = 0; i < in_count; i++) {
    if (!check(g_api->SessionGetInputName(session, i, g_allocator, &loaded.input_names[i]))) {
      release_loaded(loaded);
      return 1;
    }
  }
  for (size_t i = 0; i < out_count; i++) {
    if (!check(g_api->SessionGetOutputName(session, i, g_allocator, &loaded.output_names[i]))) {
      release_loaded(loaded);
      return 1;
    }
  }
  g_sessions[name] = loaded;
  return 0;
}

LoadedSession* find_session(const char* name) {
  if (name == nullptr) {
    set_error("session name is null");
    return nullptr;
  }
  auto it = g_sessions.find(name);
  if (it == g_sessions.end() || it->second.session == nullptr) {
    set_error("session not loaded");
    return nullptr;
  }
  return &it->second;
}

}  // namespace

extern "C" {

__declspec(dllexport) const char* garment_onnx_last_error() { return g_last_error; }

__declspec(dllexport) void garment_onnx_close() {
  release_all_sessions();
  if (g_api && g_env) {
    g_api->ReleaseEnv(g_env);
    g_env = nullptr;
  }
  g_allocator = nullptr;
}

__declspec(dllexport) int garment_onnx_load(const wchar_t* model_path) {
  return load_session("u2net", model_path);
}

__declspec(dllexport) int garment_onnx_session_load(const char* name, const wchar_t* model_path) {
  return load_session(name ? name : "", model_path);
}

__declspec(dllexport) void garment_onnx_session_close(const char* name) {
  if (name == nullptr) {
    return;
  }
  release_session_named(name);
}

__declspec(dllexport) int garment_onnx_run(const float* input, int input_count, float* output,
                                           int output_count) {
  g_last_error[0] = '\0';
  LoadedSession* loaded = find_session("u2net");
  if (loaded == nullptr) {
    return 1;
  }
  if (input == nullptr || output == nullptr || input_count <= 0 || output_count <= 0) {
    set_error("invalid tensor buffer");
    return 1;
  }
  if (loaded->input_names.empty() || loaded->output_names.empty()) {
    set_error("session has no tensors");
    return 1;
  }

  OrtMemoryInfo* memory_info = nullptr;
  if (!check(g_api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &memory_info))) {
    return 1;
  }

  const int64_t shape[4] = {1, 3, 320, 320};
  const size_t expected = 1 * 3 * 320 * 320;
  if (static_cast<size_t>(input_count) < expected) {
    set_error("input tensor too small");
    g_api->ReleaseMemoryInfo(memory_info);
    return 1;
  }

  OrtValue* input_tensor = nullptr;
  if (!check(g_api->CreateTensorWithDataAsOrtValue(
          memory_info, const_cast<float*>(input),
          static_cast<size_t>(input_count) * sizeof(float), shape, 4,
          ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, &input_tensor))) {
    g_api->ReleaseMemoryInfo(memory_info);
    return 1;
  }

  const char* input_names[] = {loaded->input_names[0]};
  const char* output_names[] = {loaded->output_names[0]};
  OrtValue* output_tensor = nullptr;
  const int run_ok = check(g_api->Run(loaded->session, nullptr, input_names, &input_tensor, 1,
                                      output_names, 1, &output_tensor))
                         ? 0
                         : 1;

  if (run_ok == 0 && output_tensor != nullptr) {
    float* data = nullptr;
    if (check(g_api->GetTensorMutableData(output_tensor, reinterpret_cast<void**>(&data))) &&
        data != nullptr) {
      size_t count = static_cast<size_t>(output_count);
      OrtTensorTypeAndShapeInfo* info = nullptr;
      if (g_api->GetTensorTypeAndShape(output_tensor, &info) == nullptr && info != nullptr) {
        size_t element_count = 0;
        if (g_api->GetTensorShapeElementCount(info, &element_count) == nullptr &&
            element_count > 0 && element_count < count) {
          count = element_count;
        }
        g_api->ReleaseTensorTypeAndShapeInfo(info);
      }
      std::memcpy(output, data, count * sizeof(float));
    }
  }

  if (output_tensor) {
    g_api->ReleaseValue(output_tensor);
  }
  g_api->ReleaseValue(input_tensor);
  g_api->ReleaseMemoryInfo(memory_info);
  return run_ok;
}

__declspec(dllexport) int garment_onnx_session_run(
    const char* name, int n_in, const char* const* in_names, const float* const* in_data,
    const int* in_counts, const int64_t* in_shapes, const int* in_ranks, int n_out,
    const char* const* out_names, float* const* out_data, const int* out_max, int* out_written) {
  g_last_error[0] = '\0';
  LoadedSession* loaded = find_session(name);
  if (loaded == nullptr) {
    return 1;
  }
  if (n_in <= 0 || n_out <= 0 || in_names == nullptr || in_data == nullptr || in_counts == nullptr ||
      in_shapes == nullptr || in_ranks == nullptr || out_names == nullptr || out_data == nullptr ||
      out_max == nullptr || out_written == nullptr) {
    set_error("invalid session run arguments");
    return 1;
  }

  OrtMemoryInfo* memory_info = nullptr;
  if (!check(g_api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &memory_info))) {
    return 1;
  }

  std::vector<OrtValue*> input_tensors(static_cast<size_t>(n_in), nullptr);
  std::vector<const char*> input_name_list(static_cast<size_t>(n_in), nullptr);
  int shape_offset = 0;
  int ok = 0;
  for (int i = 0; i < n_in; i++) {
    input_name_list[static_cast<size_t>(i)] = in_names[i];
    const int rank = in_ranks[i];
    if (rank <= 0 || in_data[i] == nullptr || in_counts[i] <= 0) {
      set_error("invalid input tensor");
      ok = 1;
      break;
    }
    if (!check(g_api->CreateTensorWithDataAsOrtValue(
            memory_info, const_cast<float*>(in_data[i]),
            static_cast<size_t>(in_counts[i]) * sizeof(float), in_shapes + shape_offset, rank,
            ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, &input_tensors[static_cast<size_t>(i)]))) {
      ok = 1;
      break;
    }
    shape_offset += rank;
  }

  std::vector<OrtValue*> output_tensors;
  std::vector<const char*> output_name_list;
  if (ok == 0) {
    output_tensors.assign(static_cast<size_t>(n_out), nullptr);
    output_name_list.assign(static_cast<size_t>(n_out), nullptr);
    for (int i = 0; i < n_out; i++) {
      output_name_list[static_cast<size_t>(i)] = out_names[i];
    }
    if (!check(g_api->Run(loaded->session, nullptr, input_name_list.data(), input_tensors.data(),
                          static_cast<size_t>(n_in), output_name_list.data(),
                          static_cast<size_t>(n_out), output_tensors.data()))) {
      ok = 1;
    }
  }

  if (ok == 0) {
    for (int i = 0; i < n_out; i++) {
      out_written[i] = 0;
      OrtValue* tensor = output_tensors[static_cast<size_t>(i)];
      if (tensor == nullptr || out_data[i] == nullptr || out_max[i] <= 0) {
        continue;
      }
      float* data = nullptr;
      if (!check(g_api->GetTensorMutableData(tensor, reinterpret_cast<void**>(&data))) ||
          data == nullptr) {
        ok = 1;
        break;
      }
      size_t count = static_cast<size_t>(out_max[i]);
      OrtTensorTypeAndShapeInfo* info = nullptr;
      if (g_api->GetTensorTypeAndShape(tensor, &info) == nullptr && info != nullptr) {
        size_t element_count = 0;
        if (g_api->GetTensorShapeElementCount(info, &element_count) == nullptr &&
            element_count > 0 && element_count < count) {
          count = element_count;
        }
        g_api->ReleaseTensorTypeAndShapeInfo(info);
      }
      std::memcpy(out_data[i], data, count * sizeof(float));
      out_written[i] = static_cast<int>(count);
    }
  }

  for (OrtValue* tensor : output_tensors) {
    if (tensor) {
      g_api->ReleaseValue(tensor);
    }
  }
  for (OrtValue* tensor : input_tensors) {
    if (tensor) {
      g_api->ReleaseValue(tensor);
    }
  }
  g_api->ReleaseMemoryInfo(memory_info);
  return ok;
}

}  // extern "C"
