#!/bin/bash

### Get Data Virtual machines

qm list | sed '1d'  > list.txt
qm list | awk '{print $1}' | sed '1d' > pid.txt
qm list  | awk '{print $1,$3}' > qm.txt

ip_address () {

mac=$(qm config "$1" | awk '/net0/ { print tolower($2) }' | sed -r 's/virtio=(.*),.*/\1/g')
ip=$(arp-scan --interface=vmbr0 192.168.56.0/24 | grep "$mac" | awk '{print $1}')

echo $ip
}



cat pid.txt | while read line
do
  qm config $line | grep name | cut -d ' ' -f2- >> $line.txt
  qm config $line | grep ostype | cut -d ' ' -f2- >> $line.txt
  qm config $line | grep memory | cut -d ' ' -f2- >> $line.txt
  qm config $line | grep cores | cut -d ' ' -f2- >> $line.txt
  qm config $line | grep sockets | cut -d ' ' -f2- >> $line.txt
  ip --oneline addr show | awk '$3 == "inet" && $2 != "lo" { print $2 ": " $4 }' | awk '{print $2}' | sed '$ s/.$//' | sed '$ s/.$//' | sed '$ s/.$//' | head -n 1 >> $line.txt
  ip_address $line >> $line.txt

  ip=`sed -n '7p' $line.txt | cut -b 1-2`

  if [ -z "$ip" ]
  then
  sed -i "7i VM is stopped or QEMU is not configured" $line.txt
    sed -i '/^$/d' $line.txt
  fi

   second=`qm status $line -verbose | grep uptime | awk '{print $2}'`
  printf '%dd %dh:%dm:%ds\n' $((second/86400)) $((second%86400/3600)) $((second%3600/60)) $((second%60)) >> $line.txt

  sed -i 's/l26/Linux/g' $line.txt
done

#Get vmid
number=`cat pid.txt | wc -l`
i=0

while [ $i -lt $number ]
do
  i=`expr $i + 1`
  value=`cat pid.txt | sed -n "$i"'p'`
  echo $value >> ` cat pid.txt | sed -n "$i"'p'`.txt
done

#Get status

qm list | sed '1d' > status.txt

cat pid.txt | while read line
do
  cat qm.txt | grep $line | awk '{print $2}' >> $line.txt
done



# get HDD
cat list.txt | awk '{print $5}' > hdd.txt

number=`cat hdd.txt | wc -l`

i=0
while [ $i -lt $number ]; do
    i=`expr $i + 1`
    value=`cat hdd.txt | sed -n "$i"'p'`
    echo $value >> ` cat pid.txt | sed -n "$i"'p'`.txt
done


#Get description
cat pid.txt | while read line
do
  qm config $line | grep description | cut -d ' ' -f2- >> $line.txt
  sed -i "s/$/,/g" $line.txt

  sed -i 's/%0A//g' $line.txt
  sed -i 's/%3A//g' $line.txt

awk 'BEGIN { ORS = " " } { print }' $line.txt | sed 's/"[[:space:]]\+"/","/g'  > $line.csv
done


