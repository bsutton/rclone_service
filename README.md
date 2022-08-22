A script for managing an rclone service on ubuntu.

Install rclone as a service and provides commands to start/stop rclone.

Firstly install rclone and create a remote.

Once installed run:

rclone_service install <remote name> <local mount point>

The local mount point must be a path to an empty (or non-existant) directory.

Once the service is installed you can run:

rclone_service start <remote name>

rclone_service stop <remote name>


