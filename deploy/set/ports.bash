set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
shift

all_delta="${1}"
shift

tikv_delta="${1}"
pd_delta="${3}"
tidb_delta="${2}"
tiflash_delta="${4}"
monitoring_delta="${5}"
grafana_delta="${6}"
monitored_delta="${7}"

prefix='tidb'

tikv_port=$[20160+tikv_delta+all_delta]
tikv_status_port=$[20180+tikv_delta+all_delta]
if [ "${tikv_port}" != '20160' ]; then
	echo "${prefix}.port.tikv=${tikv_port}" | tee -a "${env_file}"
	echo "${prefix}.port.tikv.status=${tikv_status_port}" | tee -a "${env_file}"
fi

pd_client_port=$[2379+pd_delta+all_delta]
pd_peer_port=$[2380+pd_delta+all_delta]
if [ "${pd_client_port}" != '2379' ]; then
	echo "${prefix}.port.pd.client=${pd_client_port}" | tee -a "${env_file}"
	echo "${prefix}.port.pd.peer=${pd_peer_port}" | tee -a "${env_file}"
fi

tidb_port=$[4000+tidb_delta+all_delta]
tidb_status_port=$[10080+tidb_delta+all_delta]
if [ "${tidb_port}" != '4000' ]; then
	echo "${prefix}.port.tidb=${tidb_port}" | tee -a "${env_file}"
	echo "${prefix}.port.tidb.status=${tidb_status_port}" | tee -a "${env_file}"
fi

flash_tcp_port=$[9000+tiflash_delta+all_delta]
flash_http_port=$[8123+tiflash_delta+all_delta]
flash_service_port=$[3930+tiflash_delta+all_delta]
flash_proxy_port=$[20170+tiflash_delta+all_delta]
flash_proxy_status_port=$[20292+tiflash_delta+all_delta]
flash_metrics_port=$[8234+tiflash_delta+all_delta]
if [ "${flash_tcp_port}" != '9000' ]; then
	echo "${prefix}.port.tiflash.tcp=${flash_tcp_port}" | tee -a "${env_file}"
	echo "${prefix}.port.tiflash.http=${flash_http_port}" | tee -a "${env_file}"
	echo "${prefix}.port.tiflash.service=${flash_service_port}" | tee -a "${env_file}"
	echo "${prefix}.port.tiflash.proxy=${flash_proxy_port}" | tee -a "${env_file}"
	echo "${prefix}.port.tiflash.proxy_status=${flash_proxy_status_port}" | tee -a "${env_file}"
	echo "${prefix}.port.tiflash.metrics=${flash_metrics_port}" | tee -a "${env_file}"
fi

monitoring_port=$[9090+monitoring_delta+all_delta]
if [ "${monitoring_port}" != '9090' ]; then
	echo "${prefix}.port.monitoring=${monitoring_port}" | tee -a "${env_file}"
fi

grafana_port=$[3000+grafana_delta+all_delta]
if [ "${grafana_port}" != '3000' ]; then
	echo "${prefix}.port.grafana=${grafana_port}" | tee -a "${env_file}"
fi

monitored_node_exporter_port=$[9100+monitored_delta+all_delta]
monitored_blackbox_exporter_port=$[9115+monitored_delta+all_delta]
if [ "${monitored_node_exporter_port}" != '9100' ]; then
	echo "${prefix}.port.monitored.node_exporter=${monitored_node_exporter_port}" | tee -a "${env_file}"
	echo "${prefix}.port.monitored.blackbox_exporter=${monitored_blackbox_exporter_port}" | tee -a "${env_file}"
fi

echo "[:)] ports config done"
