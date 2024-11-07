IMAGE_DIRS := $(shell find . -type d -depth 1 | sed 's/^\.\///')

.PHONY: archives
archives: $(IMAGE_DIRS).tar

.PHONY: clean
clean:
	rm -f *.tar

$(IMAGE_DIRS).tar: IMG = $(basename $@)
$(IMAGE_DIRS).tar:
	podman build -t $(IMG):$$(git -C $(IMG) describe --always --dirty --tags || echo undefined) --arch=amd64 $(IMG)
	podman save -o $(IMG).tar $(IMG):$$(git -C $(IMG) describe --always --dirty --tags || echo undefined)
