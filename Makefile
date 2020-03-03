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
	[ -e ppc64le ] && rm ppc64le
ppc64le: | docker
	if docker run --rm -it $@/centos:7 uname &> /dev/null; then \
		touch $@; \
	else \
		$(MAKE) qemu-user-static && touch $@ || exit 1; \
	fi
####################################
# Sources
####################################
serve:
	mkdir serve
serve/Miniconda3-4.7.12.1-Linux-x86_64.sh: | serve curl
	curl -sL https://repo.anaconda.com/miniconda/Miniconda3-4.7.12.1-Linux-x86_64.sh > $@.tmp && mv $@.tmp $@
serve/Miniconda3-4.7.12.1-Linux-ppc64le.sh: | serve curl
	curl -sL https://repo.anaconda.com/miniconda/Miniconda3-4.7.12.1-Linux-ppc64le.sh > $@.tmp && mv $@.tmp $@
serve/cudatoolkit-%: | serve curl
	curl -sL https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le/$(notdir $@) > $@.tmp && mv $@.tmp $@
serve/tensorflow-base-%: | serve curl
	curl -sL https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le/$(notdir $@) > $@.tmp && mv $@.tmp $@
serve/nccl-%: | serve curl
	curl -sL https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le/$(notdir $@) > $@.tmp && mv $@.tmp $@
serve/tensorrt-%: | serve curl
	curl -sL https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le/$(notdir $@) > $@.tmp && mv $@.tmp $@
serve/cudnn-%: | serve curl
	curl -sL https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le/$(notdir $@) > $@.tmp && mv $@.tmp $@
serve/torchvision-base-%: | serve curl
	curl -sL https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le/$(notdir $@) > $@.tmp && mv $@.tmp $@
serve/pytorch-base-%: | serve curl
	curl -sL https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le/$(notdir $@) > $@.tmp && mv $@.tmp $@
#serve/powerai: | serve wget
#        wget -e robots=off -np -nH --cut-dirs=8 -P serve/powerai.tmp -A '*.bz2' -r -L https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le/
#        mv $@.tmp $@
#PPCP = $(shell echo serve/cudatoolkit-{10.1.105-446.8cc2201,10.1.168-533.g8d035fd,10.1.243-616.gc122b8b}.tar.bz2 serve/tensorflow-base-{1.15.0-gpu_py36_590d6ee_64210.g4a039ec,1.15.0-gpu_py37_590d6ee_64210.g4a039ec,2.1.0-gpu_py36_e5bf8de_72635.gf8ef88c,2.1.0-gpu_py37_e5bf8de_72635.gf8ef88c}.tar.bz2)

.PHONY: downloads
downloads: $(shell echo serve/Miniconda3-4.7.12.1-Linux-{x86_64,ppc64le}.sh $(PPC15))
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
BASE := $(shell echo {,ppc64le-}{centos7,ubuntu16.04})
BASE_TEST = docker run --rm -it $(ORG)/tacc-ml:$@ bash -c 'echo $$CFLAGS | grep "pipe" && ls /etc/$@-release'

containers/extras/qemu-ppc64le-static: /usr/bin/qemu-ppc64le-static
	cp $< $@
%: containers/% serve/Miniconda3-4.7.12.1-Linux-x86_64.sh server_pid | docker
	$(BUILD) --build-arg FLAGS="$(AMD)" --build-arg IMGP="" --build-arg MCF="$(notdir $(word 2,$^))" ./containers &> $@.log
	$(PUSHC)
	touch $@
ppc64le-%: containers/% serve/Miniconda3-4.7.12.1-Linux-ppc64le.sh server_pid ppc64le | docker
	$(BUILD) --build-arg FLAGS="$(PPC)" --build-arg IMGP="ppc64le/" --build-arg MCF="$(notdir $(word 2,$^))" ./containers &> $@.log
	$(PUSHC)
	touch $@
base-images: $(BASE)
	touch $@
	$(MAKE) halt

.PHONY:clean-base
clean-base: | docker
	for img in $(BASE); do docker rmi $(ORG)/tacc-ml:$$img; rm -f $$img $$img.log; done
	[ -e base-images ] && rm base-images
	$(MAKE) halt

####################################
# ML Images
####################################
#BUILD_ML = docker build --build-arg ORG=$(ORG) --build-arg VER=$(VER) --build-arg REL=$(@) -t $(ORG)/tacc-ml:$@ -f $(word 2,$^)
#ML := $(shell echo {ubuntu16.04,centos7}-{cuda9-tf1.14,cuda10-tf1.15,cuda10-tf2.0}-pt1.3 ppc64le-{ubuntu16.04,centos7}-cuda10-tf1.15-pt1.2)
ML := $(shell echo {ubuntu16.04,centos7}-{cuda9-tf1.14,cuda10-tf1.15,cuda10-tf2.1}-pt1.3 ppc64le-{ubuntu16.04,centos7}-cuda10-tf1.15-pt1.2)
ML_TEST = docker run --rm -it $(ORG)/tacc-ml:$@ bash -c 'ls /etc/$@-release'
##### x86 images ####################
%-cuda9-tf1.14-pt1.3: containers/tf-conda % | docker
	$(BUILD) --build-arg FROM_TAG="$(word 2,$^)" --build-arg TF="1.14" --build-arg CV="10" --build-arg PT="1.3" ./containers &> $@.log
	$(PUSHC)
	touch $@
%-cuda10-tf1.15-pt1.3: containers/tf-conda % | docker
	$(BUILD) --build-arg FROM_TAG="$(word 2,$^)" --build-arg TF="1.15" --build-arg CV="10.2" --build-arg PT="1.3" ./containers &> $@.log
	$(PUSHC)
	touch $@
%-cuda10-tf2.1-pt1.3: containers/tf-conda % | docker
	$(BUILD) --build-arg FROM_TAG="$(word 2,$^)" --build-arg TF="2.1" --build-arg CV="10.2" --build-arg PT="1.3" ./containers &> $@.log
	$(PUSHC)
	touch $@
##### ppc images ####################
PPC15=$(shell echo serve/{tensorflow-base-1.15.2-gpu_py37_5d80e1e_64318.g33ef15a,cudatoolkit-10.1.243-616.gc122b8b,nccl-2.4.8-586.gdba67b7,tensorrt-6.0.1.5-py37_628.g4ac44fb,cudnn-7.6.3_10.1-590.g5627c5e,pytorch-base-1.2.0-gpu_py37_20251.ga479d1e}.tar.bz2)
.PRECIOUS: $(PPC15)
ppc64le-%-cuda10-tf1.15-pt1.2: containers/tf-ppc64le ppc64le-% ppc64le $(PPC15) | server_pid docker
	$(BUILD) --build-arg FROM_TAG="$(word 2,$^)" --build-arg TF="1.15" --build-arg CV="10.2" --build-arg PT="1.2" --build-arg PPCP="$(notdir $(PPC15))" ./containers &> $@.log
	$(PUSHC)
	touch $@
#ppc64le-%-cuda10-tf2.1-pt1.3: containers/tf-ppc64le ppc64le-% ppc64le $(PPCP) | docker
#	$(BUILD) --build-arg FROM_TAG="$(word 2,$^)" --build-arg TF="2.1" --build-arg CV="10.2" --build-arg PT="1.3" ./containers &> $@.log
#	$(PUSH)
#	touch $@

ml-images: $(ML)
	$(MAKE) halt
	touch $@

.PHONY:clean-ml
clean-ml: | docker
	for img in $(ML); do docker rmi -f $(ORG)/tacc-ml:$$img; rm -f $$img $$img.log; done
	[ -e ml-images ] && rm ml-images
	$(MAKE) halt

####################################
# Application Images
####################################

all: ml-images
	docker system prune

clean: clean-base clean-mpi | docker
	docker system prune
