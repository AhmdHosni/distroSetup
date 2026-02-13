#!/bin/bash
# adding android studio exports for zsh to Storage driver instead of the default home driver
# this needs to be sourced to .zshrc for both home and root.



#########################################
# adding path to android main directories
#########################################

# Where is android studio located
export ANDROID_DIR="/media/ahmdhosni/Storage/Apps/Android"
export ANDROID_STUDIO_DIR="$ANDROID_DIR/android-studio/bin"

# adding android SDK directory
export ANDROID_HOME="$ANDROID_DIR/Sdk"       # Sets the path to the SDK installation directory
export ANDROID_USER_HOME=$ANDROID_HOME/.android     # Sets the path to the user preferences directory for tools that are part of the Android SDK. Defaults to $HOME/.android/. 
export GRADLE_USER_HOME=$ANDROID_HOME/gradle/.gradle    
#export STUDIO_PROPERTIES=$ANDROID_HOME/custom_options/idea.properties
#export ANDROID_PREFS_ROOT=$ANDROID_HOME/prefs_root
#export ANDROID_AVD_HOME=$ANDROID_EMULATOR_HOME/avd

PLATFORM_TOOLS_PATH="$ANDROID_HOME/platform-tools"
TOOLS_PATH="$ANDROID_HOME/tools"
FLUTTER_PATH="$ANDROID_HOME/flutter/bin"



# adding to $PATH
export PATH=$PATH:$ANDROID_STUDIO_DIR:$PLATFORM_TOOLS_PATH:$TOOLS_PATH:$FLUTTER_PATH

# adding flutter to PATH 
#export PATH=$ANDROID_HOME/flutter/bin:$PATH
# adding tools and platform-tools to PATH
#export PATH=$ANDROID_HOME/tools:$PATH
#export PATH=$ANDROID_HOME/platform-tools:$PATH
