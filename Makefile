build:
	./barf
	rsync -r public/ build/public

clean:
	rm -rf build/*

watch:
	while true; do \
	ls -d .git/* * posts/* pages/* header.html | entr -cd make ;\
	done

.PHONY: build clean watch
