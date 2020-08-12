#!/bin/bash
echo "Docker System Cleanup Script"
echo "Usuage: ./b.sh iamge_id : to remove only  the images IF no container is using this image"
echo "Usuage: ./b.sh -r image_id : to list the container which has these image dependecy and remove the container as well"
echo "usuage: ./b.sh : to list all images and containers running in the system and ask to delete per image"
doker_all(){
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
}

image_list(){
res1=`docker image rm $1`
  if [ $? == 0 ]
  then
   echo "remove successful for $1 "
  else
   echo "remove failed for $1"
  fi
}


image_container_match(){
test1=`docker image ls | grep $1`
test2=`echo "$test1" | awk '{print $1}'`
test=`docker container ls | grep "$test2"`
if [ ! -z "$test" ]
then
echo "The containers that are suing the image-ID $1 are : $test"
else
echo "No container is using this image $1"
fi
}
#Main

if [ $# != 0 ]
then
  if [ $1 == "-r" ]
  then
    image_container_match $2
  else
  # echo "Acceptable commands are -r IMAGE_ID"
  image_list ubuntu
  break;
  fi

elif [ $# == 0 ]
then
  doker_all
else
  echo "Nothing"
fi

