#!/bin/bash

export NEMO_CONFIG="gpt3_proxy_smol_hydra.yaml"
export RUN_ID="$(hostname)_$(date +%Y%m%d_%H%M%S)"
mkdir -p /results/${RUN_ID}

echo "Logging to: /results/${RUN_ID}/run_0/mpirun-log_${RUN_ID}.out"

(
   OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
   mpirun -np 4 \
      --map-by ppr:4:numa:pe=8 \
      --bind-to core \
      --report-bindings \
      -x RUN_ID \
      -x ENABLE_NSYS_PROFILE \
      -x NEMO_CONFIG \
      -x CUDA_VISIBLE_DEVICES \
      bash -c "/cfg/nsys_wrapper_smol.sh" \
      > /results/${RUN_ID}/mpirun-log_${RUN_ID}.out 2>&1
) &

MPI_PID=$!
echo "MPI job started (PID $MPI_PID)"
