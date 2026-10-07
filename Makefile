FLUTTER=C:\flutter_windows\flutter\bin\flutter.bat

.PHONY: run build clean run-windows build-windows

# Default to windows to avoid Gradle
run: run-windows

build: build-windows

run-windows:
	$(FLUTTER) run -d windows

build-windows:
	$(FLUTTER) build windows

clean:
	$(FLUTTER) clean
