.PHONY: build
build:
	sh build.sh

.PHONY: release
release:
	sh build.sh release

.PHONY: run
run: build
	killall Macxelio 2>/dev/null || true
	sleep 0.5
	open build/Macxelio.app

.PHONY: format
format:
	swift-format format -i -r --configuration .swift-format Sources

.PHONY: clean
clean:
	rm -rf build .build
