# -*-makefile-*-
#
#  eval and register a system output with the following command
#
#  make USER=username MODELNAME=modelname BENCHMARK=testset LANGPAIR=xxx-yyy FILE=filename eval
#
#    username  = name of the user/provider of the system translation
#    modelname = name of the model that produced the translations (ASCII and no spaces!)
#    testset   = name of a valid test set in our collection (e.g.. flores200-devtest)
#    xxx-yyy   = language pair of the test set (e.g. deu-eng)
#    filename  = path and filename to the system output to be evaluated
#
#
# TODO: add more metadata (model-yaml file) like website, ...
#---------------------------------------------------------------------------------------------


PWD      := ${shell pwd}
REPOHOME := ${PWD}/


## evaluation metrics
METRICS := bleu spbleu chrf chrf++ # comet
METRIC  ?= $(firstword ${METRICS})

ifdef LANGPAIRDIR
  LANGPAIR := $(lastword $(subst /, ,${LANGPAIRDIR}))
endif


## SCORE_DIRS   = directories that contains new scores
## LEADERBOARDS = list of leader boards that need to be updated
##    - for all leaderboards with new scores if UPDATED_LEADERBOARDS is set
##    - or for a selected LANGPAIR

ifdef LANGPAIR
  SCORE_DIRS := $(shell find scores/${LANGPAIR} -mindepth 2 -name '*.unsorted.txt' | cut -f1-3 -d/ | sort -u)
  LANGPAIRS  := ${LANGPAIR}
else ifeq (${UPDATED_LEADERBOARDS},1)
  SCORE_DIRS := $(shell find scores -mindepth 3 -name '*.unsorted.txt' | cut -f1-3 -d/ | sort -u)
  LANGPAIRS  := $(sort $(dir $(patsubst scores/%,%,${SCORE_DIRS})))
  LANGPAIR   ?= $(firstword ${LANGPAIRS})
else
  LANGPAIRS  := $(shell find scores -name '*-*' -mindepth 1 -maxdepth 1 -type d | cut -f2 -d/ | sort -u)
  LANGPAIR   := $(firstword ${LANGPAIRS})
  SCORE_DIRS := $(shell find scores/${LANGPAIR} -mindepth 2 -name '*.unsorted.txt' | cut -f1-3 -d/ | sort -u)
endif

LEADERBOARDS := $(foreach m,${METRICS},$(patsubst %,%/$(m)-scores.txt,${SCORE_DIRS}))


LANGPAIR_LISTS  := scores/langpairs.txt
BENCHMARK_LISTS := scores/benchmarks.txt


.PHONY: all
all: scores
	find scores -name '*unsorted*' -empty -delete
	${MAKE} -s updated-leaderboards
	${MAKE} -s scores/langpairs.txt user-scores/benchmarks.txt
	find scores -name '*.txt' | grep -v unsorted | xargs git add


.PHONY: all-langpairs
all-langpairs:
	@find scores -name '*unsorted*' -empty -delete
	${MAKE} -s refresh-leaderboards
	${MAKE} -s scores/langpairs.txt scores/benchmarks.txt
	find scores/ -name '*.txt' | grep -v unsorted | xargs git add



#--------------------------------------------------
# make [ARGS] eval
#
# evaluate some system output on an existing benchmark
# - expected ARGS:
#
#   USER=username
#   MODELNAME=modelname
#   LANGPAIR=src-trg
#   FILE=filename
#
#--------------------------------------------------

TESTSET_FILES := OPUS-MT-testsets/testsets.tsv

ifdef USER
ifdef MODELNAME
ifdef BENCHMARK
ifdef LANGPAIR
ifneq ($(wildcard ${FILE}),)

SRC           := ${firstword ${subst -, ,${LANGPAIR}}}
TRG           := ${lastword ${subst -, ,${LANGPAIR}}}
SYSTEM_LOGZIP := models/${USER}/${MODELNAME}.zip
MODEL_YAML    := models/${USER}/${MODELNAME}.yaml
SYSTEM_OUTPUT := models/${USER}/${MODELNAME}/${BENCHMARK}.${LANGPAIR}.output
TESTSET_SRC   := $(patsubst %,OPUS-MT-testsets/%,$(shell grep '^${SRC}	${TRG}	${BENCHMARK}	' ${TESTSET_FILES} | cut -f7))

.PHONY: eval
eval: ${SYSTEM_LOGZIP}

${SYSTEM_OUTPUT}:
	mkdir -p $(dir ${SYSTEM_OUTPUT})
	cp ${FILE} ${SYSTEM_OUTPUT}


${MODEL_YAML}:
	@mkdir -p models/${USER}
ifneq ($(wildcard ${MODEL_YAML}),)
	@grep '^language-pairs: ' ${MODEL_YAML} |\
	cut -f2- -d: | sed 's/^/${LANGPAIR}/' | \
	tr ' ' "\n" | sort -u | tr "\n" ' '                         > ${MODEL_YAML}.langpairs || exit 0
	@grep -v '^language-pairs: ' ${MODEL_YAML}                  > ${MODEL_YAML}.tmp || exit 0
	@cat ${MODEL_YAML}.langpairs | sed 's/^/language-pairs: /' >> ${MODEL_YAML}.tmp
	@mv -f ${MODEL_YAML}.tmp ${MODEL_YAML}
	@rm -f ${MODEL_YAML}.langpairs
ifdef WEBSITE
	@grep -v '^website: ' ${MODEL_YAML}                         > ${MODEL_YAML}.tmp || exit 0
	@echo "website: ${WEBSITE}"                                >> ${MODEL_YAML}.tmp
	@mv ${MODEL_YAML}.tmp ${MODEL_YAML}
endif
else
	@echo "language-pairs: ${LANGPAIR}"                         > ${MODEL_YAML}
ifdef WEBSITE
	@echo "website: ${WEBSITE}"                                >> ${MODEL_YAML}
endif
endif


${SYSTEM_LOGZIP}: ${SYSTEM_OUTPUT} ${MODEL_YAML}
ifneq ($(wildcard ${TESTSET_SRC}),)
ifeq ($(shell cat ${FILE} | grep . | wc -l),$(shell cat ${TESTSET_SRC} | grep . | wc -l))
	mkdir -p $(dir ${SYSTEM_OUTPUT})
	cp ${FILE} ${SYSTEM_OUTPUT}
	${MAKE} -C models \
		USER_NAME='${USER}' \
		USER_MODEL='${MODELNAME}' \
		TESTSETS='${BENCHMARK}' \
		LANGPAIR='${LANGPAIR}' \
		MODEL_URL='${WEBSITE}' \
	all
	${MAKE} -C models MODEL='${USER}/${MODELNAME}' register
	find scores/${LANGPAIR}/${BENCHMARK} -name '*unsorted*' -empty -delete
	${MAKE} update-leaderboards
	${MAKE} all-topavg-scores
	find scores/${LANGPAIR}/${BENCHMARK} -name '*.txt' | grep -v unsorted | xargs git add
	git add ${SYSTEM_OUTPUT} ${SYSTEM_LOGZIP}
	git add models/${USER}/${MODELNAME}.*.txt models/${USER}/${MODELNAME}.*.registered
else
	echo "${FILE} and ${TESTSET_SRC} have different lengths"
endif
else
	@echo "cannot find ${TESTSET_SRC}"
endif
endif
endif
endif
endif
endif









#--------------------------------------------------

## fetch all evaluation zip file

.PHONY: fetch-zipfiles
fetch-zipfiles:
	${MAKE} -C models download-all

.PHONY: all-topavg-scores
all-topavg-scores:
	for m in ${METRICS}; do \
	  echo "extract top/avg scores for $$m scores"; \
	  ${MAKE} -s METRIC=$$m top-langpair-scores avg-langpair-scores; \
	done

.PHONY: all-avg-scores
all-avg-scores:
	for m in ${METRICS}; do \
	  echo "extract avg scores for $$m scores"; \
	  ${MAKE} -s METRIC=$$m avg-langpair-scores; \
	done

.PHONY: all-top-scores
all-top-scores:
	for m in ${METRICS}; do \
	  echo "extract top scores for $$m scores"; \
	  ${MAKE} -s METRIC=$$m top-langpair-scores; \
	done


.PHONY: update-leaderboards
update-leaderboards: ${LEADERBOARDS}


## update all updated leaderboards
## (the ones with new scores registered)

.PHONY: updated-leaderboards
updated-leaderboards:
	${MAKE} UPDATED_LEADERBOARDS=1 update-leaderboards
	${MAKE} UPDATED_LEADERBOARDS=1 all-topavg-scores




## refresh all leaderboards using phony targets for each language pair
## this scales to large lists of language pairs

UPDATE_LEADERBOARD_TARGETS = $(sort $(patsubst %,%-update-leaderboard,${LANGPAIRS}))

.PHONY: refresh-leaderboards
refresh-leaderboards: $(UPDATE_LEADERBOARD_TARGETS)
	${MAKE} -s all-topavg-scores

.PHONY: $(UPDATE_LEADERBOARD_TARGETS)
$(UPDATE_LEADERBOARD_TARGETS):
	${MAKE} -s LANGPAIR=$(@:-update-leaderboard=) update-leaderboards



# refresh all leaderboards using find

.PHONY: refresh-leaderboards-find
refresh-leaderboards-find:
	find scores -maxdepth 1 -mindepth 1 -type d \
		-exec ${MAKE} LANGPAIRDIR={} update-leaderboards \;
	${MAKE} -s all-topavg-scores








.PHONY: model-list
model-list: scores/${LANGPAIR}/model-list.txt

scores/%/model-list.txt:
	find ${dir $@} -mindepth 2 -name '*-scores.txt' | xargs cut -f2 | sort -u > $@

released-models.txt: scores
	find scores -name 'bleu-scores.txt' | xargs cat | cut -f2 | sort -u > $@

.PHONY: top-score-file top-scores
top-score-file: scores/${LANGPAIR}/top-${METRIC}-scores.txt
top-scores: $(foreach m,${METRICS},scores/${LANGPAIR}/top-${m}-scores.txt)
top-langpair-scores: $(foreach l,${LANGPAIRS},scores/${l}/top-${METRIC}-scores.txt)


.PHONY: avg-score-file avg-scores
avg-score-file: scores/${LANGPAIR}/avg-${METRIC}-scores.txt
avg-scores: $(foreach m,${METRICS},scores/${LANGPAIR}/avg-${m}-scores.txt)
avg-langpair-scores: $(foreach l,${LANGPAIRS},scores/${l}/avg-${METRIC}-scores.txt)



## explicitely listing impict rules for each metric would make it possible
## to call it for all possible language pairs (don't have to loop over language pairs)
## disadvantages:
##   * need to create new rules for new metrics
##   * repeat the same recipe over and over again
## for the second problem: could use "define" to define a rule
## I don't know a principled solution for the first problem
## foreach does not work, e.g. this would be cool:
##
# $(foreach m,${METRICS},scores/%/avg-${m}-scores.txt): scores/%/model-list.txt
#	@echo "update $@"
#	@tools/average-scores.pl $(sort $(wildcard $(dir $@)*/$(patsubst avg-%,%,$(notdir $@)))) > $@



scores/${LANGPAIR}/avg-%-scores.txt: scores/${LANGPAIR}/model-list.txt
	@echo "update $@"
	@tools/average-scores.pl $(sort $(wildcard $(dir $@)*/$(patsubst avg-%,%,$(notdir $@)))) > $@

scores/%/avg-${METRIC}-scores.txt: scores/%/model-list.txt
	@echo "update $@"
	@tools/average-scores.pl $(sort $(wildcard $(dir $@)*/$(patsubst avg-%,%,$(notdir $@)))) > $@


scores/${LANGPAIR}/top-%-scores.txt: scores/${LANGPAIR}/model-list.txt
	@echo "update $@"
	@rm -f $@
	@for f in $(sort $(wildcard $(dir $@)*/$(patsubst top-%,%,$(notdir $@)))); do \
	  if [ -s $$f ]; then \
	    t=`echo $$f | cut -f3 -d/`; \
	    echo -n "$$t	" >> $@; \
	    head -1 $$f           >> $@; \
	  fi \
	done

scores/%/top-${METRIC}-scores.txt: scores/%/model-list.txt
	@echo "update $@"
	@rm -f $@
	@for f in $(sort $(wildcard $(dir $@)*/$(patsubst top-%,%,$(notdir $@)))); do \
	  if [ -s $$f ]; then \
	    t=`echo $$f | cut -f3 -d/`; \
	    echo -n "$$t	" >> $@; \
	    head -1 $$f           >> $@; \
	  fi \
	done


${LEADERBOARDS}: ${SCORE_DIRS}
	@echo "update $@"
	@if [ -e $@ ]; then \
	  if [ $(words $(wildcard ${@:.txt=}*.unsorted.txt)) -gt 0 ]; then \
	    echo "merge and sort ${patsubst scores/%,%,$@}"; \
	    sort -k2,2 -k1,1nr $@                           > $@.old.txt; \
	    cat $(wildcard ${@:.txt=}*.unsorted.txt) | \
	    grep '^[0-9\-]' | sort -k2,2 -k1,1nr            > $@.new.txt; \
	    sort -m $@.new.txt $@.old.txt |\
	    uniq -f1 | sort -k1,1nr -u                      > $@.sorted; \
	    rm -f $@.old.txt $@.new.txt; \
	    rm -f $(wildcard ${@:.txt=}*.unsorted.txt); \
	    mv $@.sorted $@; \
	    rm -f $(dir $<)model-list.txt; \
	  fi; \
	else \
	  if [ $(words $(wildcard ${@:.txt=}*.txt)) -gt 0 ]; then \
	    echo "merge and sort ${patsubst scores/%,%,$@}"; \
	    cat $(wildcard ${@:.txt=}*.txt) | grep '^[0-9\-]' |\
	    sort -k2,2 -k1,1nr | uniq -f1 | sort -k1,1nr -u > $@.sorted; \
	    rm -f $(wildcard ${@:.txt=}*.txt); \
	    mv $@.sorted $@; \
	    rm -f $(dir $<)model-list.txt; \
	  fi; \
	fi

scores/${LANGPAIR}/%-scores.txt: scores/${LANGPAIR}
	@echo "update $@"
	@if [ -e $@ ]; then \
	  if [ $(words $(wildcard ${@:.txt=}*.unsorted.txt)) -gt 0 ]; then \
	    echo "merge and sort ${patsubst scores/%,%,$@}"; \
	    sort -k2,2 -k1,1nr $@                           > $@.old.txt; \
	    cat $(wildcard ${@:.txt=}*.unsorted.txt) | \
	    grep '^[0-9\-]' | sort -k2,2 -k1,1nr            > $@.new.txt; \
	    sort -m $@.new.txt $@.old.txt |\
	    uniq -f1 | sort -k1,1nr -u                      > $@.sorted; \
	    rm -f $@.old.txt $@.new.txt; \
	    rm -f $(wildcard ${@:.txt=}*.unsorted.txt); \
	    mv $@.sorted $@; \
	    rm -f $(dir $<)model-list.txt; \
	  fi; \
	else \
	  if [ $(words $(wildcard ${@:.txt=}*.txt)) -gt 0 ]; then \
	    echo "merge and sort ${patsubst scores/%,%,$@}"; \
	    cat $(wildcard ${@:.txt=}*.txt) | grep '^[0-9\-]' |\
	    sort -k2,2 -k1,1nr | uniq -f1 | sort -k1,1nr -u > $@.sorted; \
	    rm -f $(wildcard ${@:.txt=}*.txt); \
	    mv $@.sorted $@; \
	    rm -f $(dir $<)model-list.txt; \
	  fi; \
	fi






%/langpairs.txt: %
	find $(dir $@) -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort > $@


%/benchmarks.txt: %
	for b in $(sort $(shell find $(dir $@) -mindepth 2 -maxdepth 2 -type d -printf '%f\n')); do \
	  echo -n "$$b	" >> $@; \
	  find $(dir $@) -name "$$b" -type d | cut -f2 -d/ | sort -u | tr "\n" ' ' >> $@; \
	  echo "" >> $@; \
	done



include ${REPOHOME}lib/env.mk
include ${REPOHOME}lib/config.mk
include ${REPOHOME}lib/slurm.mk

