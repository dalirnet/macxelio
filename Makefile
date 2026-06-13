.PHONY: build
build:
	sh dev.sh

.PHONY: release
release:
	sh dev.sh release

.PHONY: publish
publish:
	sh dev.sh publish

.PHONY: run
run: build
	killall Macxelio 2>/dev/null || true
	sleep 0.5
	open build/Macxelio.app

.PHONY: format
format:
	pnpx prettier -w docs
	swift-format format -i -r --configuration .swift-format Sources

.PHONY: clean
clean:
	rm -rf build .build
