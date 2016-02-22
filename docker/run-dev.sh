#!/bin/sh -e

DIR=$(cd $(dirname "$0") && pwd)

SRC_DIR=${DIR}/..

dir_list() {
  echo $1/opt/visallo/config \
       $1/opt/visallo/lib \
       $1/opt/visallo/logs \
       $1/var/log/hadoop \
       $1/var/log/accumulo \
       $1/var/log/elasticsearch \
       $1/tmp/zookeeper \
       $1/var/lib/hadoop-hdfs \
       $1/var/local/hadoop \
       $1/opt/elasticsearch/data \
       $1/opt/rabbitmq/var \
       $1/opt/jetty/webapps \
       $1/opt/maven/repository
}

if [ $(uname) = 'Linux' ]; then
  set +e
  docker ps &>/dev/null
  if [ $? -ne 0 ]; then
    sudo docker ps &>/dev/null
    if [ $? -eq 0 ]; then
      SUDO=sudo
    else
      echo 'ERROR: failed to run docker (even with sudo)'
      exit 1
    fi
  fi
  set -e
else
  SUDO=
fi

VM_NAME='visallo-dev'

while [ $# -gt 1 ]
do
  key="$1"

  case ${key} in
    --windows)
      USE_VM='true'
      ;;
    --vm)
      VM_NAME="$2"
      shift
      ;;
    *)
      ;;
  esac
  shift
done

if [ $(uname) = 'Darwin' -o "${USE_VM}" = 'true' ]; then
  SPLIT_PERSISTENT_DIR='true'

  which docker-machine > /dev/null
  if [ $? -eq 0 ]; then
    VM_SSH="docker-machine ssh ${VM_NAME}"
  else
    VM_SSH=
  fi
fi

if [ $(uname) = 'Darwin' -o "${SPLIT_PERSISTENT_DIR}" = 'true' ]; then
  dev=$(${VM_SSH} "blkid -L boot2docker-data")
  mnt=$(echo "$(${VM_SSH} mount)" | awk -v dev=${dev} '$1 == dev && !seen {print $3; seen = 1}')
  uid=$(${VM_SSH} "id -u")
  gid=$(${VM_SSH} "id -g")
  PERSISTENT_DIR=${mnt}/visallo-dev-persistent
  ${VM_SSH} "sudo mkdir -p ${PERSISTENT_DIR}"
  ${VM_SSH} "sudo chown -R ${uid}:${gid} ${PERSISTENT_DIR}"
  ${VM_SSH} "mkdir -p $(dir_list ${PERSISTENT_DIR})"
  LOCAL_PERSISTENT_DIR=${DIR}/visallo-dev-persistent
  mkdir -p $(dir_list ${LOCAL_PERSISTENT_DIR})
  touch ${LOCAL_PERSISTENT_DIR}/NOT_ALL_OF_YOUR_FILES_ARE_HERE
  touch ${LOCAL_PERSISTENT_DIR}/OTHER_FILES_ARE_PERSISTED_INSIDE_THE_BOOT2DOCKER_VM
else
  PERSISTENT_DIR=${DIR}/visallo-dev-persistent
  mkdir -p $(dir_list ${PERSISTENT_DIR})
  LOCAL_PERSISTENT_DIR=${DIR}/visallo-dev-persistent
fi


${SUDO} cp \
  ${DIR}/../config/log4j.xml \
  ${DIR}/../config/visallo.properties \
  ${DIR}/../config/visallo-accumulo.properties \
  ${DIR}/../config/visallo-elasticsearch.properties \
  ${DIR}/../config/visallo-hadoop.properties \
  ${DIR}/../config/visallo-rabbitmq.properties \
  ${DIR}/../config/visallo-zookeeper.properties \
  ${LOCAL_PERSISTENT_DIR}/opt/visallo/config/

(cd ${DIR} &&
  ${SUDO} docker run \
  -v ${SRC_DIR}:/opt/visallo-source \
  -v ${PERSISTENT_DIR}/var/log:/var/log \
  -v ${PERSISTENT_DIR}/tmp:/tmp \
  -v ${PERSISTENT_DIR}/var/lib/hadoop-hdfs:/var/lib/hadoop-hdfs \
  -v ${PERSISTENT_DIR}/var/local/hadoop:/var/local/hadoop \
  -v ${PERSISTENT_DIR}/opt/elasticsearch/data:/opt/elasticsearch/data \
  -v ${PERSISTENT_DIR}/opt/maven/repository:/opt/maven/repository \
  -v ${LOCAL_PERSISTENT_DIR}/opt/visallo:/opt/visallo \
  -v ${LOCAL_PERSISTENT_DIR}/opt/jetty/webapps:/opt/jetty/webapps \
  -p 2181:2181 `# ZooKeeper` \
  -p 5672:5672 `# RabbitMQ` \
  -p 5673:5673 `# RabbitMQ` \
  -p 8020:8020 `# Hadoop: HDFS` \
  -p 8032:8032 `# Hadoop: Resource Manager` \
  -p 8042:8042 `# Hadoop: Node Manager: Web UI` \
  -p 8080:8080 `# Jetty HTTP` \
  -p 8088:8088 `# Hadoop: Resource Manager: Web UI` \
  -p 8443:8443 `# Jetty HTTPS` \
  -p 9000:9000 `# Hadoop: Name Node: Metadata Service` \
  -p 9200:9200 `# Elasticsearch` \
  -p 9300:9300 `# Elasticsearch` \
  -p 9997:9997 `# Accumulo` \
  -p 9999:9999 `# Accumulo` \
  -p 15672:15672 `# RabbitMQ: Web UI` \
  -p 50010:50010 `# Hadoop: Data Node: Data transfer` \
  -p 50020:50020 `# Hadoop: Data Node: Metadata operations` \
  -p 50030:50030 `# Hadoop: Job Tracker` \
  -p 50060:50060 `# Hadoop: Task Tracker: Web UI` \
  -p 50070:50070 `# Hadoop: Name Node: Web UI` \
  -p 50075:50075 `# Hadoop: Data Node: Web UI` \
  -p 50090:50090 `# Hadoop: Secondary Name Node` \
  -p 50095:50095 `# Accumulo: Web UI` \
  -p 10001:10001 \
  -p 10002:10002 \
  -p 10003:10003 \
  -p 10004:10004 \
  -p 10005:10005 \
  -p 10006:10006 \
  -i \
  -t \
  -h visallo-dev \
  visallo/dev \
  "$@"
)
