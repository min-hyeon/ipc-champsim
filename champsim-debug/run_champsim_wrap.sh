#!/bin/bash

if [ "$#" -ne 8 ]; then
    printf "Illegal number of parameters\n"
    printf "Usage: ./run_champsim_wrap.sh [BRANCH] [L1D_PREFETCHER] [L2C_PREFETCHER] [LLC_PREFETCHER] [LLC_REPLACEMENT] [NUM_CORE] [N_WARM] [N_SIM] [OPTION]\n"
    exit 1
fi

BRANCH=$1            # branch/*.bpred
L1D_PREFETCHER=$2    # prefetcher/*.l1d_pref
L2C_PREFETCHER=$3    # prefetcher/*.l2c_pref
LLC_PREFETCHER=$4    # prefetcher/*.llc_pref
LLC_REPLACEMENT=$5   # replacement/*.llc_repl
NUM_CORE=$6          # tested up to 8-core system
N_WARM=$7
N_SIM=$8
OPTION=$9

TRACE_DIR=./traces
CONTR_DIR=./sim/control
EXPER_DIR=./sim/experiment
STATS_DIR=./sim/stats
DEBUG_DIR=./sim/debug

TRACE_TYPE=("client" "server" "spec")

if [ -z ./sim ] || [ ! -d ./sim ] ; then
	mkdir -p ./sim
fi
if [ -z ${TRACE_DIR} ] || [ ! -d ${TRACE_DIR} ] ; then
	mkdir -p ${TRACE_DIR}
fi
if [ -z ${CONTR_DIR} ] || [ ! -d ${CONTR_DIR} ] ; then
	mkdir -p ${CONTR_DIR}
fi
if [ -z ${EXPER_DIR} ] || [ ! -d ${EXPER_DIR} ] ; then
    mkdir -p ${EXPER_DIR}
fi
if [ -z ${STATS_DIR} ] || [ ! -d ${STATS_DIR} ] ; then
	mkdir -p ${STATS_DIR}
fi
if [ -z ${DEBUG_DIR} ] || [ ! -d ${DEBUG_DIR} ] ; then
	mkdir -p ${DEBUG_DIR}
fi

printf "\n[Build control group; ./sim/controls/]\n"
printf "    "
printf "Build executable simulation FILE with each l1i prefetcher...\n"
for PREF in ${CONTR_DIR}/*.l1i_pref
do
	[ -f "$PREF" ] || continue
	cp ${PREF} ./prefetcher/
	L1I_PREFETCHER=`basename $PREF .l1i_pref`
	BINARY="${BRANCH}-${L1I_PREFETCHER}-${L1D_PREFETCHER}-${L2C_PREFETCHER}-${LLC_PREFETCHER}-${LLC_REPLACEMENT}-${NUM_CORE}core"
	if [ -f ./bin/${BINARY} ]; then
		printf "        "
		printf "./build_champsim.sh ${BRANCH} ${L1I_PREFETCHER} ${L1D_PREFETCHER} ${L2C_PREFETCHER} ${LLC_PREFETCHER} ${LLC_REPLACEMENT} ${NUM_CORE} (Skipped)\n"
	else
		printf "        "
		printf "./build_champsim.sh ${BRANCH} ${L1I_PREFETCHER} ${L1D_PREFETCHER} ${L2C_PREFETCHER} ${LLC_PREFETCHER} ${LLC_REPLACEMENT} ${NUM_CORE}\n\n"
		bash ./build_champsim.sh $BRANCH $L1I_PREFETCHER $L1D_PREFETCHER $L2C_PREFETCHER $LLC_PREFETCHER $LLC_REPLACEMENT $NUM_CORE
	fi
	rm -f ./prefetcher/"${L1I_PREFETCHER}.l1i_pref"
done

printf "\n[Build Experimental Group; ./sim/experiments/]\n"
printf "    "
printf "Build executable simulation FILE with each l1i prefetcher...\n"
for PREF in ${EXPER_DIR}/*.l1i_pref
do
	[ -f "$PREF" ] || continue
	cp ${PREF} ./prefetcher/
	L1I_PREFETCHER=`basename $PREF .l1i_pref`
	BINARY="${BRANCH}-${L1I_PREFETCHER}-${L1D_PREFETCHER}-${L2C_PREFETCHER}-${LLC_PREFETCHER}-${LLC_REPLACEMENT}-${NUM_CORE}core"
	if [ -f ./bin/${BINARY} ]; then
		printf "        "
		printf "./build_champsim.sh ${BRANCH} ${L1I_PREFETCHER} ${L1D_PREFETCHER} ${L2C_PREFETCHER} ${LLC_PREFETCHER} ${LLC_REPLACEMENT} ${NUM_CORE} (Skipped)\n"
	else
		printf "        "
		printf "./build_champsim.sh ${BRANCH} ${L1I_PREFETCHER} ${L1D_PREFETCHER} ${L2C_PREFETCHER} ${LLC_PREFETCHER} ${LLC_REPLACEMENT} ${NUM_CORE}\n\n"
		bash ./build_champsim.sh $BRANCH $L1I_PREFETCHER $L1D_PREFETCHER $L2C_PREFETCHER $LLC_PREFETCHER $LLC_REPLACEMENT $NUM_CORE
	fi
	rm -f ./prefetcher/"${L1I_PREFETCHER}.l1i_pref"
done

printf "\n[Simulate each binaries from ./bin/ on traces in ./dpc3_traces]\n"
for BINARY in ./bin/*
do
	[ -f "$BINARY" ] || continue
	BINARY=`basename $BINARY`
	if [ ! -d ./sim/stats/${BINARY}/ ]; then
		mkdir -p ./sim/stats/${BINARY}
	fi
	if [ ! -d ./sim/debug/${BINARY}/ ]; then
		mkdir -p ./sim/debug/${BINARY}
	fi
	printf "    Simulating ${BINARY}...\n"
	for TRACE in ${TRACE_DIR}/*
	do
		TRACE=`basename $TRACE`
		TRACE_BASENAME=`basename $TRACE .champsimtrace.xz`
		for TYPE in ${TRACE_TYPE[@]}
		do
			if [[ ${TRACE_BASENAME} == ${TYPE}* ]] ; then
				if [ ! -d ${STATS_DIR}/${BINARY}/${TYPE} ]; then
					mkdir -p ${STATS_DIR}/${BINARY}/${TYPE}
				fi
				if [ ! -d ${DEBUG_DIR}/${BINARY}/${TYPE} ]; then
					mkdir -p ${DEBUG_DIR}/${BINARY}/${TYPE}
				fi
				if [ -f ${STATS_DIR}/${BINARY}/${TYPE}/${BINARY}-${TRACE}-${N_SIM}.stats ]; then
					printf "        "
					printf "./run_champsim_nosuffix.sh ${BINARY} ${N_WARM} ${N_SIM} ${TRACE} (Skipped)\n"
				else
					printf "        "
					printf "./run_champsim_nosuffix.sh ${BINARY} ${N_WARM} ${N_SIM} ${TRACE}\n"
					bash ./run_champsim_nosuffix.sh ${BINARY} ${N_WARM} ${N_SIM} ${TRACE}
					mv ./results_${N_SIM}/${TRACE}-${BINARY}${OPTION}.txt ${STATS_DIR}/${BINARY}/${TYPE}/${BINARY}-${TRACE}-${N_SIM}.stats
					for DEBUG in ./debug/*
					do
						mv ${DEBUG} ${DEBUG_DIR}/${BINARY}/${TYPE}
					done
				fi
			fi
		done
	done
done
if [ -d ./results_${N_SIM}/ ]; then
	rm -r ./results_${N_SIM}
fi

printf "\n[All stats are available at ./sim/stats/[BINARY]/]\n"
for BINARY in ${STATS_DIR}/*
do
	[ -d "$BINARY" ] || continue
	printf "    "
	printf "${BINARY}/\n"
	BINARY=`basename $BINARY`
	for TRACE_TYPE in ${STATS_DIR}/${BINARY}/*
	do
		TRACE_TYPE=`basename $TRACE_TYPE`
		printf "        "
		printf "${TRACE_TYPE}\n"
		for STATS in ${STATS_DIR}/${BINARY}/${TRACE_TYPE}/*
		do
			STATS=`basename $STATS`
			printf "            "
			printf "${STATS}\n"
		done
	done
done

printf "\n[All debug results are available at ./sim/debug/[BINARY]/]\n"
for BINARY in ${DEBUG_DIR}/*
do
	[ -d "$BINARY" ] || continue
	printf "    "
	printf "${BINARY}/\n"
	BINARY=`basename $BINARY`
	for TRACE_TYPE in ${DEBUG_DIR}/${BINARY}/*
	do
		TRACE_TYPE=`basename $TRACE_TYPE`
		printf "        "
		printf "${TRACE_TYPE}\n"
		for DEBUG in ${DEBUG_DIR}/${BINARY}/${TRACE_TYPE}/*
		do
			DEBUG=`basename $DEBUG`
			printf "            "
			printf "${DEBUG}\n"
		done
	done
done

printf "\n"
