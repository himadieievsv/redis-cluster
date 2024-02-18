# Overview

Minimalistic Redis Cluster Docker Image.

This Docker image provides a Redis Cluster setup based on the official Redis distributive. It is designed to easily deploy a Redis Cluster environment for various use cases. Image have small size footprint.

# Build

Run build with Docker build command:
```bash
docker build -t<image name>:<image tag> . 
```

# Usage


## Pool from docker hub

To use this Docker image, follow these steps:
1. Pull the Docker image from Docker Hub:
   ```
   docker pull himadieievsv/redis-cluster:latest
   ```
2. Run the Redis Cluster container:
   ```
    docker run -d -p 7000-7002:7000-7002 himadieievsv/redis-cluster:latest
   ```

## Cluster generate script parameters 

This is list of available parameters with its default values.

| Environment variable |    Default |
|----------------------|-----------:|
| `INITIAL_PORT`       |       7000 |
| `MASTERS`            |          3 |
| `SLAVES_PER_MASTER`  |          0 | 
| `IP`                 |    0.0.0.0 | 
| `SENTINEL`           |      false |
| `STANDALONE`         |      false |
| `BIND_ADDRESS`       |    0.0.0.0 |

If the flag `"SENTINEL=true"` is passed there are 3 Sentinel nodes running on ports 5000 to 5002 matching cluster's master instances.
Check the [docker-entrypoint.sh](docker-entrypoint.sh) file for details on how parameters influence cluster setup.

# Version support list
Redis 7.0.x version:
- 7.0.10
  
Redis 7.2.x version:
- 7.2.4

# License

This repo is using the MIT LICENSE.

You can find it in the file [LICENSE](LICENSE)


# Credits
Forked from [docker-redis-cluster](https://github.com/Grokzen/docker-redis-cluster)