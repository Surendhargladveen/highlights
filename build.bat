@echo off
echo ============================================
echo Highlights - Build Script
echo ============================================
echo.

echo Checking prerequisites...
echo.

REM Check Java
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Java not found!
    echo Please install Java JDK 11+ from https://adoptium.net/
    pause
    exit /b 1
)
echo [OK] Java detected

REM Check Maven
mvn -version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Maven not found!
    echo Please install Maven from https://maven.apache.org/
    pause
    exit /b 1
)
echo [OK] Maven detected
echo.

echo Starting build process...
echo.

REM Clean previous builds
echo [1/3] Cleaning previous builds...
call mvn clean
if %errorlevel% neq 0 (
    echo [ERROR] Clean failed!
    pause
    exit /b 1
)
echo [OK] Clean completed
echo.

REM Compile and package
echo [2/3] Compiling and packaging application...
call mvn package
if %errorlevel% neq 0 (
    echo [ERROR] Build failed!
    pause
    exit /b 1
)
echo [OK] Build completed
echo.

REM Verify output
echo [3/3] Verifying output...
if exist "target\HighlightsApp-1.0.0.jar" (
    echo [OK] JAR file created successfully!
    echo.
    echo ============================================
    echo Build Complete!
    echo ============================================
    echo.
    echo Output file: target\HighlightsApp-1.0.0.jar
    echo.
    echo To run the application:
    echo   - Option 1: Double-click run.bat
    echo   - Option 2: java -jar target\HighlightsApp-1.0.0.jar
    echo   - Option 3: mvn javafx:run
    echo.
) else (
    echo [ERROR] JAR file not found!
    echo Build may have failed. Check the error messages above.
    pause
    exit /b 1
)

pause
