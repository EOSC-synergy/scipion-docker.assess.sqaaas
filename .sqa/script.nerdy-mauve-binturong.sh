(mkdir /im
cat <<EOF >> /im/auth.dat
# InfrastructureManager auth
type = InfrastructureManager; username = %s; password = %s
# OpenStack site using standard user, password, tenant format

id = incd; type = OpenStack; host = https://stratus.ncg.ingrid.pt:5000; username = %s; password = %s; tenant = eosc-synergy; domain = default; auth_version = 3.x_password

EOF
if [ -z "$IM_USER" ] || [ -z "$IM_PASS" ] || [ -z "$OPENSTACK_USER" ] || [ -z "$OPENSTACK_PASS" ]; then
  echo 'One or more credential variables are undefined (required: IM_USER, IM_PASS, OPENSTACK_USER, OPENSTACK_PASS)'
  exit 1
fi
printf "$(cat /im/auth.dat)" "${IM_USER}" "${IM_PASS}" "${OPENSTACK_USER}" "${OPENSTACK_PASS}" > /im/auth.dat
echo "Generated auth.dat file:"
ls -l /im/auth.dat
echo


cp im-topology-jenkins.yaml github.com/EOSC-synergy/scipion-docker/im-topology-jenkins.yaml
echo "Printing IM config file: github.com/EOSC-synergy/scipion-docker/im-topology-jenkins.yaml"
cat github.com/EOSC-synergy/scipion-docker/im-topology-jenkins.yaml
im_client.py -r "https://appsgrycap.i3m.upv.es:31443/im/" -a "/im/auth.dat" create_wait_outputs github.com/EOSC-synergy/scipion-docker/im-topology-jenkins.yaml > ./im_yaml.json
RETURN_CODE=$?
echo "im_client.py create_wait_outputs return code: ${RETURN_CODE}"
echo "Infrastructure Manager output:"
cat ./im_yaml.json
awk "/\{/,/\}/ { print $1 }" ./im_yaml.json > ./im_yaml_aux.json
echo "Infrastructure Manager output (only json part):"
cat ./im_yaml_aux.json
echo
INFID=$(jq -r '[ .infid ] | .[]' ./im_yaml_aux.json)
echo "INFID=${INFID}"
if [ ${RETURN_CODE} -eq 0 ] && ! [[ -z "${INFID}" && "x${INFID}x" == "xnullx" ]]; then
  echo "Deployment finished with success. Logs:"
  im_client.py -r "https://appsgrycap.i3m.upv.es:31443/im/" -a "/im/auth.dat" getcontmsg ${INFID}
  echo
  im_client.py -r "https://appsgrycap.i3m.upv.es:31443/im/" -a "/im/auth.dat" destroy ${INFID}
  echo "im_client.py destroy return code: $?"
elif ! [[ -z "${INFID}" && "x${INFID}x" == "xnullx" ]]; then
  echo "Deployment failed. Logs:"
  im_client.py -r "https://appsgrycap.i3m.upv.es:31443/im/" -a "/im/auth.dat" getcontmsg ${INFID}
  echo
  im_client.py -r "https://appsgrycap.i3m.upv.es:31443/im/" -a "/im/auth.dat" destroy ${INFID}
  echo "im_client.py destroy return code: $?"
  exit ${RETURN_CODE}
else
  exit ${RETURN_CODE}
fi
)