all: hookup_spec.pdf

%.pdf : %.md
	pandoc -V geometry:margin=1in -o $@ $^

.PHONY: all
