#ifndef RUNNER_NATIVE_CHANNELS_H_
#define RUNNER_NATIVE_CHANNELS_H_

namespace flutter {
class BinaryMessenger;
}

namespace desktop_cat {
void RegisterNativeChannels(flutter::BinaryMessenger* messenger);
}

#endif  // RUNNER_NATIVE_CHANNELS_H_
