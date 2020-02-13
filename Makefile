.PHONY: build test docker help stage release clean latest
ifndef VERBOSE
.SILENT: build test docker help stage release clean latest
endif

SHELL = bash

VER := $(shell cat VERSION)
ORG := tacc
ALL := $(BASE) $(MPI)
EDR := maverick wrangler hikari maverick2
OPA := stampede2
SYS := $(EDR) $(OPA) ls5

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
python curl:
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
stop_qemu: qemu-user-static ppc64le
	docker run --rm --privileged multiarch/qemu-user-static --reset &> /dev/null
	rm $^
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
.PHONY: downloads
downloads: $(shell echo serve/Miniconda3-4.7.12.1-Linux-{x86_64,ppc64le}.sh serve/qemu)
####################################
# File server
####################################
.SILENT: server_pid stop_server
HOST := $(shell [ $$(uname) == "Darwin" ] && echo host.docker.internal || echo $$(hostname -I | cut -f 2 -d ' '))
server_pid: serve | python
	cd serve \
	&& if python -V 2>&1 | grep -q "Python 2"; then \
		echo "Starting python2 file server"; \
		python -m SimpleHTTPServer 3333 &> /dev/null & echo $$! | tee ../$@; \
	else \
		echo "Starting python3 file server"; \
		python -m http.server 3333 &> /dev/null & echo $$! | tee ../$@; \
	fi

.PHONY: stop_server
stop_server: server_pid
	kill -9 $(shell cat $<) && rm $<
	echo "Stopped file server"
####################################
# Stop Daemons
####################################
halt: stop_server stop_qemu
####################################
# BUILD Commands
####################################
BUILD = docker build --build-arg HOST=$(HOST) --build-arg ORG=$(ORG) --build-arg VER=$(VER) --build-arg REL=$(@) -t $(ORG)/tacc-ml:$@ -f $(word 1,$^)
PUSH = docker push $(ORG)/tacc-ml:$@
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
	touch $@
ppc64le-%: containers/% serve/Miniconda3-4.7.12.1-Linux-ppc64le.sh server_pid ppc64le | docker
	$(BUILD) --build-arg FLAGS="$(PPC)" --build-arg IMGP="ppc64le/" --build-arg MCF="$(notdir $(word 2,$^))" ./containers &> $@.log
	touch $@
base-images: $(BASE)
	touch $@
	$(MAKE) halt

.PHONY:clean-base
clean-base: | docker
	for img in $(BASE); do docker rmi $(ORG)/tacc-ml:$$img; rm $$img $$img.log; done

####################################
# ML Images
####################################
#BUILD_ML = docker build --build-arg ORG=$(ORG) --build-arg VER=$(VER) --build-arg REL=$(@) -t $(ORG)/tacc-ml:$@ -f $(word 2,$^)
ML := $(shell echo {ubuntu16.04,centos7}-{cuda9-tf1.14,cuda10-tf1.15,cuda10-tf2.0}-pt1.3 ppc64le-{ubuntu16.04,centos7}-cuda10-tf1.15-pt1.2)
ML_TEST = docker run --rm -it $(ORG)/tacc-ml:$@ bash -c 'ls /etc/$@-release'

%-cuda9-tf1.14-pt1.3: containers/tf-conda % | docker
	$(BUILD) --build-arg FROM_TAG="$(word 2,$^)" --build-arg TF="1.14" --build-arg CV="9" --build-arg PT="1.3" ./containers &> $@.log
	$(PUSH)
	touch $@
%-cuda10-tf1.15-pt1.3: containers/tf-conda % | docker
	$(BUILD) --build-arg FROM_TAG="$(word 2,$^)" --build-arg TF="1.15" --build-arg CV="10" --build-arg PT="1.3" ./containers &> $@.log
	$(PUSH)
	touch $@
%-cuda10-tf2.0-pt1.3: containers/tf-conda % | docker
	$(BUILD) --build-arg FROM_TAG="$(word 2,$^)" --build-arg TF="2.0" --build-arg CV="10" --build-arg PT="1.3" ./containers &> $@.log
	$(PUSH)
	touch $@
ppc64le-%-cuda10-tf1.15-pt1.2: containers/tf-ppc64le ppc64le-% ppc64le | docker
	$(BUILD) --build-arg FROM_TAG="$(word 2,$^)" --build-arg TF="1.15" --build-arg CV="10" --build-arg PT="1.2" ./containers &> $@.log
	$(PUSH)
	touch $@

ml-images: $(ML)
	$(MAKE) halt
	touch $@

.PHONY:clean-base
clean-ml: | docker
	for img in $(ML); do docker rmi $(ORG)/tacc-ml:$$img; rm $$img $$img.log; done

####################################
# Application Images
####################################

all: base-images mpi-images
	docker system prune

clean: clean-mpi clean-base | docker
	docker system prune
