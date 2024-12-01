### 1. run training after reboot and login

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

### 2. Manually Upload Trained Model to AWS DeepRacer for Racing

    # upload the best model to local S3
    # -d Dryrun means no overwrite = test run
    # -b best
    # -L local
    dr-upload-model -bL -d
    dr-upload-model -bL
    # check url: http://192.168.115.19:9001/browser/bucket

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