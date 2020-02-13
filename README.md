# TACC Machine Learning Containers


Containers for running ML applications on TACC GPU sysems

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
    <td>[Maverick2](https://portal.tacc.utexas.edu/user-guides/maverick2)</td>
    <td>[RTX](https://fronteraweb.tacc.utexas.edu/user-guide/system/#gpu-nodes)</td>
    <td>[Longhorn](https://portal.tacc.utexas.edu/user-guides/longhorn)</td>
    <td>[Lonestar5](https://portal.tacc.utexas.edu/user-guides/lonestar5)</td>
  </tr>
  <tr>
    <td>9</td>
    <td>1.14</td>
    <td>1.3</td>
    <td></td>
    <td></td>
    <td></td>
    <td>[X](#centos7-cuda9-tf1.14-pt1.3)</td>
  </tr>
  <tr>
    <td>10</td>
    <td>1.15</td>
    <td>1.3</td>
    <td>[X](#centos7-cuda10-tf1.15-pt1.3)</td>
    <td>[X](#centos7-cuda10-tf1.15-pt1.3)</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>10</td>
    <td>1.15</td>
    <td>1.2</td>
    <td></td>
    <td></td>
    <td>[X](#ppc64le-centos7-cuda10-tf1.15-pt1.2)</td>
    <td></td>
  </tr>
  <tr>
    <td>10</td>
    <td>2</td>
    <td>1.3</td>
    <td>[X](#centos7-cuda10-tf2.0-pt1.3)</td>
    <td>[X](#centos7-cuda10-tf2.0-pt1.3)</td>
    <td></td>
    <td></td>
  </tr>
</table>

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
    <td>[Maverick2](https://portal.tacc.utexas.edu/user-guides/maverick2)</td>
    <td>[RTX](https://fronteraweb.tacc.utexas.edu/user-guide/system/#gpu-nodes)</td>
    <td>[Longhorn](https://portal.tacc.utexas.edu/user-guides/longhorn)</td>
    <td>[Lonestar5](https://portal.tacc.utexas.edu/user-guides/lonestar5)</td>
  </tr>
  <tr>
    <td>9</td>
    <td>1.14</td>
    <td>1.3</td>
    <td></td>
    <td></td>
    <td></td>
    <td>[X](#ubuntu16.04-cuda9-tf1.14-pt1.3)</td>
  </tr>
  <tr>
    <td>10</td>
    <td>1.15</td>
    <td>1.3</td>
    <td>[X](#ubuntu16.04-cuda10-tf1.15-pt1.3)</td>
    <td>[X](#ubuntu16.04-cuda10-tf1.15-pt1.3)</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>10</td>
    <td>1.15</td>
    <td>1.2</td>
    <td></td>
    <td></td>
    <td>[X](#ppc64le-ubuntu16.04-cuda10-tf1.15-pt1.2)</td>
    <td></td>
  </tr>
  <tr>
    <td>10</td>
    <td>2</td>
    <td>1.3</td>
    <td>[X](#ubuntu16.04-cuda10-tf2.0-pt1.3)</td>
    <td>[X](#ubuntu16.04-cuda10-tf2.0-pt1.3)</td>
    <td></td>
    <td></td>
  </tr>
</table>

## Image information

All images are hosted on [Docker Hub](https://hub.docker.com/r/tacc/tacc-ml/tags)

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
