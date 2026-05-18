@echo off
chcp 65001 >nul
echo === ZIP 转 IPA 工具 ===
echo.

if "%~1"=="" (
    echo 用法: 把 runner.app.zip 拖到这个 bat 文件上
    echo 或者: zip2ipa.bat runner.app.zip
    pause
    exit /b 1
)

set "ZIP_FILE=%~1"
set "OUT_DIR=%~dp1"

if not exist "%ZIP_FILE%" (
    echo 文件不存在: %ZIP_FILE%
    pause
    exit /b 1
)

echo 输入: %ZIP_FILE%

:: 创建临时目录
set "TMP_DIR=%TEMP%\ipa_%RANDOM%"
mkdir "%TMP_DIR%" 2>nul

:: 解压原始 zip
echo 解压中...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TMP_DIR%' -Force"

:: 查找 Runner.app
for /d %%i in ("%TMP_DIR%\**\Runner.app") do set "APP_PATH=%%i"

if not defined APP_PATH (
    echo 错误: 在 zip 中找不到 Runner.app
    pause
    exit /b 1
)

echo 找到: %APP_PATH%

:: 打包 Payload 结构
set "PAYLOAD_DIR=%TMP_DIR%\Payload"
mkdir "%PAYLOAD_DIR%" 2>nul
move "%APP_PATH%" "%PAYLOAD_DIR%\" >nul 2>&1
if not exist "%PAYLOAD_DIR%\Runner.app" (
    echo 尝试复制...
    xcopy "%APP_PATH%" "%PAYLOAD_DIR%\Runner.app\" /E /I /Q
)

:: 生成 IPA
set "IPA_FILE=%OUT_DIR%Runner.ipa"
echo 生成 IPA...
powershell -Command "Compress-Archive -Path '%PAYLOAD_DIR%' -DestinationPath '%IPA_FILE%' -Force"

:: 清理
rmdir /s /q "%TMP_DIR%" 2>nul

echo.
echo === 完成 ===
echo IPA: %IPA_FILE%
echo.
echo 用 3uTools 打开此 IPA 即可安装到 iPhone
pause
