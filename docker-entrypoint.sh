#!/bin/sh

if [ "$1" = 'redis-cluster' ]; then
    # Allow passing in cluster IP by argument or environmental variable
    IP="${2:-$IP}"

    if [ -z "$IP" ]; then # If IP is unset then set it to 0.0.0.0
        IP=0.0.0.0
    fi

    echo " -- IP Before trim: '$IP'"
    IP=$(echo ${IP}) # trim whitespaces
    echo " -- IP Before split: '$IP'"
    IP=${IP%% *} # use the first ip
    echo " -- IP After trim: '$IP'"

    if [ -z "$INITIAL_PORT" ]; then # Default to port 7000
      INITIAL_PORT=7000
    fi

    if [ -z "$MASTERS" ]; then # Default to 3 masters
      MASTERS=3
    fi

    if [ -z "$SLAVES_PER_MASTER" ]; then # Default to 0 slave for each master
      SLAVES_PER_MASTER=0
    fi

    if [ -z "$BIND_ADDRESS" ]; then # Default to any IPv4 address
      BIND_ADDRESS=0.0.0.0
    fi

    max_port=$(($INITIAL_PORT + $MASTERS * ( $SLAVES_PER_MASTER  + 1 ) - 1))
    first_standalone=$(($max_port + 1))
    if [ "$STANDALONE" = "true" ]; then
      STANDALONE=2
    fi
    if [ ! -z "$STANDALONE" ]; then
      max_port=$(($max_port + $STANDALONE))
    fi

    redis_cluster_template=$(cat /redis-conf/redis-cluster.tmpl)
    redis_template=$(cat /redis-conf/redis.tmpl)
    redis_sentinel_template=$(cat /redis-conf/sentinel.tmpl)

    for port in $(seq $INITIAL_PORT $max_port); do
      mkdir -p /redis-conf/${port}
      mkdir -p /redis-data/${port}

      if [ -e /redis-data/${port}/nodes.conf ]; then
        rm /redis-data/${port}/nodes.conf
      fi

      if [ -e /redis-data/${port}/dump.rdb ]; then
        rm /redis-data/${port}/dump.rdb
      fi

      if [ -e /redis-data/${port}/appendonly.aof ]; then
        rm /redis-data/${port}/appendonly.aof
      fi

      if [ "$port" -lt "$first_standalone" ]; then
        echo "$redis_cluster_template" | \
            sed -e "s/\${BIND_ADDRESS}/${BIND_ADDRESS}/g" \
                -e "s/\${PORT}/${port}/g" \
            > /redis-conf/${port}/redis.conf
        nodes="$nodes $IP:$port"
      else
        echo "$redis_template" | \
            sed -e "s/\${BIND_ADDRESS}/${BIND_ADDRESS}/g" \
                -e "s/\${PORT}/${port}/g" \
             > /redis-conf/${port}/redis.conf
      fi

      if [ "$port" -lt $(($INITIAL_PORT + $MASTERS)) ]; then
        if [ "$SENTINEL" = "true" ]; then
          echo "$redis_sentinel_template" | \
              sed -e "s/\${SENTINEL_PORT}/$((port - 2000))/g" \
                  -e "s/\${PORT}/${port}/g" \
              > /redis-conf/sentinel-${port}.conf
          cat /redis-conf/sentinel-${port}.conf
        fi
      fi

    done

    sh /run-servers.sh $INITIAL_PORT $max_port

    redis-cli --version | grep -E "redis-cli 3.0|redis-cli 3.2|redis-cli 4.0"

    if [ $? -eq 0 ]
    then
      echo "Old redis-trib.rb is not supported"
      exit 1 
    else
      echo "Using redis-cli to create the cluster"
      echo "yes" | eval redis-cli --cluster create --cluster-replicas "$SLAVES_PER_MASTER" "$nodes"
    fi

    if [ "$SENTINEL" = "true" ]; then
      for port in $(seq $INITIAL_PORT $(($INITIAL_PORT + $MASTERS))); do
        redis-sentinel /redis-conf/sentinel-${port}.conf &
      done
    fi

    tail -f /var/log/redis/redis*.log
else
  exec "$@"
fi
