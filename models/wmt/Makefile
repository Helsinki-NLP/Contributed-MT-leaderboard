# -*-makefile-*-
#
# insert WMT system outputs
#
#

## below we can specify what kind of test sets to include
## we can probably skip that because nothing will be done for
## benchmarks that are not listed in OPUS-MT-testsets
#
# AVAILABLE_TESTSETS = newstest2021
# PERCENT = %
# SUBMISSIONS_DIR = wmt21-news-systems/txt/system-outputs
# SUBMISSIONS = $(filter $(patsubst %,%.${PERCENT},${AVAILABLE_TESTSETS}),$(notdir $(wildcard ${SUBMISSIONS_DIR}/*.*)))

CONFERENCE ?= wmt21

SUBMISSIONS_DIR = ${CONFERENCE}-news-systems/txt/system-outputs
SUBMISSIONS := $(notdir $(wildcard ${SUBMISSIONS_DIR}/*.*))
SUBMISSION  ?= $(firstword ${SUBMISSIONS})


PROVIDER   ?= ${CONFERENCE}
BENCHMARK  := $(word 1,$(subst ., ,${SUBMISSION}))
LANGPAIR   := $(shell iso639 -3 -k -p $(word 2,$(subst ., ,${SUBMISSION})))
MODELNAME  := $(word 4,$(subst ., ,${SUBMISSION}))


.PHONY: all
all:
	${MAKE} ${CONFERENCE}-news-systems
	${MAKE} eval-all
	rm -fr ${CONFERENCE}-news-systems

.PHONY: wmt21
wmt21:
	${MAKE} CONFERENCE=wmt21 all

.PHONY: wmt22
wmt22:
	${MAKE} CONFERENCE=wmt22 all



.PHONY: eval
eval:
	${MAKE} -C ../../ \
		USER=${PROVIDER} \
		MODELNAME=${MODELNAME} \
		BENCHMARK=${BENCHMARK} \
		LANGPAIR=${LANGPAIR} \
		FILE=${PWD}/${SUBMISSIONS_DIR}/${SUBMISSION} \
	eval

SUBMISSIONS_DONE = $(patsubst %,${CONFERENCE}/%.done,${SUBMISSIONS})

.PHONY: eval-all
eval-all: ${SUBMISSIONS_DONE}

${SUBMISSIONS_DONE}:
	${MAKE} SUBMISSION=$(notdir $(@:.done=)) eval
	@mkdir -p $(dir $@)
	@touch $@

${CONFERENCE}-news-systems:
	git clone https://github.com/wmt-conference/${CONFERENCE}-news-systems.git


