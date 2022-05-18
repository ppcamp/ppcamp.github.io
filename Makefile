default: help

.PHONY: run
.PHONY: help
.PHONY: build
.PHONY: install-deps
.PHONY: install-hugo
.PHONY: install-minifier


ifeq ($(shell test -f .env && echo -n EXIST_ENV), EXIST_ENV)
    include .env
    export
endif


DOWNLOAD := curl -L --max-redirs 5 --silent --output
HUGO_URL := "https://github.com/gohugoio/hugo/releases/download/v0.89.4/hugo_extended_0.89.4_Linux-64bit.deb"
MINIFIER_URL := "https://github.com/tdewolff/minify/releases/download/v2.9.26/minify_linux_amd64.tar.gz"


clear: ## Clean the doc folder
	@echo ""
	@echo "Clearing the docs folder"
	@echo ""
	@rm -rfd ./docs/* ./public


run: ## Run a local server watching for changes
	@echo ""
	@echo "Running the project..."
	@echo ""
	@cd src && hugo server -w -D --disableFastRender --port=8080


build: clear ## Build the project to the upper docs folder
	@echo ""
	@echo " Building the project..."
	@echo ""
	@cd src && HUGO_ENV="production" hugo --destination=../docs
    #	@echo "3. Minifying the HTML"
    #	minify -r -o docs --match=\.html --html-keep-document-tags --html-keep-end-tags public && mv ./docs/public/* ./docs && rm -d ./docs/public
    #	@echo ""
    #	@echo "4. Cleaning up"
    #	rm -rfd ./public
    #	@echo ""
	@echo "Finished!"


install-hugo: ## Install hugo package (needed to build the static pages)
	@echo ""
	@echo " Installing hugo..."
	@echo ""
	cd /tmp && ${DOWNLOAD} "hugo.deb" ${HUGO_URL}
	cd /tmp && sudo apt install ./hugo.deb && reset


install-minifier: ## Install minifier package (needed to reduce the html size)
	@echo ""
	@echo " Installing minifier locally..."
	@echo ""
	cd /tmp && ${DOWNLOAD} "minify.tar.gz" ${MINIFIER_URL}
	cd /tmp && tar -xf minify.tar.gz && sudo cp minify /usr/bin && reset


install-deps: install-hugo install-minifier ## Install all needed deps


help:
	@printf "\e[2m Available methods:\033[0m\n\n"
        # 1. read makefile
        # 2. get lines that can have a method description and assign colors to method
        # 3. colour special worlds. If fail, return the original row
        # 4. colour and strip lines
        # 5. create column view
	@cat $(MAKEFILE_LIST) | \
	 	grep -E '^[a-zA-Z_-]+:.* ## .*$$' | \
		sed -rn 's/`([a-zA-Z0-9=\_\ \-]+)`/\x1b[33m\1\x1b[0m/g;t1;b2;:1;h;:2;p' | \
		sed -rn 's/(.*):.* ## (.*)/\x1b[32m\1:\x1b[0m\2/p' | \
		column -t -s ":"