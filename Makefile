SCRIPTS := $(shell awk '/#!\/usr\/bin\/env (ba)?sh/&&FNR==1{print FILENAME}' $(shell git ls-files))
GODEPS := $(shell git ls-files '*.go' go.mod go.sum)

VSN ?= $(shell git describe --dirty)
VSNHASH ?= $(shell git rev-parse --verify HEAD)
LDFLAGS ?= -ldflags "-X main.Version=$(VSN) -X main.VersionHash=$(VSNHASH)"

undocker: $(GODEPS) ## builds binary for the current architecture
	go build $(LDFLAGS) -o $@

.PHONY: test
test: coverage.out

.PHONY: lint
lint:
	go vet ./...
	staticcheck -f stylish ./...
	shellcheck $(SCRIPTS)
	shfmt -w -i 4 $(SCRIPTS)
	git diff --exit-code

.INTERMEDIATE: coverage.out
coverage.out: $(GODEPS)
	go test -race -cover -coverprofile $@ ./...

coverage.html: coverage.out
	go tool cover -html=$< -o $@

.PHONY: clean
clean:
	rm -f undocker coverage.html

TEST_IMAGES = busybox-glibc_65ad0d468eb1

.PHONY: test-integration
test-integration: $(foreach IMG,$(TEST_IMAGES),test-integration-$(IMG))

ifeq ($(shell uname -s),Darwin)
    TAR := gtar
else
    TAR := tar
endif

define TEST_RULES
.PHONY: test-integration-$(IMG)
test-integration-$(IMG): undocker t/$(IMG).tar t/$(IMG).txt
	./undocker t/$(IMG).tar - | $$(TAR) -tv > t/$(IMG)-got.txt
	diff -u t/$(IMG).txt t/$(IMG)-got.txt
	@echo "$(IMG) success"

t/$(IMG).tar:
	wget -O $$@ https://git.jakstys.lt/api/packages/motiejus/generic/undocker-tests/0/$(IMG).tar
endef
$(foreach IMG,$(TEST_IMAGES),$(eval $(TEST_RULES)))
