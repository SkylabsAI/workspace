DOCKER_GHCR_REGISTRY = ghcr.io
DOCKER_GHCR_SKYLABS_FM = $(DOCKER_GHCR_REGISTRY)/skylabsai/skylabs-fm
DOCKER_GITLAB_REGISTRY = registry.gitlab.com
DOCKER_GITLAB_SKYLABS_FM = $(DOCKER_GITLAB_REGISTRY)/skylabs_ai/fm/skylabs-fm

### Docker login / logout

docker/github-login:
	@echo -n "Enter your GitHub login: "
	@read -r LOGIN; echo $$LOGIN > $@

docker/github-token:
	@echo "You need a GitHub personal access token (classic)."
	@echo "See https://github.com/settings/tokens."
	@echo "Select write:packages permission/scope when creating the token"
	@echo -n "Enter your personal access token: "
	@read -r TOKEN; echo $$TOKEN > $@

.PHONY: docker-login
docker-login: docker/github-login docker/github-token
	@docker login -u $$(cat $<) --password-stdin $(DOCKER_GHCR_REGISTRY) < docker/github-token

.PHONY: docker-logout
docker-logout:
	@docker logout $(DOCKER_GHCR_REGISTRY)

docker/gitlab-login:
	@echo -n "Enter your GitLab login: "
	@read -r LOGIN; echo $$LOGIN > $@

docker/gitlab-token:
	@echo "You need a GitLab personal access token."
	@echo "See https://gitlab.com/-/user_settings/personal_access_tokens"
	@echo -n "Enter your personal access token: "
	@read -r TOKEN; echo $$TOKEN > $@

.PHONY: docker-gitlab-login
docker-gitlab-login: docker/gitlab-login docker/gitlab-token
	@docker login -u $$(cat $<) --password-stdin $(DOCKER_GITLAB_REGISTRY) < docker/gitlab-token

.PHONY: docker-gitlab-logout
docker-gitlab-logout:
	@docker logout $(DOCKER_GITLAB_REGISTRY)

docker/docker-hub-token:
	@echo "You need a Docker Hub personal access token."
	@echo "See https://app.docker.com/accounts/skylabsai/settings/personal-access-tokens/"
	@echo "Credentials can be shared by Ehtesham."
	@echo -n "Enter your personal access token: "
	@read -r TOKEN; echo $$TOKEN > $@

.PHONY: docker-hub-login
docker-hub-login: docker/docker-hub-token
	@docker login -u skylabsai --password-stdin < $<

.PHONY: docker-hub-logout
docker-hub-logout:
	@docker logout

### Base docker image (from BlueRock's fm-ci config).

.PHONY: docker-build-fm-default
docker-build-fm-default:
	@$(MAKE) -C fmdeps/fm-ci/docker tag-default BR_REGISTRY=$(DOCKER_GHCR_SKYLABS_FM)

.PHONY: docker-run-fm-default
docker-run-fm-default:
	@$(MAKE) -C fmdeps/fm-ci/docker run-default BR_REGISTRY=$(DOCKER_GHCR_SKYLABS_FM)

.PHONY: docker-push-fm-default
docker-push-fm-default: docker-build-fm-default | docker-login
	@docker push $(DOCKER_GHCR_SKYLABS_FM):fm-default

.PHONY: docker-pull-fm-default
docker-pull-fm-default: | docker-login
	@docker pull $(DOCKER_GHCR_SKYLABS_FM):fm-default

### Intermediate docker image (with fmdeps installed).

docker/latest-fmdeps.tar.gz: docker/build-latest-fmdeps.sh
	./$< docker/latest-fmdeps $@

GENERATED_FILES += docker/latest-fmdeps/
GENERATED_FILES += docker/latest-fmdeps.tar.gz

.PHONY: docker-build-fm-default-fmdeps
docker-build-fm-default-fmdeps: docker/Dockerfile-fmdeps docker/latest-fmdeps.tar.gz docker-build-fm-default
	docker buildx build \
		--tag "$(DOCKER_GHCR_SKYLABS_FM):fm-default-fmdeps" \
		--build-arg BASE_IMAGE="$(DOCKER_GHCR_SKYLABS_FM):fm-default" \
		--file $< .

.PHONY: docker-run-fm-default-fmdeps
docker-run-fm-default-fmdeps:
	docker run -i -t "$(DOCKER_GHCR_SKYLABS_FM):fm-default-fmdeps"

.PHONY: docker-push-fm-default-fmdeps
docker-push-fm-default-fmdeps: docker-build-fm-default-fmdeps | docker-login
	@docker push $(DOCKER_GHCR_SKYLABS_FM):fm-default-fmdeps

.PHONY: docker-pull-fm-default-fmdeps
docker-pull-fm-default-fmdeps: docker-pull-fm-default | docker-login
	@docker pull $(DOCKER_GHCR_SKYLABS_FM):fm-default-fmdeps

### Main docker image (with full toolchain installed).

docker/latest.tar.gz: docker/build-latest.sh
	./$< docker/latest $@

GENERATED_FILES += docker/skylabs-fm/
GENERATED_FILES += docker/latest.tar.gz

.PHONY: docker-build-skylabs-fm-default
docker-build-skylabs-fm-default: docker/Dockerfile docker/latest.tar.gz docker-build-fm-default-fmdeps
	docker buildx build \
		--tag "$(DOCKER_GHCR_SKYLABS_FM):skylabs-fm-default" \
		--build-arg BASE_IMAGE="$(DOCKER_GHCR_SKYLABS_FM):fm-default-fmdeps" \
		--file $< .

.PHONY: docker-run-skylabs-fm-default
docker-run-skylabs-fm-default:
	docker run -i -t "$(DOCKER_GHCR_SKYLABS_FM):skylabs-fm-default"

.PHONY: docker-push-skylabs-fm-default
docker-push-skylabs-fm-default: docker-build-skylabs-fm-default | docker-login
	@docker push $(DOCKER_GHCR_SKYLABS_FM):skylabs-fm-default

.PHONY: docker-pull-skylabs-fm-default
docker-pull-skylabs-fm-default: docker-pull-fm-default-fmdeps | docker-login
	@docker pull $(DOCKER_GHCR_SKYLABS_FM):skylabs-fm-default

### Shortcuts

.PHONY: docker-build
docker-build: docker-build-skylabs-fm-default

.PHONY: docker-run
docker-run: docker-run-skylabs-fm-default

.PHONY: docker-pull
docker-pull: docker-pull-skylabs-fm-default
