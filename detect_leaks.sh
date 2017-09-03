#!/bin/bash

set -euf -o pipefail

whitelist="socket(AF_UNIX,
getsockopt(
setsockopt(
{sa_family=AF_NETLINK,
{sa_family=AF_UNIX,
sendto(.*, NULL, 0) =
recvfrom(.*, NULL, NULL) =
getpeername(.*) = -1"

if [ "$LEAK_CI_ALLOW_IP_PROTOCOL" == "1" ]
then
    whitelist="${whitelist}
socket(AF_"
    echo "Allowing IP."
fi

while read -r ip4_addr
do
    [[ ${ip4_addr} != "" ]] || break
    read -r ip4_port
    [[ ${ip4_port} != "" ]] || break
    echo "Allowing ${ip4_addr} port ${ip4_port}"
    whitelist="${whitelist}
{sa_family=AF_INET, sin_port=htons(${ip4_port}), sin_addr=inet_addr(\"${ip4_addr}\")}"
    #echo "${whitelist}"
done <<< "${LEAK_CI_ALLOW_IP4_ADDR_PORT}"

while read -r ip6_addr
do
    [[ ${ip6_addr} != "" ]] || break
    read -r ip6_port
    [[ ${ip6_port} != "" ]] || break
    echo "Allowing ${ip6_addr} port ${ip6_port}"
    whitelist="${whitelist}
{sa_family=AF_INET6, sin6_port=htons(${ip6_port}), inet_pton(AF_INET6, \"${ip6_addr}\""
done <<< "${LEAK_CI_ALLOW_IP6_ADDR_PORT}"

echo ""
echo "strace whitelist:
${whitelist}"
echo ""

strace -xx -o >(stdbuf -i 0 -o 0 -e 0 grep -G --invert-match "${whitelist}" - | stdbuf -i 0 -o 0 -e 0 grep -E "(socket|getsockopt|setsockopt|getsockname|connect|bind|send|sendto|sendmsg|recv|recvfrom|recvmsg|accept|shutdown|listen|getpeername|socketpair|accept4|recvmmsg|sendmmsg)" - | tee strace_output.txt) -f -e trace=socket,getsockopt,setsockopt,getsockname,connect,bind,send,sendto,sendmsg,recv,recvfrom,recvmsg,accept,shutdown,listen,getpeername,socketpair,accept4,recvmmsg,sendmmsg $*

if [ -s strace_output.txt ]
then
    echo ""
    echo "Proxy leaks detected by strace:"
    echo ""
    cat strace_output.txt
    exit 1
fi

exit 0
