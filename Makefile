DAMLSDK_VERSION ?= 2.9.5
DAMLSDK_IMAGE ?= digitalasset/daml-sdk:$(DAMLSDK_VERSION)
DAMLSDK_WORKDIR ?= /work/cmtat-canton
DOCKER_RUN_DAML = docker run --rm -u 0:0 -e HOME=/tmp -e DAML_HOME=/tmp/.daml -v "$$(pwd)":/work -w $(DAMLSDK_WORKDIR) $(DAMLSDK_IMAGE)
PROJECT_SDK_VERSION ?= 2.10.4

.PHONY: daml-build-docker daml-test-docker

daml-build-docker:
	$(DOCKER_RUN_DAML) sh -lc "daml install $(PROJECT_SDK_VERSION) && daml build"

daml-test-docker:
	$(DOCKER_RUN_DAML) sh -lc "daml install $(PROJECT_SDK_VERSION) && daml test"
