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
ar:
	$@ -h &> /dev/null; \
	if [ ! $$? -eq 1 ]; then \
		echo "[ERROR] $@ does not seem to be on your path. Please install $@"; \
		exit 1; \
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
serve/bazel-0.25.2-installer-linux-x86_64.sh: | serve curl
	curl -sL https://github.com/bazelbuild/bazel/releases/download/0.25.2/bazel-0.25.2-installer-linux-x86_64.sh > $@.tmp && mv $@.tmp $@
serve/bazel-0.11.1-installer-linux-x86_64.sh: | serve curl
	curl -sL https://github.com/bazelbuild/bazel/releases/download/0.11.1/bazel-0.11.1-installer-linux-x86_64.sh > $@.tmp && mv $@.tmp $@
serve/bazel-0.25.2-dist.zip: | serve curl
	curl -sL https://github.com/bazelbuild/bazel/releases/download/0.25.2/bazel-0.25.2-dist.zip > $@.tmp && mv $@.tmp $@
serve/bazel-0.11.1-dist.zip: | serve curl
	curl -sL https://github.com/bazelbuild/bazel/releases/download/0.11.1/bazel-0.11.1-dist.zip > $@.tmp && mv $@.tmp $@
serve/bazel-license.txt: | serve curl
	curl -sL https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE > $@.tmp && mv $@.tmp $@
serve/tensorflow-1.8.0.tar.gz: | serve git
	curl -sL https://github.com/tensorflow/tensorflow/archive/v1.8.0.tar.gz > $@.tmp && mv $@.tmp $@
serve/tensorflow-1.15.2.tar.gz: | serve git
	curl -sL https://github.com/tensorflow/tensorflow/archive/v1.15.2.tar.gz > $@.tmp && mv $@.tmp $@
serve/tensorflow-2.1.0.tar.gz: | serve git
	curl -sL https://github.com/tensorflow/tensorflow/archive/v2.1.0.tar.gz > $@.tmp && mv $@.tmp $@
serve/osu-micro-benchmarks-5.4.4.tar.gz: | serve git
	curl -s http://mvapich.cse.ohio-state.edu/download/mvapich/$(notdir $@) > $@.tmp && mv $@.tmp $@
serve/mvapich2-2.3.1.tar.gz: | serve git
	curl -s http://mvapich.cse.ohio-state.edu/download/mvapich/mv2/$(notdir $@) > $@.tmp && mv $@.tmp $@
serve/nccl-2.5.7-1.tar.gz: | serve curl
	curl -sL https://github.com/NVIDIA/nccl/archive/v2.5.7-1.tar.gz > $@.tmp && mv $@.tmp $@
serve/qemu: | serve ar curl
	# Not necessary on docker desktop
	rm -rf serve/tmp*
	curl -s http://security.ubuntu.com/ubuntu/pool/universe/q/qemu/qemu-user-static_2.5+dfsg-5ubuntu10.42_amd64.deb > serve/tmp.deb
	mkdir serve/tmp && cd serve/tmp && ar x ../tmp.deb && rm ../tmp.deb
	cd serve/tmp && rm debian-binary control.tar.gz && tar -xf data.tar.xz usr/bin
	mv serve/tmp/usr/bin/* serve/tmp && rm -rf serve/tmp/{usr,data.tar.xz}
	mv serve/tmp $@
.PHONY: downloads
downloads: $(shell echo serve/Miniconda3-4.7.12.1-Linux-{x86_64,ppc64le}.sh serve/bazel-{0.25.2,0.11.1}-{installer-linux-x86_64.sh,dist.zip} serve/tensorflow-{1.8.0,1.15.2,2.1.0}.tar.gz serve/osu-micro-benchmarks-5.4.4.tar.gz serve/mvapich2-2.3.1.tar.gz serve/qemu)

####################################
# File server
####################################
.SILENT: server_pid stop_server
server_pid: | downloads python
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
# BUILD Commands
####################################
BUILD = docker build --build-arg ORG=$(ORG) --build-arg VER=$(VER) --build-arg REL=$(@) -t $(ORG)/tacc-ml:$@ -f $(word 2,$^)
PUSH = docker push $(ORG)/$@:$(VER)
####################################
# CFLAGS
####################################
AMD := -O2 -pipe -march=x86-64 -ftree-vectorize -mtune=core-avx2
PPC := -mcpu=power9 -O2 -pipe

####################################
# Base Images
####################################
BASE := $(shell echo {ubuntu18.04,centos7}-cuda{9.2,10.1}-x86_64 {ubuntu18.04,centos7}-cuda10.1-ppc64le)
BASE_TEST = docker run --rm -it $(ORG)/tacc-ml:$@ bash -c 'echo $$CFLAGS | grep "pipe" && ls /etc/$@-release'

10.1-cudnn7-devel-centos7 10.1-cudnn7-devel-ubuntu18.04 9.2-cudnn7-devel-centos7 9.2-cudnn7-devel-ubuntu18.04: | docker
	docker pull nvidia/cuda:$@
	touch $@
ppc64le-10.1-cudnn7-devel-centos7 ppc64le-10.1-cudnn7-devel-ubuntu18.04: | docker
	docker pull nvidia/cuda-ppc64le:$(subst ppc64le-,,$@)
	touch $@
%-cuda9.2-x86_64: 9.2-cudnn7-devel-% containers/% server_pid
	$(BUILD) --build-arg FLAGS="$(AMD)" --build-arg FROM_TAG="$<" --build-arg FROM_IMG="nvidia/cuda" ./containers &> $@.log
	$(BASE_TEST) >> $@.log 2>&1
	#$(PUSH) >> $@.log 2>&1
	touch $@
%-cuda10.1-x86_64: 10.1-cudnn7-devel-% containers/% server_pid
	$(BUILD) --build-arg FLAGS="$(AMD)" --build-arg FROM_TAG="$<" --build-arg FROM_IMG="nvidia/cuda" ./containers &> $@.log
	$(BASE_TEST) >> $@.log 2>&1
	#$(PUSH) >> $@.log 2>&1
	touch $@
%-cuda10.1-ppc64le: 10.1-cudnn7-devel-% containers/% server_pid
	$(BUILD) --build-arg FLAGS="$(PPC)" --build-arg FROM_TAG="$<" --build-arg FROM_IMG="nvidia/cuda-ppc64le" ./containers &> $@.log
	$(BASE_TEST) >> $@.log 2>&1
	#$(PUSH) >> $@.log 2>&1
	touch $@
base-images: $(BASE)
	touch $@
	$(MAKE) stop_server

.PHONY:clean-base
clean-base: | docker
	for img in $(BASE); do docker rmi $(ORG)/tacc-ml:$$img; rm $$img; done

####################################
# ML Images
####################################
#BUILD_ML = docker build --build-arg ORG=$(ORG) --build-arg VER=$(VER) --build-arg REL=$(@) -t $(ORG)/tacc-ml:$@ -f $(word 2,$^)
ML := $(shell echo {ubuntu18.04,centos7}-cuda{9.2,10.1}-x86_64-tf{1.8.0,1.15.2,2.1.0} {ubuntu18.04,centos7}-cuda10.1-ppc64le-tf{1.8.0,1.15.2,2.1.0})
ML_TEST = docker run --rm -it $(ORG)/tacc-ml:$@ bash -c 'echo $$CFLAGS | grep "pipe" && ls /etc/$@-release'

%-tf1.8.0: % containers/tf-1.8-source server_pid
	$(BUILD) --build-arg FROM_TAG="$<" --build-arg TF_V="1.8.0" ./containers 
	$(ML_TEST)
	touch $@
ml-images: $(BASE)
	touch $@
	$(MAKE) stop_server

.PHONY:clean-base
clean-ml: | docker
	for img in $(ML); do docker rmi $(ORG)/tacc-ml:$$img; rm $$img; done
####################################
# Base Images
####################################
ubuntu16-cuda10.1-tf2.1.0:

####################################
# MPI Images
####################################
MPI := $(shell echo tacc-{ubuntu18,centos7}-mvapich2.3-{ib,psm2})
MPI_TEST = docker run --rm -it $(ORG)/$@:$(VER) bash -c 'which mpicc && ls /etc/$@-release'
# IB
%-mvapich2.3-ib: containers/%-mvapich2.3-ib | docker %
	$(BUILD) --build-arg FLAGS="$(TACC)" ./containers
	$(MPI_TEST)
	$(TAG)
	$(PUSH)
# PSM2
%-mvapich2.3-psm2: containers/%-mvapich2.3-psm2 | docker %
	$(BUILD) --build-arg FLAGS="$(TACC)" ./containers
	$(MPI_TEST)
	$(TAG)
	$(PUSH)
#docker tag $(ORG)/$@:$(VER) $(ORG)/$@:stampede2
#docker push $(ORG)/$@:stampede2
#	for sys in hikari maverick2 wrangler; do \
#		docker tag $(ORG)/$@:$(VER) $(ORG)/$@:$$sys \
#		&& docker push $(ORG)/$@:$$sys; \
#	done
mpi-images: $(MPI)

clean-mpi: | docker
	docker rmi $(ORG)/tacc-{ubuntu18,centos7}-mvapich2.3-{ib,psm2}:{$(VER),latest}
####################################
# CUDA Images
####################################


####################################
# Application Images
####################################

all: base-images mpi-images
	docker system prune

clean: clean-mpi clean-base | docker
	docker system prune
