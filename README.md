# TACC Machine Learning Containers


Containers for running ML applications on TACC GPU sysems

## Image information

All images are hosted on [Docker Hub](https://hub.docker.com/r/tacc/tacc-ml/tags)

Please refer to our system and version tables which support the following base operating systems:

- [Centos7](#centos7-images)
- [Ubuntu 20.04](#ubuntu2004-images)

## Usage

```
$ module load tacc-singularity
$ singularity pull docker://tacc/tacc-ml:ubuntu20.04-cuda11-tf2.6-pt1.10
$ singularity exec --nv tacc-ml_ubuntu20.04-cuda11-tf2.6-pt1.10.sif python -c 'import tensorflow as tf; print(tf.test.is_gpu_available())'                                                           
```

## Development

Begin `FROM` an image that supports your target TACC system, and add any necessary packages from there.

```
FROM tacc/tacc-ml:ubuntu20.04-cuda11-tf2.6-pt1.10

RUN conda install new_package
```

Once you are finished building your new container, push it to dockerhub and then pull to TACC.

## Centos7 Images
<table>
  <tr>
    <th></th>
    <th></th>
    <th></th>
    <th colspan="4">System</th>
  </tr>
  <tr>
    <td>CUDA</td>
    <td>TensorFlow</td>
    <td>PyTorch</td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/maverick2">Maverick2</a></td>
    <td><a href="https://fronteraweb.tacc.utexas.edu/user-guide/system/#gpu-nodes">Frontera/RTX</a></td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/longhorn">Longhorn</a></td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/lonestar6">Lonestar6</a></td>
  </tr>
  <tr>
    <td>11</td>
    <td>2.6</td>
    <td>1.10</td>
    <td><a href="#centos7-cuda11-tf2.6-pt1.10">X</a></td>
    <td><a href="#centos7-cuda11-tf2.6-pt1.10">X</a></td>
    <td></td>
    <td><a href="#centos7-cuda11-tf2.6-pt1.10">X</a></td>
  </tr>
  <tr>
    <td>11</td>
    <td>2.7</td>
    <td>1.10</td>
    <td></td>
    <td></td>
    <td><a href="#ppc64le-centos7-cuda11-tf2.7-pt1.10">X</a></td>
    <td></td>
  </tr>
</table>

### centos7-cuda11-tf2.6-pt1.10
* [Dockerfile](containers/tf-conda)
* URL: `tacc/tacc-ml:centos7-cuda11-tf2.6-pt1.10`
### ppc64le-centos7-cuda11-tf2.7-pt1.10
* [Dockerfile](containers/tf-ppc64le)
* URL: `tacc/tacc-ml:ppc64le-centos7-cuda11-tf2.7-pt1.10`

## Ubuntu20.04 Images
<table>
  <tr>
    <th></th>
    <th></th>
    <th></th>
    <th colspan="4">System</th>
  </tr>
  <tr>
    <td>CUDA</td>
    <td>TensorFlow</td>
    <td>PyTorch</td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/maverick2">Maverick2</a></td>
    <td><a href="https://fronteraweb.tacc.utexas.edu/user-guide/system/#gpu-nodes">Frontera/RTX</a></td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/longhorn">Longhorn</a></td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/lonestar6">Lonestar6</a></td>
  </tr>
  <tr>
    <td>11</td>
    <td>2.6</td>
    <td>1.10</td>
    <td><a href="#ubuntu20.04-cuda11-tf2.6-pt1.10">X</a></td>
    <td><a href="#ubuntu20.04-cuda11-tf2.6-pt1.10">X</a></td>
    <td></td>
    <td><a href="#ubuntu20.04-cuda11-tf2.6-pt1.10">X</a></td>
  </tr>
  <tr>
    <td>11</td>
    <td>2.7</td>
    <td>1.10</td>
    <td></td>
    <td></td>
    <td><a href="#ppc64le-ubuntu20.04-cuda11-tf2.7-pt1.10">X</a></td>
    <td></td>
  </tr>
</table>

### ubuntu20.04-cuda11-tf2.6-pt1.10
* [Dockerfile](containers/tf-conda)
* URL: `tacc/tacc-ml:ubuntu20.04-cuda11-tf2.6-pt1.10`
### ppc64le-ubuntu20.04-cuda11-tf2.7-pt1.10
* [Dockerfile](containers/tf-ppc64le)
* URL: `tacc/tacc-ml:ppc64le-ubuntu20.04-cuda11-tf2.7-pt1.10101010101010101010`
