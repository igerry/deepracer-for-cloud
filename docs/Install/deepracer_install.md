### 0. install ubuntu-24.04-server 
    
- please DO NOT install default **docker** during linux install.
- please DO NOT install default **aws cli** during linux install.

### 1. essential setup
    
    # go to user home
    cd ~

    # build essential
    sudo apt-get update
    sudo apt-get install build-essential

    # [optional] install open vm tools
    sudo apt-get install open-vm-tools

    # install other tools
    sudo apt-get install jq awscli python3-boto3 docker-compose-plugin

    # install docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update 
    sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io
    
    # setup docker user
    groups $USER
    # add user to docker group
    sudo usermod -aG docker $USER
    sudo reboot

### 2. [optional] nvidia driver install if training on GPU

    # install Nvidia driver
    sudo ubuntu-drivers list --gpgpu
    sudo apt-get install nvidia-driver-550-open
    sudo reboot

    # test nvidia gpu status
    watch -n 5 nvidia-smi
    
    # Setting up NVIDIA Container Toolkit
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    # install the nvidia-docker2
    sudo apt-get update
    sudo apt-get install -y nvidia-docker2
    sudo reboot

    # check running docker containers
    docker ps -a
    # sudo systemctl restart docker
    # test nvidia gpu in cuda container
    docker run --rm --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi

### 3. deepracer-for-cloud setup

ref: https://aws-deepracer-community.github.io/deepracer-for-cloud/installation.html
    
    # install deepracer-for-cloud locally
    git clone https://github.com/igerry/deepracer-for-cloud.git
    # git clone https://github.com/aws-deepracer-community/deepracer-for-cloud.git
    cd deepracer-for-cloud
    # for traning on cpu
    bin/init.sh -c local -a cpu -s compose
    
    # for training on gpu
    # if running in vm, have to remove detecting gpu logic line[56-73] first
    # nano bin/init.sh
    # bin/init.sh -c local -a gpu -s compose

    # create local minio
    aws configure --profile minio
    AWS Access Key ID [None]: minioadmin
    AWS Secret Access Key [None]: minioadmin
    Default region name [None]: us-east-1
    Default output format [None]:
    # check minio configure
    nano ~/.aws/config
    nano ~/.aws/credentials

    # add DR_LOCAL_ACCESS_KEY_ID & DR_LOCAL_SECRET_ACCESS_KEY into environment settings
    nano system.env
    DR_LOCAL_S3_PROFILE=minio
    DR_LOCAL_S3_BUCKET=bucket
    DR_LOCAL_ACCESS_KEY_ID=minioadmin
    DR_LOCAL_SECRET_ACCESS_KEY=minioadmin
    # enable metrics boardcast
    DR_TELEGRAF_HOST=telegraf
    DR_TELEGRAF_PORT=8092
    dr-update

### 4. run training after reboot and login

    # activate deepracer
    cd deepracer-for-cloud
    source bin/activate.sh
    
    # check running docker containers
    docker ps -alq

    # set track
    nano run.env
    DR_WORLD_NAME=2024_reinvent_champ_ccw
    DR_EVAL_SAVE_MP4=True
    dr-update

    # modify reward function
    nano custom_files/reward_function.py
    
    # upload custom files
    dr-upload-custom-files

    # start training
    dr-start-training -w
    dr-stop-training
    
    # monitor viewer
    dr-start-viewer
    dr-stop-viewer
    dr-update-viewer
    # url: http://localhost:8100

    # monitor metrics
    dr-start-metrics
    dr-stop-metrics
    # url: http://localhost:3000

    # start evalutaion if needed, mp4 file will be output to S3
    dr-start-evalutation
    # url: http://localhost:9000 (account: minioadmin, password: minioadmin)

### 5. Manually Upload Trained Model to AWS DeepRacer for Racing

    # upload the best model to local S3
    # -d Dryrun means no overwrite
    # -b best
    # -L local
    dr-upload-model -bL -d
    dr-upload-model -bL

    # Locate Your Model Folder
    ```bash
    cd deepracer-for-cloud/data/minio/bucket
    ls -a
    ```

    # Login to AWS S3
    - Create a new bucket with default settings.
    - Inside the bucket, create a new folder.

    # Upload the Following Folders/Files to the S3 Bucket
    - `model/`
    - `ip/`
    - `reward_function.py`
    - `training_params.yaml`
   
    # (You can drag and drop these into the browser window.)

    # Copy the Bucket/Folder Prefix
    - Note down the path of the folder you uploaded.

    # Import Model in AWS Deepracer
    - Navigate to the AWS Deepracer model page.
    - Click on **Import Model**. s3://dodo-dr-bucket/rl-deepracer-sagemaker-1/
    - Paste the bucket/folder prefix.
    - Fill in the model name and description.
    - Click **Import** (the process will take approximately five minutes).

    # Evaluate or Enter Race
    - Once the import is complete, you can start evaluating the model or enter it into a race.





