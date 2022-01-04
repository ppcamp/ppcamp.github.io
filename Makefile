DEFAULT: help

.PHONY: help run build

FILENAME := "hugo.deb"
URL := "https://github.com/gohugoio/hugo/releases/download/v0.89.4/hugo_extended_0.89.4_Linux-64bit.deb"
DOWNLOAD_FILE := curl -L --max-redirs 5 --silent --output ${FILENAME} ${URL}

## build: build the project to the upper docs folder
build:
	@echo ""
	@echo " Building the project..."
	@echo ""
	@echo "Steps:"
	@echo ""
	@echo "1. Cleaning directory"
	rm -rfd ./docs/*
	@echo ""
	@echo "2. Building hugo"
	cd src && HUGO_ENV="production" hugo --destination=../docs
	@echo ""
	@echo "Finished!"

## run: Run a local server watching for changes
run:
	@echo ""
	@echo "Running the project..."
	@echo ""
	cd src && hugo server -w -D --disableFastRender --port=8080

## install-deps: Install hugo (needed to build this project)
install-deps:
	@echo ""
	@echo " Installing hugo..."
	@echo ""
	cd /tmp && ${DOWNLOAD_FILE}
	cd /tmp && sudo apt install ./${FILENAME}


help: Makefile
	@echo
	@echo " Choose a command run:"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'