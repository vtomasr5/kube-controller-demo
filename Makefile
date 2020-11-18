GOFILES:=$(shell find . -name '*.go' | grep -v -E '(./vendor)')

all: \
	bin/linux/reboot-agent \
	bin/linux/reboot-controller

images: GVERSION=$(shell $(CURDIR)/git-version.sh)
images: bin/linux/reboot-agent bin/linux/reboot-controller
	docker build -f Dockerfile-agent -t vtomasr5/demo-reboot-agent:$(GVERSION) .
	docker build -f Dockerfile-agent -t vtomasr5/demo-reboot-agent:latest .
	docker build -f Dockerfile-controller -t vtomasr5/demo-reboot-controller:$(GVERSION) .
	docker build -f Dockerfile-controller -t vtomasr5/demo-reboot-controller:latest .

push:
	docker push vtomasr5/demo-reboot-agent:$(GVERSION)
	docker push vtomasr5/demo-reboot-agent:latest
	docker push vtomasr5/demo-reboot-controller:$(GVERSION)
	docker push vtomasr5/demo-reboot-controller:latest

check:
	@find . -name vendor -prune -o -name '*.go' -exec gofmt -s -d {} +
	@go vet $(shell go list ./... | grep -v '/vendor/')
	@go test -v $(shell go list ./... | grep -v '/vendor/')

.PHONY: vendor
vendor:
	go mod vendor

clean:
	rm -rf bin

bin/%: LDFLAGS=-X github.com/vtomasr5/kube-controller-demo/common.Version=$(shell $(CURDIR)/git-version.sh) -extldflags "-static"
bin/%: $(GOFILES)
	mkdir -p $(dir $@)
	CGO_ENABLED=0 GOOS=$(word 1, $(subst /, ,$*)) GOARCH=amd64  go build -ldflags "$(LDFLAGS)" -o $@ github.com/vtomasr5/kube-controller-demo/$(notdir $@)

