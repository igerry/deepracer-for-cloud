### tensor flow log

    This TensorFlow binary is optimized to use available CPU instructions in performance-critical operations.
    To enable the following instructions: AVX2 AVX512F AVX512_VNNI AVX512_BF16 FMA, in other operations, rebuild TensorFlow with the appropriate compiler flags.

    # check cpu features
    cat /proc/cpuinfo | grep flags
    gcc -march=native -Q --help=target


### get tensor version from running docker

    docker ps -alq
    docker exec -it <container_name_or_id> python3 -c "import tensorflow as tf; print(tf.__version__)"

    >>> import numpy; print(numpy.__version__)
    1.24.3
    >>> import matplotlib; print(matplotlib.__version__)
    3.7.4
    >>> import scipy; print(scipy.__version__)
    1.10.1

    # 2024-11-14 17:19:35.329490: I tensorflow/core/util/port.cc:110] oneDNN custom operations are on. You may see slightly different numerical results due to floating-point round-off errors from different computation orders. To turn them off, set the environment variable `TF_ENABLE_ONEDNN_OPTS=0`.
    # 2024-11-14 17:19:35.367794: I tensorflow/core/platform/cpu_feature_guard.cc:182] This TensorFlow binary is optimized to use available CPU instructions in performance-critical operations.
    # To enable the following instructions: AVX2 AVX512F AVX512_VNNI AVX512_BF16 FMA, in other operations, rebuild TensorFlow with the appropriate compiler flags.
    # 2.13.1

### AMD 7945HX/7940HX supported extensions

    AVX2 , AVX512 , FMA3 , 
    AES , AMD-V , AVX , MMX-plus , SHA , x86-64 ,
    SSE , SSE2 , SSE3 , SSE4.1 , SSE4.2 , SSE4A , SSSE3

  -mavx2                                [enabled]
  -mavx512f                             [enabled]
  -mavx512vnni                          [enabled]
  -mfma                                 [enabled]

  -mavx512bf16                          [enabled]
  -mavx512bitalg                        [enabled]
  -mavx512bw                            [enabled]
  -mavx512cd                            [enabled]
  -mavx512dq                            [enabled]
  -mavx512f                             [enabled]
  -mavx512ifma                          [enabled]
  -mavx512vbmi                          [enabled]
  -mavx512vbmi2                         [enabled]
  -mavx512vl                            [enabled]
  -mavx512vnni                          [enabled]
  -mavx512vpopcntdq                     [enabled]

  -msse3                                [enabled]
  -msse4                                [enabled]
  -msse4.1                              [enabled]
  -msse4.2                              [enabled]
  -msse4a                               [enabled]
  -mssse3                               [enabled]
  
### tensor flow compile suggestion

For your CPU with AVX2, AVX512, and FMA3 support, the best compile options for TensorFlow are:
Use ***-march=native*** to optimize for your specific CPU architecture.
Include ***--copt flags: -mavx2, -mavx512f, and -mfma*** to enable specific instruction sets.

### tensor flow denpency

Create a Docker file: ***Dockerfile.optimized.1***

    FROM awsdeepracercommunity/deepracer-simapp:5.3.2-cpu

    RUN wget https://github.com/bazelbuild/bazel/releases/download/6.1.1/bazel-6.1.1-linux-x86_64 \
    && chmod +x bazel-6.1.1-linux-x86_64
    && mv bazel-6.1.1-linux-x86_64 /usr/local/bin/bazel

    RUN apt-get update && apt-get install -y \
        git \
        curl \
        patchelf \
        python3-dev \
        python3-pip \
        build-essential \
        openjdk-11-jdk \
        zip \
        unzip \
        zlib1g-dev \
        libhdf5-serial-dev \
        hdf5-tools \
        protobuf-compiler \
        libcurl3-dev \
        swig \
        libpython3-dev \
        libpython3-all-dev \
        software-properties-common

    RUN pip3 install --upgrade pip
    ENV TF_VERSION=2.13.1
    RUN git clone -b v$TF_VERSION https://github.com/tensorflow/tensorflow.git /tensorflow_src
    WORKDIR /tensorflow_src
    # Set environment variables for TensorFlow build, check cat .tf_configure.bazelrc
    ENV PYTHON_BIN_PATH=/usr/bin/python3
    ENV PYTHON_LIB_PATH=/usr/local/lib/python3.8/dist-packages
    ENV CC_OPT_FLAGS="-march=native"
    ENV TF_NEED_JEMALLOC=0
    ENV TF_NEED_GCP=0
    ENV TF_NEED_HDFS=0
    ENV TF_ENABLE_XLA=0
    ENV TF_NEED_OPENCL_SYCL=0
    ENV TF_NEED_CUDA=0
    ENV TF_NEED_ROCM=0
    ENV TF_NEED_MKL=0
    ENV TF_DOWNLOAD_CLANG=0
    ENV TF_SET_ANDROID_WORKSPACE=0
    # Run TensorFlow configuration
    RUN yes "" | ./configure

    # Build TensorFlow wheel package
    RUN bazel build --config=opt \
        --copt=-mavx2 \
        --copt=-mavx512f \
        --copt=-mavx512vnni \
        --copt=-mavx512bf16 \
        --copt=-mfma \
        //tensorflow/tools/pip_package:build_pip_package

    # [optional] build cmd for tensorflow-cpu on exsi vm
    # RUN bazel build --config=opt --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse --copt=-msse2 --copt=-msse3 --copt=-msse4 --copt=-msse4.1 --copt=-msse4.2 //tensorflow/tools/pip_package:build_pip_package

    bazel build //tensorflow/tools/pip_package:wheel --repo_env=WHEEL_NAME=tensorflow_cpu

    # Create the wheel package
    RUN ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
    # Uninstall existing TensorFlow
    # RUN pip3 uninstall -y tensorflow

    # Install the new TensorFlow wheel
    # RUN pip3 install /tmp/tensorflow_pkg/tensorflow-*.whl

    # Clean up source code and Bazel cache
    # RUN rm -rf /tensorflow_src \
        && rm -rf /root/.cache/bazel

Create a Docker file: ***Dockerfile.optimized.2***

    FROM awsdeepracercommunity/deepracer-simapp:5.3.2-cpu

    ENV TENSOR_FLOW_WHL=tensorflow-2.13.1-cp38-cp38-linux_x86_64.whl
    RUN wget http://192.168.115.191:8081/$TENSOR_FLOW_WHL

    # Uninstall existing TensorFlow
    RUN pip3 uninstall -y tensorflow-cpu \
    && pip3 install ./$TENSOR_FLOW_WHL \
    && rm ./$TENSOR_FLOW_WHL

# re-create docker img

    # build a new docker container with a tag deepracer-simapp-optimized
    docker build -t deepracer-simapp-optimized -f Dockerfile.optimized .

    # run dock image by name
    docker run -it deepracer-simapp-optimized /bin/bash

    # switch root to running container
    docker exec -it <id> /bin/bash

    # copy file from running container to host
    docker cp 0d9bc4711345:/tensorflow_src/tensorflow-2.13.0-cp38-cp38-linux_x86_64.whl ~/Projects/tensorflow-2.13.0-cp38-cp38-linux_x86_64.whl
    docker cp /home/igerry/Projects/libtensorflow_cc.so.2 0fd2275be3d0:/usr/local/lib/python3.8/dist-packages/tensorflow/libtensorflow_cc.so.2

    # list installed tensorflow
    pip3 list | grep tensorflow
    tensorflow-cpu                     2.13.1
    tensorflow-estimator               2.13.0
    tensorflow-io-gcs-filesystem       0.34.0
    tensorflow-probability             0.21.0

    # tag image with new tag
    docker image tag deepracer-simapp-optimized gerrywang/deepracer-simapp;5.3.2-cpu

    # remove images
    docker image remove $(docker ps -a)
    docker rmi $(docker ps -a)
    docker rm $(docker ps -a -q)

    # clear local cache
    docker system prune -a
    docker image prune -a -f
    docker container prune -f
    # Volumes are never cleaned up automatically in Docker because they could contain valuable data.
    # docker volume prune -a -f
    docker ps --filter status=exited --filter status=dead -q

# an successful compile of Tensorflow from others

    https://gist.github.com/kmhofmann/e368a2ebba05f807fa1a90b3bf9a1e03
    https://github.com/mhoangvslev/tensorflow-compiler

    I have recently installed it from source and bellow are all the steps needed to install it from source with the mentioned instructions available.

    Other answers already describe why those messages are shown. My answer gives a step-by-step on how to isnstall, which may help people struglling on the actual installation as I did.

    Install Bazel
    Download it from one of their available releases, for example 0.5.2. Extract it, go into the directory and configure it: bash ./compile.sh. Copy the executable to /usr/local/bin: sudo cp ./output/bazel /usr/local/bin

    Install Tensorflow
    Clone tensorflow: git clone https://github.com/tensorflow/tensorflow.git Go to the cloned directory to configure it: ./configure

    It will prompt you with several questions, bellow I have suggested the response to each of the questions, you can, of course, choose your own responses upon as you prefer:

    Using python library path: /usr/local/lib/python2.7/dist-packages
    Do you wish to build TensorFlow with MKL support? [y/N] y
    MKL support will be enabled for TensorFlow
    Do you wish to download MKL LIB from the web? [Y/n] Y
    Please specify optimization flags to use during compilation when bazel option "--config=opt" is specified [Default is -march=native]: 
    Do you wish to use jemalloc as the malloc implementation? [Y/n] n
    jemalloc disabled
    Do you wish to build TensorFlow with Google Cloud Platform support? [y/N] N
    No Google Cloud Platform support will be enabled for TensorFlow
    Do you wish to build TensorFlow with Hadoop File System support? [y/N] N
    No Hadoop File System support will be enabled for TensorFlow
    Do you wish to build TensorFlow with the XLA just-in-time compiler (experimental)? [y/N] N
    No XLA JIT support will be enabled for TensorFlow
    Do you wish to build TensorFlow with VERBS support? [y/N] N
    No VERBS support will be enabled for TensorFlow
    Do you wish to build TensorFlow with OpenCL support? [y/N] N
    No OpenCL support will be enabled for TensorFlow
    Do you wish to build TensorFlow with CUDA support? [y/N] N
    No CUDA support will be enabled for TensorFlow
    The pip package. To build it you have to describe which instructions you want (you know, those Tensorflow informed you are missing).
    Build pip script: bazel build -c opt --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse --copt=-msse2 --copt=-msse3 --copt=-msse4 --copt=-msse4.1 --copt=-msse4.2 //tensorflow/tools/pip_package:build_pip_package

    Build pip package: bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

    Install Tensorflow pip package you just built: sudo pip install /tmp/tensorflow_pkg/tensorflow-1.2.1-cp27-cp27mu-linux_x86_64.whl

    Now next time you start up Tensorflow it will not complain anymore about missing instructions.