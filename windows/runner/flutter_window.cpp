#include "flutter_window.h"

#include <optional>
#include <mmdeviceapi.h>
#include <audiopolicy.h>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

namespace {

void SetWindowsAudioDuckingOptOut(bool optOut) {
  HRESULT hr = CoInitialize(NULL);
  IMMDeviceEnumerator* pEnumerator = NULL;
  hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), NULL, CLSCTX_ALL,
                        __uuidof(IMMDeviceEnumerator), (void**)&pEnumerator);
  if (FAILED(hr) || !pEnumerator) {
    if (SUCCEEDED(hr)) CoUninitialize();
    return;
  }

  IMMDeviceCollection* pDevices = NULL;
  hr = pEnumerator->EnumAudioEndpoints(eAll, DEVICE_STATE_ACTIVE, &pDevices);
  if (SUCCEEDED(hr) && pDevices) {
    UINT count = 0;
    pDevices->GetCount(&count);
    DWORD currentPid = GetCurrentProcessId();

    for (UINT i = 0; i < count; ++i) {
      IMMDevice* pDevice = NULL;
      if (SUCCEEDED(pDevices->Item(i, &pDevice)) && pDevice) {
        IAudioSessionManager2* pSessionManager = NULL;
        if (SUCCEEDED(pDevice->Activate(__uuidof(IAudioSessionManager2), CLSCTX_ALL,
                                         NULL, (void**)&pSessionManager)) &&
            pSessionManager) {
          IAudioSessionEnumerator* pSessionEnum = NULL;
          if (SUCCEEDED(pSessionManager->GetSessionEnumerator(&pSessionEnum)) &&
              pSessionEnum) {
            int sessionCount = 0;
            pSessionEnum->GetCount(&sessionCount);
            for (int s = 0; s < sessionCount; ++s) {
              IAudioSessionControl* pSessionControl = NULL;
              if (SUCCEEDED(pSessionEnum->GetSession(s, &pSessionControl)) &&
                  pSessionControl) {
                IAudioSessionControl2* pSessionControl2 = NULL;
                if (SUCCEEDED(pSessionControl->QueryInterface(
                        __uuidof(IAudioSessionControl2), (void**)&pSessionControl2)) &&
                    pSessionControl2) {
                  DWORD sessionPid = 0;
                  pSessionControl2->GetProcessId(&sessionPid);
                  if (sessionPid == currentPid) {
                    pSessionControl2->SetDuckingPreference(optOut ? TRUE : FALSE);
                  }
                  pSessionControl2->Release();
                }
                pSessionControl->Release();
              }
            }
            pSessionEnum->Release();
          }
          pSessionManager->Release();
        }
        pDevice->Release();
      }
    }
    pDevices->Release();
  }
  pEnumerator->Release();
  CoUninitialize();
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  auto audio_ducking_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.projectnbx.audio/ducking",
          &flutter::StandardMethodCodec::GetInstance());

  audio_ducking_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name().compare("setDuckingOptOut") == 0) {
          bool optOut = true;
          const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments) {
            auto it = arguments->find(flutter::EncodableValue("optOut"));
            if (it != arguments->end()) {
              if (const auto* val = std::get_if<bool>(&it->second)) {
                optOut = *val;
              }
            }
          }
          SetWindowsAudioDuckingOptOut(optOut);
          result->Success(flutter::EncodableValue(true));
        } else {
          result->NotImplemented();
        }
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
