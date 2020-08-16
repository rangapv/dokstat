#!/bin/bash
#echo "Docker System Cleanup Script"
#echo "Usuage: ./b.sh iamge_id : to remove only  the images IF no container is using this image"
#echo "Usuage: ./b.sh -r image_id : to list the container which has these image dependecy and remove the container as well"
#echo "usuage: ./b.sh : to list all images and containers running in the system and ask to delete per image"
#echo "usuage: ./b.sh -d : list the total number of images and any dangling images present"
#echo "usuage: ./b.sh -c image_id " list the image if it has dependency or not"
#echo "usuage: ./b.sh -a :list images as a Parent or a Dependendant"
#echo "usuage: ./b.sh -s : list image offsprings"

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

image_dangle(){
count=0
dcount=0
while read -r line
do

repo=`echo "$line" | awk '{print $1}'`
id=`echo "$line" | awk '{print $3}'`

c1=`docker container ls | grep "$repo"`
i1=`docker container ls | grep "$id"`
if [ -z "$c1" ]
then
 if [ -z "$i1" ]
 then
 echo "The image with ID: $id and Repo: $repo is Dangling meaning not referenced by any running container"
 ((dcount++))
 fi
fi
if [ ! -z "$c1" ] || [ ! -z "$i1" ]
then
 ((count++))
fi

done < <(docker image ls)
echo "Total in use Images are : $count"
echo "Total Dangling Images are : $dcount"
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


image_ancestory(){
ccount=0
pcount=0
while read -r line
do
id=`echo "$line" | awk '{print $3}'`
dep=`docker inspect --format='{{.Parent}}' $id`

if [ -z "$dep" ]
then
  ((pcount++))
  echo "Image with ID:$id is a PARENT"
else
  ((ccount++))
  echo "Image with ID:$id is a CHILD"
fi 

done< <(docker image ls)
echo "Total Parent Images (Idependent)in this Node is: $pcount"
echo "Total Children Images (Dependent)in this Node is: $ccount"
}


image_array(){
cc="$#"
childcount=0
args=("$@")
cdc=${#args[@]}
echo "Number of layers in Parent with ImageID:${args[$((cc-1))]} is $((cdc-2))"
a=$1
for ((k=1; k<$cdc; k++))
do
#  echo "the parent id is ${args[$((cc-1))]}"
  while read -r line
  do
  id=`echo "$line" | awk '{print $3}'`
  dep=`docker inspect --format='{{.RootFS.Layers}}' $id`
#  res= `echo "$dep" | grep ${cd[${k}]}`
  parent1=`docker inspect --format='{{.Parent}}' $id`
  if [ ! -z "$parent1" ]
  then
  if [ "${args[$((cc-1))]}" != "$id" ]
  then
temp1="${args[${k}]}"
temp2=`echo "$temp1" | sed -e 's/\[//g; s/\]//g'`
temp3=`echo "$dep" | grep "$temp2"`
  if [ ! -z "$temp3" ]
  then
  echo "Image with ID: $id is a child of ${args[$((cc-1))]}"
  ((childcount++))
  break;
  fi
  fi
  fi
  done< <(docker image ls)
done
echo "The Parent with image ID:${args[$((cc-1))]} has:$childcount dependent"
}

image_array1(){
cc="$#"
childcount=0
args=("$@")
cdc=${#args[@]}
echo "Number of layers in Parent with ImageID:${args[$((cc-1))]} is $((cdc-2))"
pa="${args[$((cc-1))]}"
par1=`docker inspect --format='{{.RootFS.Layers}}' $pa`
patemp1=`echo "$par1" | sed -e 's/\[//g; s/\]//g'`
#echo "the patemp1 is $patemp1"

if [ $((cdc-2)) > 0 ]
then
  while read -r line
  do
  id=`echo "$line" | awk '{print $3}'`
  ch=`docker inspect --format='{{.Parent}}' $id`
  
  if [ ! -z "$ch" ] && [ $? == 0 ]
  then
  if [ "$pa" != "$id" ]
  then
  dep=`docker inspect --format='{{.RootFS.Layers}}' $id`
  temp2=`echo "$dep" | sed -e 's/\[//g; s/\]//g'`
  temp3=`echo "$temp2" | grep "$patemp1"`

  if [ ! -z "$temp3" ]
  then
  echo "Image with ID: $id is a child of $pa"
  ((childcount++))
  fi
  fi
  fi
  done< <(docker image ls)
echo "The Parent with image ID:${args[$((cc-1))]} has:$childcount dependent"
fi
}

image_dependency(){
pcount=0
while read -r line
do

id=`echo "$line" | awk '{print $3}'`
parent=`docker inspect --format='{{.Parent}}' $id`

if [ -z "$parent" ]
then
 ((pcount++))
dep=`docker inspect --format='{{.RootFS.Layers}}' $id`
res1=$?
df=`docker inspect --format='{{.RootFS.Layers}}' $id | awk '{split($0,a);print length(a);for (i=1;i<=length(a);i++) print a[i]}'&1>/dev/null`

if [ $res1 == 0 ]
then
image_array1 $df $id
fi
fi
done< <(docker image ls)
echo " The Total Parent Images(Independent) in this Node is: $pcount"
}

image_recurssion(){
echo "Inside recurssion"
re1=`(docker image rm $1 2>&1 >/dev/null)`
echo "res1 is $re1"
re2=`echo "$re1" |grep "dependent child images"`
if [ ! -z "$re1" ]
then
echo "This image $1 has Dependency"
fi
}

image_container_match(){
test1=`docker image ls | grep $1`
test2=`echo "$test1" | awk '{print $1}'`
test=`docker container ls | grep "$test2"`
if [ ! -z "$test" ]
then
echo "The containers that are using the image-ID $1 are : $test"
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
  elif [ $1 == "-d" ]
  then
    image_dangle
  elif [ $1 == "-c" ]
  then
    image_recurssion $2
  elif [ $1 == "-a" ]
  then
    image_ancestory
  elif [ $1 == "-s" ]
  then
    image_dependency
  else
  # echo "Acceptable commands are -r IMAGE_ID"
  image_list ubuntu
  fi

elif [ $# == 0 ]
then
  doker_all
else
  echo "Nothing"
fi
