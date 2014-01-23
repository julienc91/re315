TEXFILES=$(wildcard *.tex)
REPORT=rapport.pdf

all: $(REPORT) show

$(REPORT): $(TEXFILES)
	pdflatex rapport.tex && pdflatex rapport.tex

show: 
	evince rapport.pdf 2> /dev/null&

clean:
	rm *~ *.out *.aux *.toc *.glo 2> /dev/null

mrproper:
	make clean; rm $(REPORT)
