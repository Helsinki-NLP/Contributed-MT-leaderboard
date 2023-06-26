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




include ${REPOHOME}lib/leaderboards.mk
include ${REPOHOME}lib/env.mk
include ${REPOHOME}lib/config.mk
include ${REPOHOME}lib/slurm.mk



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

${SYSTEM_OUTPUT}: ${FILE}
ifneq ($(wildcard ${TESTSET_SRC}),)
ifeq ($(shell cat ${FILE} | grep . | wc -l),$(shell cat ${TESTSET_SRC} | grep . | wc -l))
	mkdir -p $(dir ${SYSTEM_OUTPUT})
	cp ${FILE} ${SYSTEM_OUTPUT}
else
	@echo "${FILE} and ${TESTSET_SRC} have different lengths"
	@exit 1
endif
else
	@echo "cannot find ${TESTSET_SRC}"
	@exit 1
endif

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
ifdef CONTACT
	@grep -v '^contact: ' ${MODEL_YAML}                         > ${MODEL_YAML}.tmp || exit 0
	@echo "contact: ${CONTACT}"                                >> ${MODEL_YAML}.tmp
	@mv ${MODEL_YAML}.tmp ${MODEL_YAML}
endif
else
	@echo "language-pairs: ${LANGPAIR}"                         > ${MODEL_YAML}
ifdef WEBSITE
	@echo "website: ${WEBSITE}"                                >> ${MODEL_YAML}
endif
endif


${SYSTEM_LOGZIP}: ${SYSTEM_OUTPUT} ${MODEL_YAML}
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


endif
endif
endif
endif
endif








