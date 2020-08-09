#!/bin/bash
echo "Docker System Cleanup Script"


echo "The docker containers in this SYSTEMS are:"
while read -r line
do
   echo "$line"
done < <(docker container ls)

echo "The docker images in this SYSTEMS are:"
while read -r line
do
  echo "$line"
tmp2=`echo "$line" | awk '{print $1}'`
echo "$tmp2"
echo "Enter y to delete"
read -u 1 user
if [ "$user" = "y" ]
then
  echo "Removing $tmp2"
  res=`docker image rm $tmp2`
  echo "The value of res is $res"
  if [ $? == 0 ]
  then
   echo "remove successful"
  else
   echo "remove failed"
  fi
fi
done < <(docker image ls)
