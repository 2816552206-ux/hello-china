@echo off
set JAVA_HOME=E:\dome\jdk17
set ANDROID_HOME=E:\dome\android-sdk
set ANDROID_SDK_ROOT=E:\dome\android-sdk
set PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%
cd /d E:\dome\hello_china
echo ===== Flutter Build APK =====
E:\dome\flutter\bin\flutter.bat build apk --debug
echo EXIT_CODE=%ERRORLEVEL%
if exist build\app\outputs\flutter-apk\app-debug.apk (
    echo ===== APK Build Success =====
    dir build\app\outputs\flutter-apk\app-debug.apk
) else (
    echo ===== APK Not Found =====
)
