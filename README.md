# Torizon Core Builder reference image builder and examples

The project is used as a reference for a small team, and can serve for educational purposes.
Do not expect eager maintanence or configuration.

In this README.md file I will both give information about the theory of operation, and the practical steps.
Example builder code (that will not be heavily maintained) is also presented.


## Preparing for kernel build work and/or device tree customization

In order to customize the image, and in particular device trees or device tree overlays, you need to get several repositories. It does not matter how exactly you get them,
and two options are provided, as the submodules is for convenience and not a must, but may complicate things at some points, as, well, submodules...

To set device tree overlays, you have to both download the kernel tree and the device tree overlays, so these are the examples that will be given here.
Perhaps some more submodules will be added later, as examples, but I do not gurantee that the documentation (this file) will be updated to represent them.

### Setup without submodules:

```
# It's tiny so no need to shallow clone
git clone -b toradex_6.6-2.2.x-imx git://git.toradex.com/linux-toradex.git device-trees
# You probably want to shallow clone
git clone --depth=1 -b toradex_6.6-2.2.x-imx git://git.toradex.com/linux-toradex.git linux
```

### Setup with submodules (which is likely what you have here)
You can use the steps without submodules if you want to. Otherwise, there may be some warnings depending on when you update the submodules, if you 
want to do a shallow clone. 

Below are steps for a shallow clone. Otherwise, if you don't care about your time and disk space, just run ```git submodule init ; git submoudle update --recursive```.

```
$ git submodule init
$ git submodule update --depth 1
```

Warnings that are fine and you may encounter will be of the form (assuming this project is cloned into _/tmp/wip_):
```
Cloning into '/tmp/wip/device-trees'...
Cloning into '/tmp/wip/linux'...
warning: You appear to have cloned an empty repository.
Submodule path 'device-trees': checked out '1c9cef0936e03d68cc7808b1b8c88e9138d8f951'
Unable to fetch in submodule path 'linux'; trying to directly fetch 5ccea04d70833da346501ac219f0181f23fac3a7:
remote: Enumerating objects: 89251, done.
remote: Counting objects: 100% (89251/89251), done.
remote: Compressing objects: 100% (84989/84989), done.
remote: Total 89251 (delta 8201), reused 21452 (delta 3328), pack-reused 0
Receiving objects: 100% (89251/89251), 244.25 MiB | 13.12 MiB/s, done.
Resolving deltas: 100% (8201/8201), done.
From git://git.toradex.com/linux-toradex
 * branch                5ccea04d70833da346501ac219f0181f23fac3a7 -> FETCH_HEAD
Submodule path 'linux': checked out '5ccea04d70833da346501ac219f0181f23fac3a7'
```



## Starting point - if you want to start on your own, regardless of this repository (or: How this repo started)

### How we got (and enable the environment of the) tcb:
Essentially we got the tcb-env-setup.sh and ran it as per the instructions in the [Torizon developer pages](https://developer.toradex.com/torizon/os-customization/torizoncore-builder-tool-customizing-torizoncore-images)

```
$ mkdir -p ~/tcbdir/ && cd ~/tcbdir/
$ wget https://raw.githubusercontent.com/toradex/tcb-env-setup/master/tcb-env-setup.sh
```

Then, on each terminal you must source the script
```
. tcb-env-setup.sh
```

Then, on the very first time you would want to create `tcbuild.yaml` by running
```
torizoncore-builder build --create-template
```

You could alternatively use another template, and some example templates are provided for you in the `tcbuild-templates/` folder. You can, e.g., either:
- Copy or link one of the templates there into the `tcbuild.yml` file before invoking `torizoncore-builder build`
- Invoke `torizoncore-builder build --file <your-file-name.yml>`

Then, the next steps would be
- Getting the kernel source tree, and the device tree (see the Setup sections above)
- Adding the customizations in the `tcbuild.yaml`
- You can then also add a *docker-compose* file in the  *bundle: compose-file* section

I will likely show examples for all of it later.

## Modifying the "Marketing" materials and the icon for the Toradex Easy Installer
If building from Yocto, you can modify the relevant files in
`torizon-yocto/layers/meta-toradex-bsp-common/recipes-bsp/tezi-metadata/files/`

Here, it makes sense there would be `icon` and `marketing` options in `tcbuild.yaml` but at the time of writing this document there are no such. 
Therefore my quick suggestion, is to:
1. Build an image with `torizoncore-builder build`. Assume it is built in `output_directory`
2. Copy your own `marketing.tar` and `toradexlinux.png` and overwrite the contents in `output_directory`

Then you can use the folder in `output_directory` as the TEZI installer input for your image.

Disclaimer: I don't work for Toradex, and I have never worked for Toradex, there might and there should be better solutions for everything I propose.

## Building offline
This is fully explained in [this short video](https://www.youtube.com/watch?v=_d6O4ZCholk&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=79]).

Assume the docker-compose.chromium-kiosk.yml example, and a particular torizon version, either from Toradex, or build with the Yocto Project.
The cache materials can be added as follows:
```
torizoncore-builder bundle --platform linux/arm64 containers/docker-compose/docker-compose.chromium-kiosk.yml
wget https://tezi.toradex.com/artifactory/torizoncore-oe-prerelease-frankfurt/scarthgap-7.x.y/nightly/209/verdin-imx8mp/torizon/torizon-docker/oedeploy/torizon-docker-verdin-imx8mp-Tezi_7.3.0-devel-20250429+build.209.tar
```

Then you can of course move them to a folder of your own, and make sure your `tcbuild.yml` file points to the right places.
For example:
```
mkdir caches_dir
mv torizon-docker*.tar bundle caches_dir
```

An example template file is available, and you can build it (as in the video) using
```
torizoncore-builder build --file tcbuild-templates/tcbuild.offline.containers_dtbs_kernelcmdline.yaml
```

## Using your own container registries and your own custom docker images
In order to bundle your own containers, you have to put them in registries. If you are working alone, you can use the local builds on your host and that is fine.
However, if you want to, for example use [ghcr.io] hosted containers, you have to:
- Build and push the containers them yourself
- Login to the container registry and get them. Since the build process here uses DIND (Docker in Docker), it needs to know how to login and to which registry.

An example, to build such a bundle is:
```
# $CR_PAT is a github classic Personal Access Token
torizoncore-builder bundle --platform linux/arm64 containers/docker-compose/docker-compose.fbdev-simple-test.yml    --bundle-directory caches_dir/bundle --login-to ghcr.io ronpscg $CR_PAT
```

You can of course select other docker compose files as well, and create the _bundle_ directory directly (we do trust you to know to handle the renames, should you need such). For example, you can create a bundle that requires docker login to another repository:
The equivalents to `--login to <registry> <username> <password/token>` and `--platform linux/arm64` are easily indentifiable in the `_tcbuild.yml_ file, and are not listed here.

### Note about private container registries
At the time of writing, the repo I showed in this example is private, so login is essential. If I find the time to create something without credentials (and if it is possible? I am not sure it is even for the public packages, but I have not tried that), I will update this comment line.


## Deploying the image
1. Via copying to USB or an sdcard and then using _TEZI_ (Toradex Easy Installer)
2. Via running ```torizoncore-builder images serve .``` and selecting the image in _TEZI_
3. Via `torizoncore-builder deploy` to a live device

### Deploying to a live image using ostree

This is done using:
```
$ torizoncore-builder deploy [your-branch] --remote-host [your-device-ip] --remote-username torizon --remote-password "<your password>"
```
Before rebooting you will see something like:

```
  torizon c9ad7b82108604b536f51aebf73a07ef19ce1765b57107ea989c1b213e4223c9.0 (pending)
    Version: 7.2.0-devel-20250405200544+build.0
    origin refspec: tcbuilder:c9ad7b82108604b536f51aebf73a07ef19ce1765b57107ea989c1b213e4223c9
* torizon d943cd9b213f75132d8c4708209ca2d80e9c5ae5fa34168521ccbb00d3673565.0
    Version: 7.2.0-devel-20250405200544+build.0-tcbuilder.20250409071721
    origin refspec: torizon
```

After rebooting you will see something like
```
torizon@verdin-imx8mp-15602169:~$ ostree admin status
* torizon c9ad7b82108604b536f51aebf73a07ef19ce1765b57107ea989c1b213e4223c9.0
    Version: 7.2.0-devel-20250405200544+build.0
    origin refspec: tcbuilder:c9ad7b82108604b536f51aebf73a07ef19ce1765b57107ea989c1b213e4223c9
  torizon d943cd9b213f75132d8c4708209ca2d80e9c5ae5fa34168521ccbb00d3673565.0 (rollback)
    Version: 7.2.0-devel-20250405200544+build.0-tcbuilder.20250409071721
    origin refspec: torizon
```

Note: if you used the IDE extension and the device is in Engineering mode, it keeps being in it. So at the time of writing this, I did not see an update like I would
want to, and I will deal with it later perhaps.

# More Notes

## A simple build example as per given in this repo
You can run `build-me.sh` . See the comments in it for more details.

added build-me.sh as an example of building an image. Ot was quickly hacked, and `tcb-env-setup.sh` had to be modified in order to have as it uses `torizoncore-builder` as an *alias* instead of being declared as function. I notified Toradex and I think that sooner or later this will be changed.
    
As per the time of writing, f you want things to be very automatic, you need to start from a tcbuild.yaml file that has the checked in `output: local: output_directory` , as I hacked the file very quickly and I added a sed statement from the top of my head and didn't bother to do more than that. 

Others are welcome to contribute, I would do it later but I don't want to spend too much time on something that is half educational.
    
If you want to use it as is, in a CI/CD flow, the easiest thing for you to do would be to just move output_directory after every build, and use output_directory as the target folder in the build you are working on.


## torizoncore builder container and reproducibility

While `tcb-env-setup.sh` does not update often, the `torizon/torizoncore-builder` docker image that actually does the TCB work may update.
This means that when you source an image, you may be prompted to update, as in the following output. 
Use your judgement, and potential reproducibility requirments, to decide for yourself whether you would like to update it or not.

Full output of the occurence of this example follows:

```
$ . tcb-env-setup.sh 
You may have an outdated version installed. Would you like to check for updates online? [y/n] y
Setting up TorizonCore Builder with version 3.

Pulling TorizonCore Builder...
3: Pulling from torizon/torizoncore-builder
725b616d8b01: Pull complete 
38a0d3c4618c: Pull complete 
d75b1a01c6a3: Pull complete 
5c5848b6fad7: Pull complete 
53a3200cd0fd: Pull complete 
1de6d905f6e7: Pull complete 
a3ba199f151b: Pull complete 
c3ba3850d30a: Pull complete 
6d74f181570c: Pull complete 
5731ffd4d650: Pull complete 
d651574fca16: Pull complete 
a493dfe49ed8: Pull complete 
388360d71232: Pull complete 
13b2f0d3491a: Pull complete 
92a2b332c7f0: Pull complete 
9e659f8fa02e: Pull complete 
8b80d2123b92: Pull complete 
17faf794b403: Pull complete 
69684297755e: Pull complete 
Digest: sha256:3d644246569e8c199dd35c1a1692b6a13219c80ffe95ebde697cd07d4afa7f2b
Status: Downloaded newer image for torizon/torizoncore-builder:3
docker.io/torizon/torizoncore-builder:3
Done!

Setup complete! TorizonCore Builder is now ready to use.
TorizonCore Builder internal status and image customizations will be stored in Docker volume named 'storage'.
********************
Important: When you run TorizonCore Builder, the tool can only access the files inside the current working directory. Files and directories outside of the current working directory, or links to files and directories outside of the current working directory, won't be visible to TorizonCore Builder. So please make sure that, when running TorizonCore Builder, all files and directories passed as parameters are within the current working directory.
Your current working directory is: /home/ron/2025/toradex/submoduletry/git-repos/imx8mp-torizon-7-stuff
********************
For more information, run 'torizoncore-builder -h' or go to https://developer.toradex.com/knowledge-base/torizoncore-builder-tool
```
