# adding android studio exports for zsh to Storage driver instead of the default home driver
# this needs to be sourced to .zshrc for both home and root.



#########################################
# adding path to android main directories
#########################################

# adding android SDK directory
export ANDROID_SDK_ROOT=run/media/ahmdhosni/Storage/Android/Sdk
export GRADLE_USER_HOME=$ANDROID_SDK_ROOT/gradle/.gradle
export STUDIO_PROPERTIES=$ANDROID_SDK_ROOT/custom_options/idea.properties
export ANDROID_PREFS_ROOT=$ANDROID_SDK_ROOT/prefs_root
export ANDROID_EMULATOR_HOME=$ANDROID_PREFS_ROOT/.android
export ANDROID_AVD_HOME=$ANDROID_EMULATOR_HOME/avd


# adding flutter to PATH 
export PATH=$ANDROID_SDK_ROOT/flutter/bin:$PATH
# adding tools and platform-tools to PATH
export PATH=$ANDROID_SDK_ROOT/tools:$PATH
export PATH=$ANDROID_SDK_ROOT/platform-tools:$PATH
export PATH=/home/ahmdhosni/Downloads/voidrice-master/.local/bin:$PATH
