@echo off
echo ========================================
echo Highlights App
echo ========================================
echo.

REM Check if Java is installed
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Java is not installed or not in PATH
    echo Please install Java JDK 11 or higher
    echo Download from: https://adoptium.net/
    pause
    exit /b 1
)

echo Java detected successfully!
echo.

REM Check if JAR file exists
if not exist "target\HighlightsApp-1.0.0.jar" (
    echo Building the application...
    echo This may take a few minutes on first run...
    call mvn clean package
    if %errorlevel% neq 0 (
        echo.
        echo ERROR: Build failed!
        echo Make sure Maven is installed and in PATH
        pause
        exit /b 1
    )
)

echo Starting Highlights App...
echo.

REM Run with proper module path for JavaFX
java --module-path target\libs --add-modules javafx.controls,javafx.fxml -cp "target\HighlightsApp-1.0.0.jar;target\libs\*" com.Highlights.Launcher

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Application failed to start!
    echo.
    echo Trying alternative method...
    java -jar target\HighlightsApp-1.0.0.jar
    
    if %errorlevel% neq 0 (
        echo.
        echo ERROR: Both methods failed!
        echo Please try: mvn javafx:run
        pause
    )
)
