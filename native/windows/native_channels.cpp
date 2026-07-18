#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>

namespace desktop_cat {

void RegisterNativeChannels(flutter::BinaryMessenger* messenger) {
  auto sleep_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "desktop_cat/sleep_preventer",
          &flutter::StandardMethodCodec::GetInstance());

  sleep_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "enable") {
          SetThreadExecutionState(ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED);
          result->Success();
          return;
        }
        if (call.method_name() == "disable") {
          SetThreadExecutionState(ES_CONTINUOUS);
          result->Success();
          return;
        }
        result->NotImplemented();
      });

  static auto keep_sleep_channel_alive = std::move(sleep_channel);

  auto idle_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "desktop_cat/idle_detector",
          &flutter::StandardMethodCodec::GetInstance());

  idle_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() != "idleSeconds") {
          result->NotImplemented();
          return;
        }

        LASTINPUTINFO info;
        info.cbSize = sizeof(LASTINPUTINFO);
        if (!GetLastInputInfo(&info)) {
          result->Success(flutter::EncodableValue(0));
          return;
        }

        const DWORD now = GetTickCount();
        const int idle_seconds = static_cast<int>((now - info.dwTime) / 1000);
        result->Success(flutter::EncodableValue(idle_seconds));
      });

  static auto keep_idle_channel_alive = std::move(idle_channel);
}

}  // namespace desktop_cat
