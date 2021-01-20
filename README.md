
# Howto use the scripts

1. Setting the repository mirror if download speed is poor from the official site.
Edit the `.local_env` file (create if not exists), and add `OPENWRT_MIRROR` field to it,
for example:

    ```
    OPENWRT_MIRROR=mirrors.tuna.tsinghua.edu.cn/openwrt
    ```

    You should select the proper mirror that near to you.

1. change the openwrt version you wanted via `OPENWRT_VERSION` field in `env` file

    ```
    OPENWRT_VERSION=19.07.5
    ```
1. upload scripts to the openwrt instance

    ```
    ./upload_script.sh <host-to-upgrade>
    ```

    where `host-to-upgrade` is the host to be upgrade, we will sync scripts via `rsync`.
    Defined the host in ~/.ssh/config is recommended, else you will need to specified the host
    in `root@host` format.

1. ssh to the openwrt instance and cd to the `/etc/openwrt_upgrade_script` directory.

    ```
    ssh host-to-upgrade
    cd /etc/openwrt_upgrade_script
    ```
1. upgrade via `./upgrade.sh` command

1. After upgraded, router will reboot, this may take some time, **DO NOT HARD RESET or TURN OFF THE POWER**
1. After router start up, the upgrade is success.
ssh to the openwrt instance and cd to the `/etc/openwrt_upgrade_script` directory.
1. we should install extra package now. running the `./install.sh`

# TODO

* [ ] snapshot version supported
* [ ] keep all preinstalled pkg after upgrade. I prefer add a features directory, and collect the install script for each feature.
    and then, we can specified which feature we needed via hostname.
