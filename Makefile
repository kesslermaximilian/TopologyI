TEXINPUTS=LatexPackagesBuild//:
FULL_FILE=2021_Topologie_I
MASTER_FILE=master

### Compilation of the document

# Compiles the full document, assuming gnuplots already exist
${FULL_FILE}: ${FULL_FILE}.gnuplots
	@TEXINPUTS=${TEXINPUTS} latexmk -pdf -dvi- -latexoption=-interaction=nonstopmode ${FULL_FILE}.tex

# Compiles the master document, assuming gnuplots already exist
${MASTER_FILE}: ${MASTER_FILE}.gnuplots
	@TEXINPUTS=${TEXINPUTS} latexmk -pdf -dvi- -latexoption=-interaction=nonstopmode ${MASTER_FILE}.tex

# Runs pdflatex on the full document
${FULL_FILE}-pdflatex: ${FULL_FILE}.gnuplots
	@TEXINPUTS=${TEXINPUTS} pdflatex -interaction=nonstopmode ${FULL_FILE}.tex

# Runs pdflatex on the master document
${MASTER_FILE}-pdflatex: ${MASTER_FILE}.gnuplots
	@TEXINPUTS=${TEXINPUTS} pdflatex -interaction=nonstopmode ${MASTER_FILE}.tex

# Compiles the full document, as well as re-computing the gnuplots.
${FULL_FILE}-with-gnuplots: gnuplots-${FULL_FILE}
	@make ${FULL_FILE}-pdflatex # This ensures re-compilation for the gnuplots
	@make ${FULL_FILE} # Latexmk now takes care of biber etc (possibly no further runs are required)

# Compiles the master document, as well as re-computing the gnuplots.
${MASTER_FILE}-with-gnuplots: gnuplots-${MASTER_FILE}
	@make ${MASTER_FILE}-pdflatex
	@make ${MASTER_FILE}

#### Clean targets

clean: clean-${MASTER_FILE} clean-${FULL_FILE}

clean-${MASTER_FILE}:
	@ls | sed -n 's/^\(${MASTER_FILE}\..*\)$$/\1/p' | sed -e '/${MASTER_FILE}.tex/d' | sed -e '/${MASTER_FILE}.gnuplots/d' | xargs --no-run-if-empty rm

clean-${FULL_FILE}:
	@ls | sed -n 's/^\(${FULL_FILE}\..*\)$$/\1/p' | sed -e '/${FULL_FILE}.tex/d' | sed -e '/${FULL_FILE}.gnuplots/d' | sed -e '/${FULL_FILE}.cnt/d' | xargs --no-run-if-empty rm

#### Gnuplot-related targets

# Creates the folder for gnuplots of full document
${FULL_FILE}.gnuplots:
	@mkdir ${FULL_FILE}.gnuplots

# Creates the folder for gnuplots of master document
${MASTER_FILE}.gnuplots:
	@mkdir ${MASTER_FILE}.gnuplots

# Runs gnuplot on the gnuplot files of full document
compile-gnuplots-${FULL_FILE}: ${FULL_FILE}.gnuplots
	@echo "[Make] Running gnuplot in ${FULL_FILE}.gnuplots directory..."
	@for f in ${FULL_FILE}.gnuplots/*.gnuplot ; do [ -f "$$f" ] || continue; gnuplot "$$f"; done

# Runs gnuplot on the gnuplot files of master document
compile-gnuplots-${MASTER_FILE}: ${MASTER_FILE}.gnuplots
	@echo "[Make] Running gnuplot in ${MASTER_FILE}.gnuplots directory..."
	@for f in ${MASTER_FILE}.gnuplots/*.gnuplot ; do [ -f "$$f" ] || continue; gnuplot "$$f"; done

# Runs gnuplot on all gnuplot files
compile-gnuplots: compile-gnuplots-${FULL_FILE} compile-gnuplots-${MASTER_FILE}

# (Re)computes gnuplot files for full document
gnuplots-${FULL_FILE}: ${FULL_FILE}.gnuplots
	@rm -r ${FULL_FILE}.gnuplots
	@make ${FULL_FILE}-pdflatex
	@make compile-gnuplots-${FULL_FILE}

# (Re)computes gnuplot files for master document
gnuplots-${MASTER_FILE}: ${MASTER_FILE}.gnuplots
	@rm -r ${MASTER_FILE}.gnuplots
	@make ${MASTER_FILE}-pdflatex
	@make compile-gnuplots-${MASTER_FILE}

# (Re)computes all gnuplot files
gnuplots: gnuplots-${FULL_FILE} gnuplots-${MASTER_FILE}

# Gets the current gnuplot directories from origin
get-gnuplots:
	@echo "[Make] Getting gnuplots from origin/gnuplots"
	git checkout origin/gnuplots ${FULL_FILE}.gnuplots
	git restore --staged ${FULL_FILE}.gnuplots/
	git checkout origin/gnuplots ${MASTER_FILE}.gnuplots
	git restore --staged ${MASTER_FILE}.gnuplots/

#### Initialization and configuration of git repository

# Initializes the submodule, i.e. clones it correctly
init-submodule:
	@echo "[Make] Initialising submodules..."
	@git submodule update --init --rebase

# Sets up git hooks for gitinfo2 package
init-git-hooks:
	@echo "[Make] Setting up git hooks for package gitinfo2"
	@cp .travis/git-info-2.sh .git/hooks/post-merge
	@cp .travis/git-info-2.sh .git/hooks/post-checkout
	@cp .travis/git-info-2.sh .git/hooks/post-commit
	@.travis/git-info-2.sh

# Initializes submodule and git hooks for this repository
init: init-submodule init-git-hooks get-gnuplots

# Sets appropriate git configuration for this repository
config:
	@echo "[Make config] Setting git configs to prevent wrong pushes"
	@git config push.recurseSubmodules check
	@git config status.submodulesummary 1
	@echo "[Push annotated tags by default]"
	@git config push.followTags true

# See
# https://stackoverflow.com/a/26339924/16371376
# for explanation
# Lists all targets in this makefile
.PHONY: list
list:
	@LC_ALL=C $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
