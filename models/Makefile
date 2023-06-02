# -*-makefile-*-
#
# template for evaluating user-contributed translations
#
# What you need to do is
#
#   * set the model-specific variables MODELS, MODEL_LANGPAIRS, MODEL_URL
#   * place the translations into a temporary work directory
#   * run make with appropriate settings
#
#-----------------------------------------------------------------------------
#
# Example: evaluate a user contributed translation of flores101-dev from English to Danish
#          for a user <username> and model <modelname>
#
#   mkdir -p work/username/modelname
#   cp translation-file.txt work/username/modelname/flores101-devtest.eng-dan.output
#
#   make USER_NAME=username USER_MODEL=modelname \
#        TESTSETS=flores101-devtest LANGPAIR=eng-dan \
#   eval
#
#
# After evaluating all benchmarks, create model score files with:
#
#   make USER_NAME=username USER_MODEL=modelname \
#        MODEL_URL=http://path/to/my/wonderful-model \
#   eval-model-files
#
#
# and finally pack everything together:
#
#   make USER_NAME=username USER_MODEL=modelname pack-model-scores
#
#-----------------------------------------------------------------------------


PWD      := ${shell pwd}
REPOHOME := ${PWD}/../

METRICS     := bleu spbleu chrf chrf++
ALL_SOURCES := $(filter-out lib,$(notdir ${shell find . -maxdepth 1 -mindepth 2 -type d}))


## specify all models

MODEL_HOME  := ${PWD}
USER_NAME   ?= testuser
USER_MODEL  ?= testmodel
MODELS      := ${USER_NAME}/${USER_MODEL}
MODEL       ?= $(firstword ${MODELS})


## MODEL_URL: location of the public model (to be stored in the score files)
## MODEL_EVAL_URL: location of the storage space for the evaluation output files

MODEL_URL       := https://location.of.my.model/storage/${MODEL}
MODEL_STORAGE   := https://object.pouta.csc.fi/Contributed-MT-models
MODEL_EVAL_URL  := ${MODEL_STORAGE}/${MODEL}.eval.zip

SKIP_NEW_EVALUATION := 1

.PHONY: all
all:
	${MAKE} -s fetch-model-scores
	${MAKE} -s eval
	${MAKE} -s update-eval-files
	${MAKE} -s pack-model-scores



## all kinds of common evaluation recipes and variables
## no changes needed (hopefully)


include lib/config.mk
include lib/eval.mk

.PHONY: fetch-model
fetch-model:
	@echo "no model to fetch"


##----------------------------------------------------------------------
## targets for score registration and file upload
##
##    make register
##    make upload
##
##    make register-all
##    make upload-all
##
## ...
##----------------------------------------------------------------------



## scores that need to be registered (stored in temporary score files)
## if ALL_MODELS is set: check all model directories
## if ALL_MODELS is not set: take only the current model dir

ifdef ALL_MODELS
  SCOREFILES := ${shell find ${MODEL_HOME}/ -name '*-scores.txt'}
else
  SCOREFILES := ${wildcard ${MODEL_DIR}.*-scores.txt}
endif


## if ALL_MODELSOURCE is set: find all *.scores.txt files
## to get a list of all *.eval.zip files (a very long list)

ifdef ALL_MODELSOURCES
  MODEL_EVALZIPS := $(patsubst ./%.scores.txt,%.eval.zip,${shell find . -name '*.scores.txt'})
endif

MODEL_EVALZIPS  ?= $(patsubst %,%.eval.zip,$(sort $(basename ${SCOREFILES:.txt=})))
SCOREFILES_DONE := ${SCOREFILES:.txt=.registered}



.PHONY: register-all
register-all:
	for s in ${ALL_SOURCES}; do \
	  ${MAKE} SOURCE=$$s ALL_MODELS=1 register; \
	done

## register scores from all models in current source in leaderboards
.PHONY: register-scores
register-scores:
	${MAKE} ALL_MODELS=1 register

## register scores from current model in leaderboards
.PHONY: register
register: ${SCOREFILES_DONE}
ifdef ALL_MODELS
	find ${MODEL_HOME}/ -name '*.txt' | xargs git add
	find ${MODEL_HOME}/ -name '*.registered' | xargs git add
	-find ${MODEL_HOME}/ -name '*.logfiles' | xargs git add
else
	git add ${MODEL_DIR}.*.txt
	git add ${MODEL_DIR}.*.registered
	-git add ${MODEL_DIR}.logfiles
endif

## register the scores for the current model
## (scores will be added to some temporary files sorted by language pair and benchmark)
## NOTE: this removes langIDs from newstest sets to avoid confusion and duplicates

${MODEL_HOME}/%-scores.registered: ${MODEL_HOME}/%-scores.txt
	@echo "register scores from ${patsubst ${MODEL_HOME}/%,%,$<}"
	@cat $< | perl -e 'while (<>){ chomp; @a=split(/\t/); $$a[1]=~s/^(news.*)\-[a-z]{4}/$$1/; system "mkdir -p ${LEADERBOARD_DIR}/$$a[0]/$$a[1]"; open C,">>${LEADERBOARD_DIR}/$$a[0]/$$a[1]/$(patsubst .%,%,$(suffix $(basename $<))).$(subst /,.,${patsubst ${MODEL_HOME}/%,%,$<}).unsorted.txt"; $$m="$(basename $(basename $(patsubst ${MODEL_HOME}/%,%,$<)))";if ($$a[2] && $$m){print C "$$a[2]\t$$m\n";} close C; }'
	@touch $@



STORAGE_BUCKET := Contributed-MT-leaderboard
STORAGE_URL    := https://object.pouta.csc.fi/${STORAGE_BUCKET}

.PHONY: upload upload-eval-files
upload upload-eval-files:
	which a-get
	if [ `find .${MODEL_HOME} -size -5G -name '*.eval.zip' | wc -l` -gt 0 ]; then \
	  cd .. && find models/${MODEL_HOME} -size -5G -name '*.eval.zip' | \
		xargs swift upload ${STORAGE_BUCKET} --changed --skip-identical; \
	fi
	if [ `find .${MODEL_HOME} -size +5G -name '*.eval.zip' | wc -l` -gt 0 ]; then \
	  cd .. && find models/${MODEL_HOME} -size +5G -name '*.eval.zip' | \
		xargs swift upload ${STORAGE_BUCKET} --changed --skip-identical --use-slo --segment-size 5G; \
	fi
	swift post ${STORAGE_BUCKET} --read-acl ".r:*"

# -size +5G

.PHONY: upload-all
upload-all:
	which a-get
	if [ `find . -size -5G -name '*.eval.zip' | wc -l` -gt 0 ]; then \
	  cd .. && find models/ -size -5G -name '*.eval.zip' | \
		xargs swift upload ${STORAGE_BUCKET} --changed --skip-identical; \
	fi
	if [ `find . -size +5G -name '*.eval.zip' | wc -l` -gt 0 ]; then \
	  cd .. && find models/ -size +5G -name '*.eval.zip' | \
		xargs swift upload ${STORAGE_BUCKET} --changed --skip-identical --use-slo --segment-size 5G; \
	fi
	swift post ${STORAGE_BUCKET} --read-acl ".r:*"

.PHONY: upload-dryrun upload-eval-files-dryrun
upload-dryrun upload-eval-files-dryrun:
	@echo 'which a-get'
	@echo "cd .. && find models/${MODEL_HOME} -name '*.eval.zip' | xargs swift upload ${STORAGE_BUCKET}"




.PHONY: download download-eval-files
download download-eval-files: ${MODEL_EVALZIPS}

.PHONY: download-all
download-all:
	${MAKE} ALL_MODELSOURCES=1 download

%.eval.zip: %.scores.txt
	-wget -qq -O $@ ${STORAGE_URL}/models/$@






benchmark-info:
	@echo "benchmarks: ${TESTSETS}"
	@echo "  selected: ${TESTSET}"
	@echo "    source: ${TESTSET_SRC}"
	@echo "trg-labels: ${TESTSET_LABELS}"
	@echo "references: ${TESTSET_REFS}"
