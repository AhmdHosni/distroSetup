#!/bin/bash
# adding android studio exports for zsh to Storage driver instead of the default home driver
# this needs to be sourced to .zshrc for both home and root.

# https://developer.android.com/tools/variables

#########################################
# adding path to android main directories
#########################################

# Where is android studio located
export ANDROID_DIR="/media/ahmdhosni/Storage/Apps/Android"
export ANDROID_STUDIO_DIR="$ANDROID_DIR/android-studio/bin"         # location of android studio portable


# ANDROID_HOME (SDK HOME DIR)
# # Sets the path to the SDK installation directory
# Sets the path to the SDK installation directory. 
# Once set, the value does not typically change and can be shared by multiple users on the same machine. 
# ANDROID_SDK_ROOT, which also points to the SDK installation directory, is deprecated. 
# If you continue to use it, Android Studio and the Android Gradle plugin will check that the old and new variables are consistent
export ANDROID_HOME=$ANDROID_DIR/sdk
#export JAVA_HOME=$ANDROID_HOME/openJDK-26              # location of openJDK portable


# ANDROID_USER_HOME (.android)
# Sets the path to the user preferences directory for tools that are part of the Android SDK. 
#Defaults to $HOME/.android/.
# Some older tools, such as Android Studio 4.3 and earlier, do not read ANDROID_USER_HOME. 
# To override the user preferences location for those older tools, 
# set ANDROID_SDK_HOME to the parent directory you would like the .android directory to be created under. 
export ANDROID_USER_HOME=$ANDROID_HOME/custom/.android

# Tell adb to look for the key in a different place than ~/.android
#export ADB_VENDOR_KEYS=$HOME/.config/android


#export ANDROID_PREFS_ROOT=$ANDROID_HOME/.android
export GRADLE_USER_HOME=$ANDROID_HOME/custom/.gradle    
#export STUDIO_PROPERTIES=$ANDROID_HOME/custom_options/idea.properties
#export ANDROID_PREFS_ROOT=$ANDROID_HOME/prefs_root
#export ANDROID_AVD_HOME=$ANDROID_EMULATOR_HOME/avd

# extras
# vmoptions
#Sets the location of the studio.vmoptions file. 
#This file contains settings that affect the performance characteristics of the Java HotSpot Virtual Machine. 
#This file can also be accessed from within Android Studio
export STUDIO_VM_OPTIONS=$ANDROID_HOME/custom/vm-options/studio.vmoptions   


# studio-properties
# Sets the location of the idea.properties file. 
# This file lets you customize Android Studio IDE properties, 
# such as the path to user installed plugins and the maximum file size supported by the IDE
export STUDIO_PROPERTIES=$ANDROID_HOME/custom/studio-properties/idea.properties


# STUDIO_JDK
# Sets the location of the JDK that Android Studio runs in. 
# When you launch the IDE, it checks the STUDIO_JDK, JDK_HOME, and JAVA_HOME environment variables, in that order.
#export STUDIO_JDK=
# openJDK 


# STUDIO_GRADLE_JDK
# Sets the location of the JDK that Android Studio uses to start the Gradle daemon. 
# When you launch the IDE, it first checks STUDIO_GRADLE_JDK. 
# If STUDIO_GRADLE_JDK is not defined, the IDE uses the value set in the project structure settings
#export STUDIO_GRADLE_JDK=


# ANDROID_AVD_HOME
# By default, the emulator stores configuration files under $HOME/.android/ and AVD data under $HOME/.android/avd/. 
# You can override the defaults by setting the following environment variables. 
# The emulator -avd <avd_name> command searches the avd directory in the order of the values in 
# $ANDROID_AVD_HOME, $ANDROID_USER_HOME/avd/, and $HOME/.android/avd/.
# For emulator environment variable help, type emulator -help-environment at the command line. 
# For information about emulator command-line options, see Start the emulator from the command line. 
export ANDROID_AVD_HOME=$ANDROID_HOME/custom/.android



# ANDROID_EMULATOR_HOME
# Sets the path to the user-specific emulator configuration directory. 
# Defaults to $ANDROID_USER_HOME.
# Older tools, such as Android Studio 4.3 and earlier, do not read ANDROID_USER_HOME. 
# For those tools, the default value is $ANDROID_SDK_HOME/.android
# export ANDROID_EMULATOR_HOME=

# ANDROID_AVD_HOME
# Sets the path to the directory that contains all AVD-specific files, 
# which mostly consist of very large disk images. 
# The default location is $ANDROID_EMULATOR_HOME/avd/. 
# You might want to specify a new location if the default location is low on disk space.
# export ANDROID_AVD_HOME=``




#export _JAVA_OPTIONS="$XDG_CONFIG_HOME"/java
#export _JAVA_OPTIONS="-Duser.home=$XDG_CONFIG_HOME"
#export JAVA_TOOL_OPTIONS="-Duser.home=$XDG_DATA_HOME/java"




PLATFORM_TOOLS_PATH="$ANDROID_HOME/platform-tools"
TOOLS_PATH="$ANDROID_HOME/tools"
FLUTTER_PATH="$ANDROID_HOME/flutter/bin"

# adding to $PATH
#export PATH=$PATH:$ANDROID_STUDIO_DIR:$PLATFORM_TOOLS_PATH:$TOOLS_PATH:$FLUTTER_PATH


export PATH=$PATH:$ANDROID_STUDIO_DIR       # adding android studio portable to PATH
export PATH=$PATH:$ANDROID_HOME/flutter/bin     # adding flutter to PATH 
export PATH=$PATH:$JAVA_HOME/bin            # adding openJDK executables to PATH

#adding tools and platform-tools to PATH
#export PATH=$ANDROID_HOME/tools:$PATH
#export PATH=$ANDROID_HOME/platform-tools:$PATH
# Update PATH to include Android Tools
export PATH=$PATH:$ANDROID_HOME/emulator
#export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/build-tools
# Optional: Move Emulator data if your Home partition is small
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools



