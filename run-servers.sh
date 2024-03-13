#!/bin/sh

initial_port="$1"
max_port="$2"

mkdir -p /var/log/redis /var/service/ /etc/sv

service_template ()
{
  local port=$1
  echo "#!/bin/sh
/usr/local/bin/redis-server /redis-conf/$port/redis.conf --logfile /var/log/redis/redis-$port.log
"
}

for port in `seq $initial_port $max_port`; do
  mkdir -p /etc/sv/redis-$port
  service_template $port > /etc/sv/redis-$port/run
  chmod +x /etc/sv/redis-$port/run
  ln -s /etc/sv/redis-$port /var/service/
done

runsvdir -P /var/service &
sleep 3

# Service status output and starting in case if not started yet for any reason
sv -v start /var/service/*
