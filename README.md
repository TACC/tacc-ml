# TACC Machine Learning Containers


Containers for running ML applications on TACC GPU sysems

## Image information

All images are hosted on [Docker Hub](https://hub.docker.com/r/tacc/tacc-ml/tags)

Please refer to our system and version tables which support the following base operating systems:

- [Centos7](#centos7-images)
- [Ubuntu 16.04](#ubuntu1604-images)

## Usage

```
$ module load tacc-singularity
$ singularity pull docker://tacc/tacc-ml:ppc64le-ubuntu16.04-cuda10-tf1.15-pt1.2
$ singularity exec --nv tacc-ml_ppc64le-ubuntu16.04-cuda10-tf1.15-pt1.2.sif python -c 'import tensorflow as tf; print(tf.test.is_gpu_available())'                                                           
```

## Development

Begin `FROM` an image that supports your target TACC system, and add any necessary packages from there.

```
FROM tacc/tacc-ml:ppc64le-ubuntu16.04-cuda10-tf1.15-pt1.2

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
    <td>Cuda</td>
    <td>TensorFlow</td>
    <td>PyTorch</td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/maverick2">Maverick2</a></td>
    <td><a href="https://fronteraweb.tacc.utexas.edu/user-guide/system/#gpu-nodes">RTX</a></td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/longhorn">Longhorn</a></td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/lonestar5">Lonestar5</a></td>
  </tr>
  <tr>
    <td>9</td>
    <td>1.14</td>
    <td>1.3</td>
    <td></td>
    <td></td>
    <td></td>
    <td><a href="#centos7-cuda9-tf1.14-pt1.3">X</a></td>
  </tr>
  <tr>
    <td>10</td>
    <td>1.15</td>
    <td>1.3</td>
    <td><a href="#centos7-cuda10-tf1.15-pt1.3">X</a></td>
    <td><a href="#centos7-cuda10-tf1.15-pt1.3">X</a></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>10</td>
    <td>1.15</td>
    <td>1.2</td>
    <td></td>
    <td></td>
    <td><a href="#ppc64le-centos7-cuda10-tf1.15-pt1.2">X</a></td>
    <td></td>
  </tr>
  <tr>
    <td>10</td>
    <td>2</td>
    <td>1.3</td>
    <td><a href="#centos7-cuda10-tf2.0-pt1.3">X</a></td>
    <td><a href="#centos7-cuda10-tf2.0-pt1.3">X</a></td>
    <td></td>
    <td></td>
  </tr>
</table>

### centos7-cuda10-tf1.15-pt1.3
* [Dockerfile](containers/tf-conda)
* URL: `tacc/tacc-ml:centos7-cuda10-tf1.15-pt1.3`
### centos7-cuda10-tf2.0-pt1.3
* [Dockerfile](containers/tf-conda)
* URL: `tacc/tacc-ml:centos7-cuda10-tf2.0-pt1.3`
### centos7-cuda9-tf1.14-pt1.3
* [Dockerfile](containers/tf-conda)
* URL: `tacc/tacc-ml:centos7-cuda9-tf1.14-pt1.3`
### ppc64le-centos7-cuda10-tf1.15-pt1.2
* [Dockerfile](containers/tf-ppc64le)
* URL: `tacc/tacc-ml:ppc64le-centos7-cuda10-tf1.15-pt1.2`

## Ubuntu16.04 Images
<table>
  <tr>
    <th></th>
    <th></th>
    <th></th>
    <th colspan="4">System</th>
  </tr>
  <tr>
    <td>Cuda</td>
    <td>TensorFlow</td>
    <td>PyTorch</td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/maverick2">Maverick2</a></td>
    <td><a href="https://fronteraweb.tacc.utexas.edu/user-guide/system/#gpu-nodes">RTX</a></td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/longhorn">Longhorn</a></td>
    <td><a href="https://portal.tacc.utexas.edu/user-guides/lonestar5">Lonestar5</a></td>
  </tr>
  <tr>
    <td>9</td>
    <td>1.14</td>
    <td>1.3</td>
    <td></td>
    <td></td>
    <td></td>
    <td><a href="#ubuntu16.04-cuda9-tf1.14-pt1.3">X</a></td>
  </tr>
  <tr>
    <td>10</td>
    <td>1.15</td>
    <td>1.3</td>
    <td><a href="#ubuntu16.04-cuda10-tf1.15-pt1.3">X</a></td>
    <td><a href="#ubuntu16.04-cuda10-tf1.15-pt1.3">X</a></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>10</td>
    <td>1.15</td>
    <td>1.2</td>
    <td></td>
    <td></td>
    <td><a href="#ppc64le-ubuntu16.04-cuda10-tf1.15-pt1.2">X</a></td>
    <td></td>
  </tr>
  <tr>
    <td>10</td>
    <td>2.0</td>
    <td>1.3</td>
    <td><a href="#ubuntu16.04-cuda10-tf2.0-pt1.3">X</a></td>
    <td><a href="#ubuntu16.04-cuda10-tf2.0-pt1.3">X</a></td>
    <td></td>
    <td></td>
  </tr>
</table>

### ppc64le-ubuntu16.04-cuda10-tf1.15-pt1.2
* [Dockerfile](containers/tf-ppc64le)
* URL: `tacc/tacc-ml:ppc64le-ubuntu16.04-cuda10-tf1.15-pt1.2`
### ubuntu16.04-cuda10-tf1.15-pt1.3
* [Dockerfile](containers/tf-conda)
* URL: `tacc/tacc-ml:ubuntu16.04-cuda10-tf1.15-pt1.3`
### ubuntu16.04-cuda10-tf2.0-pt1.3
* [Dockerfile](containers/tf-conda)
* URL: `tacc/tacc-ml:ubuntu16.04-cuda10-tf2.0-pt1.3`
### ubuntu16.04-cuda9-tf1.14-pt1.3
* [Dockerfile](containers/tf-conda)
* URL: `tacc/tacc-ml:ubuntu16.04-cuda9-tf1.14-pt1.3`
