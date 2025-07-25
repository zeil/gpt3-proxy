# setup env
export TRANSFORMERS_OFFLINE=1
export HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface/hub
export TORCH_NCCL_AVOID_RECORD_STREAMS=1
export NCCL_NVLS_ENABLE=0
export NVTE_DP_AMAX_REDUCE_INTERVAL=0
export NVTE_ASYNC_AMAX_REDUCTION=1
export HYDRA_FULL_ERROR=1

export NVTE_FWD_LAYERNORM_SM_MARGIN=8
export NVTE_BWD_LAYERNORM_SM_MARGIN=8
export NVTE_UB_SPLIT_AG=1

export NVTE_FUSED_ATTN=1
export PYTHONUNBUFFERED=1
export SLURM_UNBUFFEREDIO=1
export TORCHX_MAX_RETRIES=0
export TOKENIZERS_PARALLELISM=False

export PYTHONPATH=/opt/NeMo:\${PYTHONPATH}
export CUDA_DEVICE_MAX_CONNECTIONS=1
#export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-0,1,2,3,4,5,6,7}"
export UCX_TLS=tcp,shm,self # Need on BM to disable IB discovery by UCX for userbuffers
