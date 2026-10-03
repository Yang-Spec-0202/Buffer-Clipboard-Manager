#!/bin/bash
# Shared by the local build and tests. BUFFER_SDK can select a particular installed SDK.
buffer_sdk="${BUFFER_SDK:-$(xcrun --show-sdk-path --sdk macosx)}"
# Some Command Line Tools installations include macOS 27's SwiftUI macro declarations
# without the SwiftUIMacros compiler plugin. Use the installed compatible SDK in that case.
if [[ -z "${BUFFER_SDK:-}" && ( "$buffer_sdk" == *MacOSX27* || "$(readlink "$buffer_sdk")" == *MacOSX27* ) &&
      ! -e "$(xcode-select -p)/usr/lib/swift/host/plugins/libSwiftUIMacros.dylib" &&
      -d /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk ]]; then
    buffer_sdk=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
fi
