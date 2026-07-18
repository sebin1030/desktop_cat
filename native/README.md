# Native Channel Files

이 폴더의 파일은 Flutter 데스크톱 runner가 생성된 뒤 플랫폼별 runner에 복사해서 사용합니다.

## macOS

`native/macos/AppDelegate.swift`를 `macos/Runner/AppDelegate.swift`에 복사합니다.

## Windows

1. `native/windows/native_channels.cpp`와 `native/windows/native_channels.h`를 `windows/runner/`에 복사합니다.
2. `windows/runner/flutter_window.cpp`에서 플러그인 등록 이후 아래 코드를 호출합니다.

```cpp
#include "native_channels.h"

desktop_cat::RegisterNativeChannels(flutter_controller_->engine()->messenger());
```

3. `windows/runner/CMakeLists.txt`의 runner source 목록에 `native_channels.cpp`를 추가합니다.
