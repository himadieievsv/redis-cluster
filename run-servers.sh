#!/bin/sh

initial_port="$1"
max_port="$2"

mkdir -p /var/log/redis /var/service/
runsvdir -P /var/service &

service_template ()
{
  local port=$1
  local count=$2
  echo "#!/bin/sh
/usr/local/bin/redis-server /redis-conf/$port/redis.conf --logfile /var/log/redis/redis-$count.log
"
}


count=1
for port in `seq $initial_port $max_port`; do
  mkdir -p /etc/sv/redis-$count
  service_template $port $count > /etc/sv/redis-$count/run
  chmod +x /etc/sv/redis-$count/run
  ln -s /etc/sv/redis-$count /var/service/
  count=$((count + 1))
done

sleep 3
