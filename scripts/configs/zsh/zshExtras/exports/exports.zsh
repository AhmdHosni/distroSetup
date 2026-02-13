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

# Java Location (Debian standard path for OpenJDK 17)
export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
#export _JAVA_OPTIONS="$XDG_CONFIG_HOME"/java
export _JAVA_OPTIONS="-Duser.home=$XDG_CONFIG_HOME"
export JAVA_TOOL_OPTIONS="-Duser.home=$XDG_DATA_HOME/java"


# adding to $PATH
#export PATH=$PATH:$ANDROID_STUDIO_DIR:$PLATFORM_TOOLS_PATH:$TOOLS_PATH:$FLUTTER_PATH

# adding flutter to PATH 
export PATH=$PATH:$ANDROID_STUDIO_DIR
export PATH=$ANDROID_HOME/flutter/bin:$PATH
#adding tools and platform-tools to PATH
#export PATH=$ANDROID_HOME/tools:$PATH
#export PATH=$ANDROID_HOME/platform-tools:$PATH
# Update PATH to include Android Tools
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/build-tools
# Optional: Move Emulator data if your Home partition is small
