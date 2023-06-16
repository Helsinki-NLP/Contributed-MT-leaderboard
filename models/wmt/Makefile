# -*-makefile-*-
#
# insert WMT system outputs
#
#

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

.PHONY: wmt
wmt:
	${MAKE} CONFERENCE=wmt21 all
	${MAKE} CONFERENCE=wmt22 all

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

fetch-results: ${CONFERENCE}-news-systems

${CONFERENCE}-news-systems:
	git clone https://github.com/wmt-conference/${CONFERENCE}-news-systems.git


