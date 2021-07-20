#!/bin/bash
export ANDROID_HOME=~/Library/Android/sdk
export API=30
if [ $API == 28 -o $API == 30 ]
        then
          export PACKAGE="system-images;android-${API};google_apis;x86"
          export ABI="google_apis/x86"
        else
          export PACKAGE="system-images;android-${API};google_apis;x86_64"
          export ABI="google_apis/x86_64"
        fi

export EMULATOR_NAME="${EMULATOR}_API${API}"
echo y | $ANDROID_HOME/tools/bin/sdkmanager --install $PACKAGE
echo no | "$ANDROID_HOME/tools/bin/avdmanager" create avd -n Pixel_XL -d pixel_xl --abi $ABI --package $PACKAGE --force
echo "AVD created:"
"$ANDROID_HOME/emulator/emulator" -list-avds
