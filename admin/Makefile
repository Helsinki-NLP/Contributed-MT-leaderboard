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


#--------------------------------------------------------------------
# find the files that need to be modified / removed
#
#   if BENCHMARK is set (e.g. to flores200-devtest)
#      - all top-score files for language pairs that exist for this benchmark
#        (unless LANGPAIR is set to specific selected language pairs)
#      - all benchmark-specific sub-directories in the leaderboard
#      - all model score files (need to test whether they have been tested with this benchmark)
#        TODO: should restrict to models that can handle that language pair!
#   if BENCHMARK and MODEL are set
#      - all top-score files for language pairs that exist for this benchmark
#        (unless LANGPAIR is set to specific selected language pairs)
#      - all score files of the selected benchmark (need to remove the entry for the selected model)
#      - only model score files of that model
#   if MODEL is set
#      - all score files of language pairs that the model can handle
#      - all model score files
#   otherwise:
#      - all top score files
#      - all model score files
#--------------------------------------------------------------------

ifneq (${BENCHMARK},)
  LANGPAIR         ?= $(shell grep '^${BENCHMARK}	' ../scores/benchmarks.txt | cut -f2)
  TOPSCORE_FILES   := $(foreach langpair,$(LANGPAIR),$(wildcard ../scores/$(langpair)/top-*.txt))
  SCORE_FILE_DIRS  := $(foreach langpair,$(LANGPAIR),$(wildcard ../scores/$(langpair)/${BENCHMARK}))
ifneq (${MODEL},)
  MODELSCORE_FILES := $(wildcard ../models/${MODEL}.*.txt)
  SCORE_FILES      := $(foreach langpair,$(LANGPAIR),$(wildcard ../scores/$(langpair)/${BENCHMARK}/*.txt))
  EVALZIP_FILES    := $(wildcard ../models/${MODEL}.eval.zip)
else
  MODELS           := $(sort $(foreach langpair,$(LANGPAIR),$(shell cat ../scores/$(langpair)/model-list.txt)))
  MODELSCORE_FILES := $(foreach model,$(MODELS),$(wildcard ../models/$(model).*.txt))
endif
else ifneq (${MODEL},)
  LANGPAIR         ?= $(shell cut -f1 ../models/${MODEL}.scores.txt | sort -u)
  TOPSCORE_FILES   := $(foreach langpair,$(LANGPAIR),$(wildcard ../scores/$(langpair)/top-*.txt))
  MODELSCORE_FILES := $(wildcard ../models/${MODEL}.*.txt)
  SCORE_FILES      := $(foreach langpair,$(LANGPAIR),$(wildcard ../scores/$(langpair)/*/*.txt))
  EVALZIP_FILES    := $(wildcard ../models/${MODEL}.eval.zip)
else ifneq (${LANGPAIR},)
  TOPSCORE_FILES   := $(foreach langpair,$(LANGPAIR),$(wildcard ../scores/$(langpair)/top-*.txt))
  SCORE_FILE_DIRS  := $(patsubst %,../scores/%,$(LANGPAIR))
  MODELS           := $(sort $(foreach langpair,$(LANGPAIR),$(shell cat ../scores/$(langpair)/model-list.txt)))
  MODELSCORE_FILES := $(foreach model,$(MODELS),$(wildcard ../models/$(model).*.txt))
  EVALZIP_FILES    := $(foreach model,$(MODELS),$(model).eval.zip)
else
  TOPSCORE_FILES   := $(wildcard ../scores/*/top-*.txt)
  MODELSCORE_FILES := $(shell find ../models -name '*.txt')
  EVALZIP_FILES    := $(shell find ../models -name '*.eval.zip')
endif



## backup files before removing benchmarks
## also used as targets to actually remove them from the original files

SCORE_FILE_DIRS_REMOVE  := $(patsubst %,%.remove-dir,${SCORE_FILE_DIRS})
SCORE_FILES_REMOVE      := $(patsubst %.txt,%.remove,${SCORE_FILES})
TOPSCORE_FILES_REMOVE   := $(patsubst %.txt,%.remove,${TOPSCORE_FILES})
MODELSCORE_FILES_REMOVE := $(patsubst %.txt,%.remove,${MODELSCORE_FILES})



## print the files that will be affected by a remove command

print-affected-files:
	@echo "------------score-file-dirs:-------------"
	@echo "${SCORE_FILE_DIRS}" | tr ' ' "\n"
	@echo "------------score-files------------------"
	@echo "${SCORE_FILES}" | tr ' ' "\n"
	@echo "------------top-score-files--------------"
	@echo "${TOPSCORE_FILES}" | tr ' ' "\n"
	@echo "------------model-files------------------"
	@echo "${MODELSCORE_FILES}" | tr ' ' "\n"
	@echo "------------eval-file-zips---------------"
	@echo "${EVALZIP_FILES}" | tr ' ' "\n"


.PHONY: remove

ifneq (${BENCHMARK},)
remove: remove-benchmark
else ifneq (${MODEL},)
remove: remove-model
endif


remove:

##-----------------------------------------------------------------------------
## remove all info about a specific model
##-----------------------------------------------------------------------------

.PHONY: remove-model
remove-model:
ifneq (${MODEL},)
	${MAKE} REMOVE_PATTERN='<TAB>${MODEL}<EOS>' remove-from-topscores
	${MAKE} REMOVE_PATTERN='<TAB>${MODEL}<EOS>' remove-from-scores
	rm -f ../models/${MODEL}.*
endif

##-----------------------------------------------------------------------------
## remove one or more benchmarks from the leaderboards and score files
## TODO: need to also do something with the evaluation files in the zip archives
##-----------------------------------------------------------------------------

.PHONY: remove-benchmark
remove-benchmark:
ifneq (${BENCHMARK},)
ifneq (${MODEL},)
	${MAKE} REMOVE_PATTERN='^${BENCHMARK}<TAB>.*<TAB>${MODEL}<EOS>' remove-from-topscores
	${MAKE} REMOVE_PATTERN='<TAB>${BENCHMARK}<TAB>' remove-from-modelscores
	${MAKE} REMOVE_PATTERN='<TAB>${MODEL}<EOS>' remove-from-scores
else
	${MAKE} REMOVE_PATTERN='^${BENCHMARK}<TAB>' remove-from-topscores
	${MAKE} REMOVE_PATTERN='<TAB>${BENCHMARK}<TAB>' remove-from-modelscores
	${MAKE} remove-benchmark_scores
endif
endif

##-----------------------------------------------------------------------------
## remove dev sets from the leaderboard
##-----------------------------------------------------------------------------

DEVSETS := $(sort $(shell cut -f1 ../scores/benchmarks.txt | grep dev | grep -v devtest))

.PHONY: remove-devsets
remove-devsets:
	${MAKE} REMOVE_PATTERN='^($(sort $(subst ${SPACE},|,${DEVSETS})))<TAB>' remove-from-topscores
	${MAKE} REMOVE_PATTERN='<TAB>($(sort $(subst ${SPACE},|,${DEVSETS})))<TAB>' remove-from-modelscores
	@for d in ${DEVSETS}; do \
	  echo "delete $$d"; \
	  find ../scores/ -maxdepth 2 -mindepth 1 -name $$d -exec rm -fr {} \; ; \
	done
	${MAKE} remove-devevalfiles


## remove all evaluation files that belong to development sets
## and put them into a separate zip file

EVALZIP_DEV := $(patsubst %.eval.zip,%.deveval.zip,${EVALZIP_FILES})

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

.PHONY: remove-from-scores remove-from-topscores remove-from-modelscores
remove-from-scores: ${SCORE_FILES_REMOVE}
remove-from-topscores: ${TOPSCORE_FILES_REMOVE}
remove-from-modelscores: ${MODELSCORE_FILES_REMOVE}

REMOVE_PATTERN_UNESCAPED := $(subst <EOS>,$$,$(subst <TAB>,	,${REMOVE_PATTERN}))

${SCORE_FILES_REMOVE} ${TOPSCORE_FILES_REMOVE} ${MODELSCORE_FILES_REMOVE}: %.remove: %.txt
ifneq (${REMOVE_PATTERN_UNESCAPED},)
	@mv -f $< $@
	egrep -v '${REMOVE_PATTERN_UNESCAPED}' < $@ > $< || exit 1
	@touch $@
endif


.PHONY: remove-benchmark_scores
remove-benchmark_scores: ${SCORE_FILE_DIRS_REMOVE}

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
