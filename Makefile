DEFAULT: help

.PHONY: help run build


DOWNLOAD := curl -L --max-redirs 5 --silent --output
HUGO_URL := "https://github.com/gohugoio/hugo/releases/download/v0.89.4/hugo_extended_0.89.4_Linux-64bit.deb"
MINIFIER_URL := "https://github.com/tdewolff/minify/releases/download/v2.9.26/minify_linux_amd64.tar.gz"

## build: build the project to the upper docs folder
build:
	@echo ""
	@echo " Building the project..."
	@echo ""
	@echo "Steps:"
	@echo ""
	@echo "1. Cleaning directory"
	rm -rfd ./docs/* ./public
	@echo ""
	@echo "2. Building hugo"
	cd src && HUGO_ENV="production" hugo --destination=../docs
	@echo ""
#	@echo "3. Minifying the HTML"
#	minify -r -o docs --match=\.html --html-keep-document-tags --html-keep-end-tags public && mv ./docs/public/* ./docs && rm -d ./docs/public
#	@echo ""
#	@echo "4. Cleaning up"
#	rm -rfd ./public
#	@echo ""
	@echo "Finished!"

## run: Run a local server watching for changes
run:
	@echo ""
	@echo "Running the project..."
	@echo ""
	cd src && hugo server -w -D --disableFastRender --port=8080

## install-hugo: Install hugo package (needed to build the static pages)
install-hugo:
	@echo ""
	@echo " Installing hugo..."
	@echo ""
	cd /tmp && ${DOWNLOAD} "hugo.deb" ${HUGO_URL}
	cd /tmp && sudo apt install ./hugo.deb && reset

## install-minifier: Install minifier package (needed to reduce the html size)
install-minifier:
	@echo ""
	@echo " Installing minifier locally..."
	@echo ""
	cd /tmp && ${DOWNLOAD} "minify.tar.gz" ${MINIFIER_URL}
	cd /tmp && tar -xf minify.tar.gz && sudo cp minify /usr/bin && reset

install-deps: install-hugo install-minifier

help: Makefile
	@echo
	@echo " Choose a command run:"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'