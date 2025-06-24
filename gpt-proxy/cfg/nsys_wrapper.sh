#!/bin/bash
set -ex

source /cfg/setup.sh

: "${ENABLE_NSYS_PROFILE:=false}"

export NSYS_EXTRA_OPTIONS=" \
    --sample=process-tree \
    --cpuctxsw=process-tree \
    --event-sample=system-wide \
    --backtrace=lbr \
    --event-sampling-interval=3 \
    --samples-per-backtrace=1 \
"

if [[ "${ENABLE_NSYS_PROFILE,,}" == "true" ]]; then
    export PROFILE_CMD="which nsys && nsys --version && nsys status --env && \
        mkdir -p /results/nsys/${RUN_ID}/ && \
        nsys profile \
            --output /results/nsys/${RUN_ID}/gpt3-proxy_8g_${RUN_ID}_%h_%q{OMPI_COMM_WORLD_LOCAL_RANK} \
            --nic-metrics=true \
            $NSYS_EXTRA_OPTIONS \
            --inherit-environment true \
            --force-overwrite true \
            --capture-range=cudaProfilerApi \
            --capture-range-end=stop \
            --stop-on-exit true \
            --trace cuda,nvtx \
        "
    export NSYS_TRAINER_OVERRIDES=" \
        model.nsys_profile.start_step=7 \
        model.nsys_profile.end_step=10 \
        model.nsys_profile.ranks=[0,1,2,3,4,5,6,7] \
        model.nsys_profile.enabled=True \
    "
    export TRAINER_MAX_STEPS=10
else
    export PROFILE_CMD=""
    export NSYS_TRAINER_OVERRIDES=""
    export TRAINER_MAX_STEPS=20
fi

export TRAIN_CMD="python3 -u /opt/NeMo/examples/nlp/language_modeling/megatron_gpt_pretraining.py \
  --config-path=/cfg \
  --config-name=gpt3_proxy_hydra.yaml \
  run.results_dir=/results \
  exp_manager.explicit_log_dir=/results/${RUN_ID} \
  model.fp8=True \
  trainer.max_steps=$TRAINER_MAX_STEPS \
  $NSYS_TRAINER_OVERRIDES "

echo "Running with CMD:"
echo "$PROFILE_CMD $TRAIN_CMD"

eval $PROFILE_CMD $TRAIN_CMD