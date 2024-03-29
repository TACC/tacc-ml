.PHONY: build test docker help stage release clean latest
ifndef VERBOSE
.SILENT: build test docker help stage release clean latest
endif

SHELL = bash

VER := $(shell cat VERSION)
ORG := tacc
PUSH ?= 0

####################################
# Sanity checks
####################################
PROGRAMS := curl git docker python ar
.PHONY: $(PROGRAMS)
.SILENT: $(PROGRAMS)

docker:
	docker info 1> /dev/null 2> /dev/null && \
	if [ ! $$? -eq 0 ]; then \
		echo "\n[ERROR] Could not communicate with docker daemon. You may need to run with sudo.\n"; \
		exit 1; \
	fi
wget python curl:
	$@ -h &> /dev/null; \
	if [ ! $$? -eq 0 ]; then \
		echo "[ERROR] $@ does not seem to be on your path. Please install $@"; \
		exit 1; \
	fi
git:
	$@ -h &> /dev/null; \
	if [ ! $$? -eq 129 ]; then \
		echo "[ERROR] $@ does not seem to be on your path. Please install $@"; \
		exit 1; \
	fi
####################################
# Multi-arch stuff
####################################
.SILENT: qemu-user-static ppc64le stop_qemu
.PHONY: stop_qemu
qemu-user-static: | docker
	echo "Starting qemu-user-static"
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes &> /dev/null
	touch $@
stop_qemu:
	if [ -e qemu-user-static ]; then \
		docker run --rm --privileged multiarch/qemu-user-static --reset &> /dev/null \
		&& rm qemu-user-static; \
	fi
	if [ -e ppc64le ]; then rm ppc64le; fi
ppc64le: | docker
	if docker run --rm -it --platform linux/ppc64le centos:7 uname &> /dev/null; then \
		touch $@; \
	else \
		$(MAKE) qemu-user-static && touch $@ || exit 1; \
	fi
####################################
# Sources
####################################
serve:
	mkdir serve
serve/Miniconda3-py37_4.11.0-Linux-x86_64.sh: | serve curl
	curl -sL https://repo.anaconda.com/miniconda/Miniconda3-py37_4.11.0-Linux-x86_64.sh > $@.tmp && mv $@.tmp $@
serve/Miniconda3-py39_4.11.0-Linux-x86_64.sh: | serve curl
	curl -sL https://repo.anaconda.com/miniconda/Miniconda3-py39_4.11.0-Linux-x86_64.sh > $@.tmp && mv $@.tmp $@
serve/Miniconda3-py37_4.11.0-Linux-ppc64le.sh: | serve curl
	curl -sL https://repo.anaconda.com/miniconda/Miniconda3-py37_4.11.0-Linux-ppc64le.sh > $@.tmp && mv $@.tmp $@
serve/Miniconda3-py39_4.11.0-Linux-ppc64le.sh: | serve curl
	curl -sL https://repo.anaconda.com/miniconda/Miniconda3-py39_4.11.0-Linux-ppc64le.sh > $@.tmp && mv $@.tmp $@
serve/Miniforge3-4.11.0-4-Linux-x86_64.sh: | serve curl
	curl -sL https://github.com/conda-forge/miniforge/releases/download/4.11.0-4/Miniforge3-4.11.0-4-Linux-x86_64.sh > $@.tmp && mv $@.tmp $@
serve/Miniforge3-4.11.0-4-Linux-ppc64le.sh: | serve curl
	curl -sL https://github.com/conda-forge/miniforge/releases/download/4.11.0-4/Miniforge3-4.11.0-4-Linux-ppc64le.sh > $@.tmp && mv $@.tmp $@

.PHONY: downloads
downloads: $(shell echo serve/Miniforge3-4.11.0-4-Linux-{x86_64,ppc64le}.sh serve/Miniconda3-py39_4.11.0-Linux-ppc64le.sh)
####################################
# File server
####################################
.SILENT: server_pid stop_server
HOST := $(shell [ $$(uname) == "Darwin" ] && echo host.docker.internal || echo $$(hostname -I | cut -f 2 -d ' '))
.PRECIOUS: server_pid
server_pid: | serve python
	cd serve \
	&& if python -V 2>&1 | grep -q "Python 2"; then \
		echo "Starting python2 file server"; \
		python -m SimpleHTTPServer 3333 &> /dev/null & echo $$! | tee ../$@; \
	else \
		echo "Starting python3 file server"; \
		python -m http.server 3333 &> /dev/null & echo $$! | tee ../$@; \
	fi

.PHONY: stop_server
stop_server:
	if [ -e server_pid ]; then \
		kill -9 $$(cat server_pid) \
		&& rm server_pid \
		&& echo "Stopped file server"; \
	fi
####################################
# Stop Daemons
####################################
halt: stop_server stop_qemu
####################################
# BUILD Commands
####################################
BUILD = docker build --build-arg HOST=$(HOST) --build-arg ORG=$(ORG) --build-arg VER=$(VER) --build-arg REL=$(@) -t $(ORG)/tacc-ml:$@ -f $(word 1,$^)
PUSHC = [ "$(PUSH)" -eq "1" ] && docker push $(ORG)/tacc-ml:$@ || echo "not pushing $@"
####################################
# CFLAGS
####################################
AMD := -O2 -pipe -march=x86-64 -ftree-vectorize -mtune=core-avx2
PPC := -mcpu=power9 -O2 -pipe

####################################
# Base Images
####################################
BASE_AMD64 := $(shell echo {centos7,ubuntu20.04})
BASE_PPC64LE := $(shell echo ppc64le-{centos7,ubuntu20.04})

containers/extras/qemu-ppc64le-static: /usr/bin/qemu-ppc64le-static
	cp $< $@

%: containers/% serve/Miniforge3-4.11.0-4-Linux-x86_64.sh server_pid | docker
	$(BUILD) --build-arg FLAGS="$(AMD)" --build-arg MCF="$(notdir $(word 2,$^))" --platform linux/amd64 ./containers &> $@.log
	touch $@
ppc64le-%: containers/% serve/Miniconda3-py39_4.11.0-Linux-ppc64le.sh server_pid ppc64le | docker
	$(BUILD) --build-arg FLAGS="$(PPC)" --build-arg MCF="$(notdir $(word 2,$^))" --platform linux/ppc64le ./containers &> $@.log
	touch $@
base-images: $(BASE_AMD64) $(BASE_PPC64LE)
	touch $@
	$(MAKE) halt
base-images-amd64: $(BASE_AMD64)
	touch $@
	$(MAKE) halt
base-images-ppc64le: $(BASE_PPC64LE)
	touch $@
	$(MAKE) halt

.PHONY: clean-base clean-base-amd64 clean-base-ppc64le
clean-base: | clean-base-amd64 clean-base-ppc64le
clean-base-amd64: | docker
	for img in $(BASE_AMD64); do docker rmi $(ORG)/tacc-ml:$$img; rm -f $$img $$img.log; done
	if [ -e base-images-amd64 ]; then rm base-images-amd64; fi
	$(MAKE) halt
clean-base-ppc64le: | docker
	for img in $(BASE_PPC64LE); do docker rmi $(ORG)/tacc-ml:$$img; rm -f $$img $$img.log; done
	if [ -e base-images-ppc64le ]; then rm base-images-ppc64le; fi
	$(MAKE) halt

####################################
# ML Images
####################################
ML_AMD64 := $(shell echo {ubuntu20.04,centos7}-cuda11-tf2.6-pt1.10)
ML_PPC64LE := $(shell echo ppc64le-{ubuntu20.04,centos7}-cuda11-tf2.7-pt1.10)

##### x86 images ####################
%-cuda11-tf2.6-pt1.10: containers/tf-conda % | docker
	$(BUILD) --build-arg FROM_TAG="$(word 2,$^)" --build-arg TF="2.6" --build-arg CV="11.2" --build-arg PT="1.10" ./containers &> $@.log
	$(PUSHC)
	touch $@

##### ppc images ####################
ppc64le-%-cuda11-tf2.7-pt1.10: containers/tf-ppc64le ppc64le-% ppc64le | docker
	$(BUILD) --build-arg FROM_TAG="$(word 2,$^)" --build-arg TF="2.7" --build-arg CV="11.2" --build-arg PT="1.10" ./containers &> $@.log
	$(PUSHC)
	touch $@

ml-images: $(ML_AMD64) $(ML_PPC64LE)
	$(MAKE) halt
	touch $@
ml-images-amd64: $(ML_AMD64)
	$(MAKE) halt
	touch $@
ml-images-ppc64le: $(ML_PPC64LE)
	$(MAKE) halt
	touch $@

.PHONY: clean-ml clean-ml-amd64 clean-ml-ppc64le
clean-ml: | clean-ml-amd64 clean-ml-ppc64le
clean-ml-amd64: | docker
	for img in $(ML_AMD64); do docker rmi -f $(ORG)/tacc-ml:$$img; rm -f $$img $$img.log; done
	if [ -e ml-images-amd64 ]; then rm ml-images-amd64; fi
	$(MAKE) halt
clean-ml-ppc64le: | docker
	for img in $(ML_PPC64LE); do docker rmi -f $(ORG)/tacc-ml:$$img; rm -f $$img $$img.log; done
	if [ -e ml-images-ppc64le ]; then rm ml-images-ppc64le; fi
	$(MAKE) halt

####################################
# Application Images
####################################

all: ml-images
	docker system prune

clean: clean-base clean-ml | docker
	docker system prune
