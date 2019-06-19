SKIP_SQUASH?=1

.PHONY: build
build:

	SKIP_SQUASH=$(SKIP_SQUASH) hack/build.sh
.PHONY: test
test:
	SKIP_SQUASH=$(SKIP_SQUASH) TAG_ON_SUCCESS=$(TAG_ON_SUCCESS) TEST_MODE=true hack/build.sh

.PHONY: run
run:
	@@MAINDEV=`ip r | awk '/default/' | sed 's|.* dev \([^ ]*\).*|\1|'`; \
	MAINIP=`ip r | awk "/ dev $$MAINDEV .* src /" | sed 's|.* src \([^ ]*\).*$$|\1|'`; \
	MAINIP=172.17.0.2; \
	docker run -e OPENLDAP_HOST=$$MAINIP \
	    -e DEBUG=pleasedo \
	    -e LLNG_PUB_PORT=8080 \
	    --add-host=auth.demo.local:127.0.0.1 \
	    --add-host=portal.demo.local:127.0.0.1 \
	    --add-host=manager.demo.local:127.0.0.1 \
	    --add-host=reload.demo.local:127.0.0.1 \
	    --add-host=test1.demo.local:127.0.0.1 \
	    --add-host=test2.demo.local:127.0.0.1 \
	    -p 8080:8080 wsweet/lemon

.PHONY: themeddemo
themeddemo:
	@@MAINDEV=`ip r | awk '/default/' | sed 's|.* dev \([^ ]*\).*|\1|'`; \
	MAINIP=`ip r | awk "/ dev $$MAINDEV .* src /" | sed 's|.* src \([^ ]*\).*$$|\1|'`; \
	docker run -e OPENLDAP_HOST=$$MAINIP \
	    -e LEMON_CUSTOM_THEMES=git+ssh://some.private.git/Project/llng-themes-repo \
	    -e LLNG_PUB_PORT=8080 \
	    -e DEBUG=pleasedo -e HOME=/ -e GIT_SSH_PORT=2222 \
	    --add-host=auth.demo.local:127.0.0.1 \
	    --add-host=portal.demo.local:127.0.0.1 \
	    --add-host=manager.demo.local:127.0.0.1 \
	    --add-host=reload.demo.local:127.0.0.1 \
	    --add-host=test1.demo.local:127.0.0.1 \
	    --add-host=test2.demo.local:127.0.0.1 \
	    -p 8080:8080 wsweet/lemon

.PHONY: ocbuild
ocbuild: occheck
	oc process -f openshift/imagestream.yaml -p FRONTNAME=wsweet | oc apply -f-
	BRANCH=`git rev-parse --abbrev-ref HEAD`; \
	if test "$$GIT_DEPLOYMENT_TOKEN"; then \
	    oc process -f openshift/build-with-secret.yaml \
		-p "FRONTNAME=wsweet" \
		-p "GIT_DEPLOYMENT_TOKEN=$$GIT_DEPLOYMENT_TOKEN" \
		-p "LLNG_REPOSITORY_REF=$$BRANCH" \
		| oc apply -f-; \
	else \
	    oc process -f openshift/build.yaml \
		-p "FRONTNAME=wsweet" \
		-p "LLNG_REPOSITORY_REF=$$BRANCH" \
		| oc apply -f-; \
	fi

.PHONY: occheck
occheck:
	oc whoami >/dev/null 2>&1 || exit 42

.PHONY: occlean
occlean: occheck
	oc process -f openshift/run-ha.yaml -p FRONTNAME=wsweet | oc delete -f- || true
	oc process -f openshift/run-persistent.yaml -p FRONTNAME=wsweet | oc delete -f- || true
	oc process -f openshift/secret.yaml -p FRONTNAME=wsweet | oc delete -f- || true

.PHONY: ocdemoephemeral
ocdemoephemeral: ocbuild
	if ! oc describe secret openldap-wsweet >/dev/null 2>&1; then \
	    oc process -f openshift/secret.yaml -p FRONTNAME=wsweet | oc apply -f-; \
	fi
	oc process -f openshift/run-ephemeral.yaml -p FRONTNAME=wsweet | oc apply -f-

.PHONY: ocdemopersistent
ocdemopersistent: ocbuild
	if ! oc describe secret openldap-wsweet >/dev/null 2>&1; then \
	    oc process -f openshift/secret.yaml -p FRONTNAME=wsweet | oc apply -f-; \
	fi
	oc process -f openshift/run-persistent.yaml -p FRONTNAME=wsweet | oc apply -f-

.PHONY: ocdemo
ocdemo: ocdemoephemeral

.PHONY: ocprod
ocprod: ocbuild
	if ! oc describe secret openldap-wsweet >/dev/null 2>&1; then \
	    oc process -f openshift/secret-prod.yaml -p FRONTNAME=wsweet | oc apply -f-; \
	fi
	oc process -f openshift/run-ha.yaml -p FRONTNAME=wsweet | oc apply -f-

.PHONY: ocpurge
ocpurge: occlean
	oc process -f openshift/build.yaml -p FRONTNAME=wsweet | oc delete -f- || true
	oc process -f openshift/imagestream.yaml -p FRONTNAME=wsweet | oc delete -f- || true
