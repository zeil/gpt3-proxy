# gpt3-proxy

This test is supposed to be run in `nvcr.io/nvidia/nemo:24.12` container. The test runs "training" of cutdown GPT3 (175B) with 1/4 of layer count, to fit in a single 8xH200 machine, layer dimensions and parallelism optimizations are kept the same as in original GPT3. 

## Running on a VM 

To run the test in a VM environment, first launch NeMo container in interactive mode (it may take some time to pull the image):

```
sudo docker run -it \
  --gpus all \
  --ipc=host \
  --privileged \
  -v ./gpt-proxy/cfg:/cfg \
  -v ./gpt-proxy/datasets:/datasets \
  -v ./gpt-proxy/results:/results \
  nvcr.io/nvidia/nemo:24.12 \
  /bin/bash
```

Default test will run with 8 CPU cores (no hyperthreading) per process (8 processes total), 4 processes per NUMA node.

You may edit the `cfg/launch.sh` script to change the CPU binding (`--map-by` and `--bind-to` arrguments).
For example, to launch with 2 CPUs per process, use `--map-by ppr:4:numa:pe=2`.


To launch the test, simply execute the `cfg/launch.sh` script (`ENABLE_NSYS_PROFILE` defaults to `false`):

```
root@5d03ce562800:/workspace# ENABLE_NSYS_PROFILE=true /cfg/launch.sh
Logging to: /results/5d03ce562800_20250624_111140/run_0/mpirun-log_5d03ce562800_20250624_111140.out
MPI job started (PID 37407)
```

**Note:** log file becomes available ~30 seconds after start when `NeMo` moves it to `run_0` subdir.

### Launching on 8xH100 machine

The test with 8xH100 machine uses `launch_h100.sh` script with  `gpt-proxy/cfg/gpt3_proxy_h100_hydra.yaml` configuration file. Differences with `gpt3_proxy.yaml`:
- reduced `num_layers` to 16 from 24;
- `virtual_pipeline_model_parallel_size` set to 4 to match new number of layers;

To alter CPU affinity, modify `--map-by` parameter in the `launch_h100.sh` script similar to launch on H200.

### Launching on 4 GPUs

The test with 4 GPUs uses `gpt-proxy/cfg/gpt3_proxy_smol_hydra.yaml` configuration file. Differences with `gpt3_proxy.yaml`:
- TP reduced to 2 from 4;
- `hidden_size`, `ffn_hidden_size` and `num_attention_heads` are cut by half;

Use `gpt-proxy/cfg/launch_smol.sh` script to launch. To launch on 4 GPUs within single NUMA, set `CUDA_VISIBLE_DEVICES=0,1,2,3`
and `--map-by ppr:4:numa:pe=<num_cores_per_gpu>`. To launch on 4 GPUs across two NUMAs, set `CUDA_VISIBLE_DEVICES=2,3,4,5`
`--map-by ppr:2:numa:pe=<num_cores_per_gpu>`.

## Running on Bare Metal (BM)

To run in a BM environment, some additional steps are required:
- Install Nvidia Driver and OFED as well as CUDA toolkit
- Install Nvidia Container Toolkit
- Add Nvidia Container Runtime to `containerd` runtime:
```
$ diff containerd-config.toml.bak /etc/containerd/config.toml
18a19,27
>     [plugins.cri.containerd.runtimes.runc]
>       runtime_type = "io.containerd.runc.v2"
>       [plugins.cri.containerd.runtimes.runc.options]
>         BinaryName = "/usr/bin/runc"
>
>     [plugins.cri.containerd.runtimes.nvidia]
>       runtime_type = "io.containerd.runc.v2"
>       [plugins.cri.containerd.runtimes.nvidia.options]
>         BinaryName = "/usr/bin/nvidia-container-runtime"
```
- Transfer the image as `.tar` file from your machine to BM and import it to `ctr`
- Add the BM node FQDN to `/etc/hosts` if not already there

After completing these steps you should be able to use `containerd` (already present on BM) to launch container with Nvidia GPU support.

To launch the container with interactive shell:

```
sudo ctr run --rm \
  --gpus 0 \
  --gpus 1 \
  --gpus 2 \
  --gpus 3 \
  --gpus 4 \
  --gpus 5 \
  --gpus 6 \
  --gpus 7 \
  --tty \
  --privileged \
  --net-host \
  --mount type=bind,src=/dev/infiniband,dst=/dev/infiniband,options=rbind:rw \
  --mount type=tmpfs,dst=/dev/shm,options=size=10g \
  --mount type=bind,src=/home/<username>/gpt-proxy/results,dst=/results,options=rbind:rw \
  --mount type=bind,src=/home/<username>/gpt-proxy/datasets,dst=/datasets,options=rbind:rw \
  --mount type=bind,src=/home/<username>/gpt-proxy/cfg,dst=/cfg,options=rbind:rw \
  nvcr.io/nvidia/nemo:24.12 \
  nemo-test \
  /bin/bash
```

You should be able to launch the `gpt3-proxy` training test with same commands as in VM environment.