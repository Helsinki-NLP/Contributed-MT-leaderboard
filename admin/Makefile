# -*-makefile-*-
#
#--------------------------------------------------------------------
#  make remove MODEL=modelname
#  make remove BENCHMARK=testset
#  make remove MODEL=modelname BENCHMARK=testset
#
#  make remove BENCHMARK=testset LANGPAIR=langpair
#  make remove MODEL=modelname BENCHMARK=testset LANGPAIR=langpair
#
#  make remove-devsets
#  make cleanup
#--------------------------------------------------------------------

REPOHOME := $(dir $(lastword ${MAKEFILE_LIST}))../
MAKEDIR  := ${REPOHOME}build/

# include ${MAKEDIR}env.mk
include ${MAKEDIR}config.mk
include ${MAKEDIR}remove.mk
include ${MAKEDIR}misc.mk
# include ${MAKEDIR}slurm.mk
