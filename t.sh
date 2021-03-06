# This is a basic workflow to help you get started with Actions

name: CI

on: [push, workflow_dispatch]
    
jobs:
  build:
    runs-on: macos-latest
    strategy:
     matrix:
       api: [1, 2, 3, 4, 5]

    steps:
    - uses: actions/checkout@v2
    
    #    - name: build
    #  run: |
      #    ./gradlew :app:assembleDebug  :app:assembleDebugAndroidTest

    - name: create AVD
      run: |
        export API=30
        if [ $API == 28 ]
        then
          export PACKAGE="system-images;android-${API};google_apis;x86"
          export ABI="google_apis/x86"
        else
          export PACKAGE="system-images;android-${API};google_apis;x86_64"
          export ABI="google_apis/x86_64"
        fi

        export EMULATOR_NAME="${EMULATOR}_API${API}"
        echo y | $ANDROID_HOME/tools/bin/sdkmanager --install $PACKAGE
        echo no | "$ANDROID_HOME/tools/bin/avdmanager" create avd -n TestAvd -d pixel_xl --abi $ABI --package $PACKAGE --force
        echo "AVD created:"
        "$ANDROID_HOME/emulator/emulator" -list-avds

    - name: accel check
      run: |
        "$ANDROID_HOME/emulator/emulator" -accel-check

    - name: modify config.ini
      run: |
        echo 'config.ini'
        cat ~/.android/avd/TestAvd.avd/config.ini
        #sed  -ibak -e '/^hw.mainKeys/d'  ~/.android/avd/TestAvd.avd/config.ini
        #echo 'hw.mainKeys=true' >> ~/.android/avd/TestAvd.avd/config.ini
        #echo 'disk.dataPartition.size=8192MB' >> ~/.android/avd/TestAvd.avd/config.ini
        #echo 'hw.ramSize=8192MB' >> ~/.android/avd/TestAvd.avd/config.ini
        #echo '== config.ini modified'
        #cat ~/.android/avd/TestAvd.avd/config.ini

    - name: run emulator
      continue-on-error: true
      run: |
        nohup "$ANDROID_HOME/emulator/emulator" -avd TestAvd -no-snapshot -no-window -no-audio -no-boot-anim -accel on -wipe-data 2>&1 &
        EMU_BOOTED=0
        n=0
        
        echo "Waiting for device 45 sec..."
        sleep 45
        
        while [[ ${EMU_BOOTED} != "1" ]];do
            echo "Waiting android to boot 10 sec..."
            sleep 10
            CURRENT_FOCUS=`adb shell dumpsys window windows 2>/dev/null | grep -i mCurrentFocus`
            echo "(DEBUG) Current focus: ${CURRENT_FOCUS}"

            case $CURRENT_FOCUS in
            *"Launcher"*)
              EMU_BOOTED=1
            ;;
            *"Not Responding"*)
              echo "System UI isn't responding ..."
              adb shell input keyevent KEYCODE_DPAD_DOWN
              adb shell input keyevent KEYCODE_DPAD_DOWN
              adb shell input keyevent KEYCODE_ENTER
            ;;
            *)
              n=$((n + 1))
              if [ $n -gt 30 ]; then
                  echo "Android Emulator does not start in 5 minutes"
                  echo "failed" > /tmp/failed
                  exit 2
              fi
            ;;
            esac
        done
        echo "Android Emulator started."
        
        echo "Access emulator with adb"
        
        "$ANDROID_HOME/platform-tools/adb" shell ls || true

    - name: show emulator log
      run: |
        test -f nohup.out && cat nohup.out || echo 'no nohup.out'

#    - name: install apk
#      run: |
  #        $ANDROID_HOME/platform-tools/adb install app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
  #      $ANDROID_HOME/platform-tools/adb install app/build/outputs/apk/debug/app-debug.apk

    - name: run test
      continue-on-error: true
      run: |
        if test -s /tmp/failed; then 
          echo "Skip"
        else
          ./gradlew connectedAndroidTest
        fi
        #$ANDROID_HOME/platform-tools/adb shell am instrument -w -m -e debug false -e class 'vsedoli.espressodemo.ExampleInstrumentedTest' vsedoli.espressodemo.test/androidx.test.runner.AndroidJUnitRunner

    - name: grab screen
      run: |
        $ANDROID_HOME/platform-tools/adb exec-out screencap -p > screen.png

    - uses: actions/upload-artifact@v2
      with:
        name: screen-${{matrix.api}}.png
        path: screen.png
