#!/bin/bash

if [ "$#" -lt 8 ] || [ "$#" -gt 9 ] ; then
    echo "Illegal number of parameters"
    echo "Usage: ./run_champsim_wrap.sh [branch_pred] [l1d_pref] [l2c_pref] [llc_pref] [llc_repl] [num_core] [N_WARM] [N_SIM] [OPTION]"
    exit 1
fi

BRANCH=${1}
L1D_PREFETCHER=${2}
L2C_PREFETCHER=${3}
LLC_PREFETCHER=${4}
LLC_REPLACEMENT=${5}
NUM_CORE=${6}
N_WARM=${7}
N_SIM=${8}
OPTION=${9}

TRACE_DIR=$PWD/traces
TRACE_TYPE=("client" "server" "spec")
TRACE_NUM=$(ls -1 ${TRACE_DIR} | wc -l)
CONTR_DIR=$PWD/sim/control
EXPER_DIR=$PWD/sim/experiment
STATS_DIR=$PWD/sim/stats
DEBUG_DIR=$PWD/sim/debug

if [ -z $PWD/sim ] || [ ! -d $PWD/sim ] ; then
	mkdir -p $PWD/sim
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

make clean
rm -r $PWD/bin

printf "\n[Build control group; ${CONTR_DIR}]\n"
printf "	Build executable simulation FILE with each l1i prefetcher...\n"
for PREF in ${CONTR_DIR}/*.l1i_pref
do
	[ -f "$PREF" ] || continue
	cp ${PREF} prefetcher/
	L1I_PREFETCHER=`basename ${PREF} .l1i_pref`
	BINARY="${BRANCH}-${L1I_PREFETCHER}-${L1D_PREFETCHER}-${L2C_PREFETCHER}-${LLC_PREFETCHER}-${LLC_REPLACEMENT}-${NUM_CORE}core"
	if [ -f $PWD/bin/${BINARY} ] ; then
		printf "		./build_champsim.sh ${BRANCH} ${L1I_PREFETCHER} ${L1D_PREFETCHER} ${L2C_PREFETCHER} ${LLC_PREFETCHER} ${LLC_REPLACEMENT} ${NUM_CORE} (Skipped)\n"
	else
		printf "		./build_champsim.sh ${BRANCH} ${L1I_PREFETCHER} ${L1D_PREFETCHER} ${L2C_PREFETCHER} ${LLC_PREFETCHER} ${LLC_REPLACEMENT} ${NUM_CORE}\n"
		bash $PWD/build_champsim.sh ${BRANCH} ${L1I_PREFETCHER} ${L1D_PREFETCHER} ${L2C_PREFETCHER} ${LLC_PREFETCHER} ${LLC_REPLACEMENT} ${NUM_CORE}
	fi
	rm -f $PWD/prefetcher/${L1I_PREFETCHER}.l1i_pref
done

printf "\n[Build Experimental Group; ${EXPER_DIR}]\n"
printf "	Build executable simulation FILE with each l1i prefetcher...\n"
for PREF in ${EXPER_DIR}/*.l1i_pref
do
	[ -f "$PREF" ] || continue
	cp ${PREF} $PWD/prefetcher/
	L1I_PREFETCHER=`basename ${PREF} .l1i_pref`
	BINARY="${BRANCH}-${L1I_PREFETCHER}-${L1D_PREFETCHER}-${L2C_PREFETCHER}-${LLC_PREFETCHER}-${LLC_REPLACEMENT}-${NUM_CORE}core"
	if [ -f $PWD/bin/${BINARY} ] ; then
		printf "		./build_champsim.sh ${BRANCH} ${L1I_PREFETCHER} ${L1D_PREFETCHER} ${L2C_PREFETCHER} ${LLC_PREFETCHER} ${LLC_REPLACEMENT} ${NUM_CORE} (Skipped)\n"
	else
		printf "		./build_champsim.sh ${BRANCH} ${L1I_PREFETCHER} ${L1D_PREFETCHER} ${L2C_PREFETCHER} ${LLC_PREFETCHER} ${LLC_REPLACEMENT} ${NUM_CORE}\n"
		bash $PWD//build_champsim.sh ${BRANCH} ${L1I_PREFETCHER} ${L1D_PREFETCHER} ${L2C_PREFETCHER} ${LLC_PREFETCHER} ${LLC_REPLACEMENT} ${NUM_CORE}
	fi
	rm -f $PWD/prefetcher/${L1I_PREFETCHER}.l1i_pref
done

printf "\n[Simulate each binaries from ${PWD}/bin/ on traces in ${TRACE_DIR}]\n"
mkdir -p $PWD/debug
for BINARY in $PWD/bin/*
do
	[ -f "$BINARY" ] || continue
	BINARY=`basename ${BINARY}`
	COUNT=1
	printf "	Simulating ${BINARY}...\n"
	for TRACE in ${TRACE_DIR}/*
	do
		TRACE=`basename ${TRACE} .champsimtrace.xz`
		PROCC=`expr ${COUNT} \* 50 / ${TRACE_NUM}`
		printf "		|"
		printf "%0.s=" $(seq 1 ${PROCC})
		if [ ${PROCC} -lt 50 ] ; then
			printf "%0.s " $(seq 0 `expr 49 - ${PROCC}`)
		fi
		printf "| ${COUNT} / ${TRACE_NUM}"
		for TYPE in ${TRACE_TYPE[@]}
		do
			if [[ ${TRACE} == ${TYPE}* ]] ; then
				if [ ! -d ${STATS_DIR}/${BINARY}/${TYPE} ] ; then
					mkdir -p ${STATS_DIR}/${BINARY}/${TYPE}
				fi
				if [ ! -d ${DEBUG_DIR}/${BINARY}/${TYPE}/${BINARY}-${TRACE}-${N_SIM} ] ; then
					mkdir -p ${DEBUG_DIR}/${BINARY}/${TYPE}/${BINARY}-${TRACE}-${N_SIM}
				fi
				if [ -f ${STATS_DIR}/${BINARY}/${TYPE}/${BINARY}-${TRACE}-${N_SIM}.stats ] ; then
					printf "	./run_champsim_nosuffix.sh ${BINARY} ${N_WARM} ${N_SIM} ${TRACE} (Skipped)\r"
				else
					printf "	./run_champsim_nosuffix.sh ${BINARY} ${N_WARM} ${N_SIM} ${TRACE}\r"
					bash $PWD/run_champsim_nosuffix.sh ${BINARY} ${N_WARM} ${N_SIM} ${TRACE}.champsimtrace.xz
					mv $PWD/results_${N_SIM}/${TRACE}.champsimtrace.xz-${BINARY}${OPTION}.txt ${STATS_DIR}/${BINARY}/${TYPE}/${BINARY}-${TRACE}-${N_SIM}.stats
					for DEBUG in $PWD/debug/*
					do
						mv ${DEBUG} ${DEBUG_DIR}/${BINARY}/${TYPE}/${BINARY}-${TRACE}-${N_SIM}
					done
				fi
			fi
		done
		COUNT=`expr ${COUNT} + 1`
	done
	printf "		|"
	printf "%0.s=" $(seq 1 50)
	printf "| ${TRACE_NUM} / ${TRACE_NUM}	simulated all traces"
	printf "%0.s " $(seq 1 100)
	echo ""
done
rm -r $PWD/results_${N_SIM}
rm -r $PWD/debug

:<<'END'
printf "\n[All stats are available at ./sim/stats/[BINARY]/]\n"
for BINARY in ${STATS_DIR}/*
do
	[ -d "$BINARY" ] || continue
	printf "	${BINARY}/\n"
	BINARY=`basename $BINARY`
	for TRACE_TYPE in ${STATS_DIR}/${BINARY}/*
	do
		TRACE_TYPE=`basename $TRACE_TYPE`
		printf "		${TRACE_TYPE}\n"
		for STATS in ${STATS_DIR}/${BINARY}/${TRACE_TYPE}/*
		do
			STATS=`basename $STATS`
			printf "			${STATS}\n"
		done
	done
done

printf "\n[All debug results are available at ./sim/debug/[BINARY]/]\n"
for BINARY in ${DEBUG_DIR}/*
do
	[ -d "$BINARY" ] || continue
	printf "	${BINARY}/\n"
	BINARY=`basename $BINARY`
	for TRACE_TYPE in ${DEBUG_DIR}/${BINARY}/*
	do
		TRACE_TYPE=`basename $TRACE_TYPE`
		printf "        "
		printf "		${TRACE_TYPE}\n"
		for DEBUG in ${DEBUG_DIR}/${BINARY}/${TRACE_TYPE}/*
		do
			DEBUG=`basename $DEBUG`
			printf "			${DEBUG}\n"
		done
	done
done
END
