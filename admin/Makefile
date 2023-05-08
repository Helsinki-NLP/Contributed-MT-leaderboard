# -*-makefile-*-
#
#  make MODEL=modelname remove-model
#  make BENCHMARK=testset remove-benchmark
#  make MODEL=modelname BENCHMARK=testset remove-benchmark
#
#  make BENCHMARK=testset LANGPAIR=langpair remove-benchmark
#  make MODEL=modelname BENCHMARK=testset LANGPAIR=langpair remove-benchmark
#
#  make remove-devsets
#  make cleanup


SPACE := $(empty) $(empty)

## all top-score files and model score files
## that may need an update

ifneq (${BENCHMARK},)
  LANGPAIR         ?= $(shell grep '^${BENCHMARK}	' ../scores/benchmarks.txt | cut -f2)
  TOPSCORE_FILES   := $(foreach langpair,$(LANGPAIR),$(wildcard ../scores/$(langpair)/top-*.txt))
  SCORE_FILE_DIRS  := $(foreach langpair,$(LANGPAIR),$(wildcard ../scores/$(langpair)/${BENCHMARK}))
ifneq (${MODEL},)
  MODELSCORE_FILES := $(wildcard ../models/${MODEL}.*.txt)
  SCORE_FILES      := $(foreach langpair,$(LANGPAIR),$(wildcard ../scores/$(langpair)/${BENCHMARK}/*.txt))
else
  MODELSCORE_FILES := $(shell find ../models -name '*.txt')
endif
else ifneq (${MODEL},)
  LANGPAIR         ?= $(shell cut -f1 ../models/${MODEL}.scores.txt | sort -u)
  TOPSCORE_FILES   := $(foreach langpair,$(LANGPAIR),$(wildcard ../scores/$(langpair)/top-*.txt))
  MODELSCORE_FILES := $(wildcard ../models/${MODEL}.*.txt)
  SCORE_FILES      := $(foreach langpair,$(LANGPAIR),$(wildcard ../scores/$(langpair)/*/*.txt))
else
  TOPSCORE_FILES   := $(wildcard ../scores/*/top-*.txt)
  MODELSCORE_FILES := $(shell find ../models -name '*.txt')
endif



## backup files before removing benchmarks
## also used as targets to actually remove them from the original files

SCORE_FILE_DIRS_REMOVE  := $(patsubst %,%.remove-dir,${SCORE_FILE_DIRS})
SCORE_FILES_REMOVE      := $(patsubst %.txt,%.remove,${SCORE_FILES})
TOPSCORE_FILES_REMOVE   := $(patsubst %.txt,%.remove,${TOPSCORE_FILES})
MODELSCORE_FILES_REMOVE := $(patsubst %.txt,%.remove,${MODELSCORE_FILES})


print-affected-files:
	@echo "${SCORE_FILE_DIRS}" | tr ' ' "\n"
	@echo "------------------------------"
	@echo "${SCORE_FILES}" | tr ' ' "\n"
	@echo "------------------------------"
	@echo "${TOPSCORE_FILES}" | tr ' ' "\n"
	@echo "------------------------------"
	@echo "${MODELSCORE_FILES}" | tr ' ' "\n"


##-----------------------------------------------------------------------------
## remove all info about a specific model
##-----------------------------------------------------------------------------

.PHONY: remove-model
remove-model:
ifneq (${MODEL},)
	${MAKE} REMOVE_PATTERN='	${MODEL}$$' renove-from-topscores
	${MAKE} REMOVE_PATTERN='	${MODEL}$$' renove-from-scores
	rm -f models/${MODEL}.*
endif

##-----------------------------------------------------------------------------
## remove one or more benchmarks from the leaderboards and score files
## TODO: need to also do something with the evaluation files in the zip archives
##-----------------------------------------------------------------------------

.PHONY: remove-benchmark
remove-benchmark:
ifneq (${BENCHMARK},)
ifneq (${MODEL},)
	${MAKE} REMOVE_PATTERN='^${BENCHMARK}	.*	${MODEL}$$' renove-from-topscores
	${MAKE} REMOVE_PATTERN='	${BENCHMARK}	' renove-from-modelscores
	${MAKE} REMOVE_PATTERN='	${MODEL}$$' renove-from-scores
else
	${MAKE} REMOVE_PATTERN='^${BENCHMARK}	' renove-from-topscores
	${MAKE} REMOVE_PATTERN='	${BENCHMARK}	' renove-from-modelscores
	${MAKE} renove-benchmark_scores
endif
endif

##-----------------------------------------------------------------------------
## renove dev sets from the leaderboard
##-----------------------------------------------------------------------------

DEVSETS := $(sort $(shell cut -f1 ../scores/benchmarks.txt | grep dev | grep -v devtest))

.PHONY: remove-devsets
remove-devsets:
	${MAKE} REMOVE_PATTERN='^($(sort $(subst ${SPACE},|,${DEVSETS})))	' renove-from-topscores
	${MAKE} REMOVE_PATTERN='	($(sort $(subst ${SPACE},|,${DEVSETS})))	' renove-from-modelscores
	@for d in ${DEVSETS}; do \
	  echo "delete $$d"; \
	  find ../scores/ -maxdepth 2 -mindepth 1 -name $$d -exec rm -fr {} \; ; \
	done
	${MAKE} remove-devevalfiles


## remove all evaluation files that belong to development sets
## and put them into a separate zip file

EVALZIP_FILES := $(shell find ../models -name '*.eval.zip')
EVALZIP_DEV   := $(patsubst %.eval.zip,%.deveval.zip,${EVALZIP_FILES})

.PHONY: remove-devevalfiles
remove-devevalfiles: ${EVALZIP_DEV}

${EVALZIP_DEV}: %.deveval.zip: %.eval.zip
	mkdir -p $@.d $<.d
	cd $<.d && unzip ../${notdir $<}
	for d in ${DEVSETS}; do \
	  find $<.d -name "$$d.*" -exec mv {} $@.d/ \; ;\
	done
	if [ `ls $<.d | wc -l` -gt 0 ]; then \
	  mv $< $<.backup; \
	  cd ${PWD}/$<.d && find . -name '*.*' | xargs zip ../${notdir $<}; \
	  cd ${PWD}/$@.d && find . -name '*.*' | xargs zip ../${notdir $@}; \
	fi
	rm -fr $<.d $@.d




##-------------------------------------------------
## generic targets to remove something
##-------------------------------------------------

.PHONY: remove-from-scores remove-from-topscores renove-from-modelscores
renove-from-scores: ${SCORE_FILES_REMOVE}
renove-from-topscores: ${TOPSCORE_FILES_REMOVE}
renove-from-modelscores: ${MODELSCORE_FILES_REMOVE}

${SCORE_FILES_REMOVE} ${TOPSCORE_FILES_REMOVE} ${MODELSCORE_FILES_REMOVE}: %.remove: %.txt
ifneq (${REMOVE_PATTERN},)
	mv -f $< $@
	egrep -v '${REMOVE_PATTERN}' < $@ > $<
	touch $@
endif


.PHONY: renove-benchmark_scores
renove-benchmark_scores: ${SCORE_FILE_DIRS_REMOVE}

${SCORE_FILE_DIRS_REMOVE}: %.remove-dir: %
	mv $< $@

##-------------------------------------------------
## cleanuo
##-------------------------------------------------

.PHONY: cleanup
cleanup:
	find ../scores -name '*.remove' -delete
	find ../models -name '*.remove' -delete
	find ../models -name '*.backup' -delete
	find ../scores -name '*.txt' -empty -delete
	find ../models -name '*.txt' -empty -delete
	find ../scores/ -name '*.remove-dir' -exec rm -fr {} \;
