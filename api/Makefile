SHELL=/bin/bash

.PHONY: help
help: ## Print this message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

.PHONY: lstart
lstart: ## start the docker container
	docker-compose up 

.PHONY: start
start: ## start the docker container
	docker-compose up

.PHONY: start-daemon
start-daemon: ## start the docker container, daemonize
	docker-compose up -d

.PHONY: build-start
build-start: ## rebuild and start the docker container
	docker-compose up --build -d

.PHONY: stop
stop: ## Stop all docker containers
	docker-compose down

.PHONY: rebuild
rebuild: stop build-start ## Shortcut for stop start

.PHONY: restart
restart: rebuild

