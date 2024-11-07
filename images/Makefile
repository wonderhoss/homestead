IMAGE_DIRS := $(shell find . -type d -depth 1 | sed 's/^\.\///')

.PHONY: archives
archives: $(IMAGE_DIRS).tgz

.PHONY: clean
clean:
	rm -f *.tgz

$(IMAGE_DIRS).tgz: IMG = $(basename $@)
$(IMAGE_DIRS).tgz:
	echo "Building archive $(IMG) with tag $$(git -C $(IMG) describe --always --dirty --tags || echo undefined)"
	podman build -t $(IMG):$$(git -C $(IMG) describe --always --dirty --tags || echo undefined) --arch=amd64 $(IMG)
	podman save -o $(IMG).tar $(IMG):$$(git -C $(IMG) describe --always --dirty --tags || echo undefined)
	gzip < $(IMG).tar > $@
	rm $(IMG).tar
