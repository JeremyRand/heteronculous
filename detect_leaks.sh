#!/bin/bash

# Copyright 2017-2019 Jeremy Rand.
#
# This file is part of Heteronculous.
#
# Heteronculous is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Heteronculous is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Heteronculous.  If not, see
# <https://www.gnu.org/licenses/>.

set -euf -o pipefail

whitelist="^[0-9]\+ \+socket(AF_UNIX,
^[0-9]\+ \+getsockopt(
^[0-9]\+ \+<... getsockopt resumed>
^[0-9]\+ \+setsockopt(
^[0-9]\+ \+listen(
^[0-9]\+ \+shutdown(
{sa_family=AF_NETLINK,
{sa_family=AF_UNIX[,}]
^[0-9]\+ \+sendto(.*, NULL, 0) = [0-9]\+$
^[0-9]\+ \+sendto(.*, NULL, 0) = -1
^[0-9]\+ \+sendto(.*, NULL, 0 <unfinished ...>$
^[0-9]\+ \+<... sendto resumed> ) *= [0-9]\+$
^[0-9]\+ \+recvfrom(.*, NULL, NULL) =
^[0-9]\+ \+<... recvfrom resumed>.*, NULL, NULL) =
^[0-9]\+ \+getpeername(.*) = -1
^[0-9]\+ \+recvmsg(.*{msg_name=NULL.*)
^[0-9]\+ \+recvmsg(.*{msg_namelen=0}.* = -1
^[0-9]\+ \+socketpair(AF_UNIX,
^[0-9]\+ \+sendmsg(.*{msg_name=NULL
^[0-9]\+ \+getpeername([0-9]\+, \+<unfinished ...>$
^[0-9]\+ \+getsockname([0-9]\+, \+<unfinished ...>$
^[0-9]\+ \+recvfrom([0-9]\+, \+<unfinished ...>$
^[0-9]\+ \+recvmsg([0-9]\+, \+<unfinished ...>$
^[0-9]\+ \+<... sendmsg resumed> ) *= [0-9]\+$
^[0-9]\+ \+<... setsockopt resumed> ) *= [0-9]\+$
^[0-9]\+ \+<... bind resumed> ) *= [0-9]\+$
^[0-9]\+ \+<... socket resumed> ) *= [0-9]\+$
^[0-9]\+ \+<... recvmsg resumed>.*{msg_name=NULL.*)
^[0-9]\+ \+<... recvmsg resumed>.*{msg_namelen=0}.*)
^[0-9]\+ \+<... connect resumed> ) *= -1"

if [ "${LEAK_CI_ALLOW_IP_PROTOCOL}" == "1" ]
then
    whitelist="${whitelist}
^[0-9]\+ \+socket(AF_"
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

strace -f -o >(stdbuf -i 0 -o 0 -e 0 grep -G --invert-match "${whitelist}" - | stdbuf -i 0 -o 0 -e 0 grep -E "(socket|getsockopt|setsockopt|getsockname|connect|bind|send|sendto|sendmsg|recv|recvfrom|recvmsg|accept|shutdown|listen|getpeername|socketpair|accept4|recvmmsg|sendmmsg)" - | tee strace_output.txt) -e trace=socket,getsockopt,setsockopt,getsockname,connect,bind,send,sendto,sendmsg,recv,recvfrom,recvmsg,accept,shutdown,listen,getpeername,socketpair,accept4,recvmmsg,sendmmsg $*

if [ -s strace_output.txt ]
then
    echo ""
    echo "Proxy leaks detected by strace:"
    echo ""
    cat strace_output.txt
    exit 1
fi

exit 0
