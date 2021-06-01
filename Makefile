GODEPS = $(shell git ls-files '*.go' go.mod go.sum)
GOBIN = $(shell go env GOPATH)/bin/

undocker: $(GODEPS)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build

.PHONY: test
test:
	go test -race -cover ./...

.PHONY: lint
lint:
	$(GOBIN)staticcheck -f stylish ./...
	go vet ./...

.INTERMEDIATE: coverage.out
coverage.out: $(GODEPS)
	go test -coverprofile $@ ./...

coverage.html: coverage.out
	go tool cover -html=$< -o $@