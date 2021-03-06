#!/bin/bash

past_day_count=$1
if [ ! $past_day_count ]; then
	past_day_count=1;
fi
#待清除的索引匹配规则
index_prefix=$2
if [ ! $index_prefix ]; then
	index_prefix="@mysql-27*";
fi

es_host=$3
if [ ! $es_host ]; then
	es_host=localhost:9200;
fi
echo "准备清理掉ES[$es_host]内索引前缀为[$index_prefix]的超过当前时间前$past_day_count天的信息......"

function delete_indices() {
	index_name=$1
	index_date=$2
 comp_date=`date -d "$past_day_count day ago" +"%Y-%m-%d"`
 date1="$index_date 00:00:00"
 date2="$comp_date 00:00:00"

 t1=`date -d "$date1" +%s`
 t2=`date -d "$date2" +%s`

 if [ $t1 -le $t2 ]; then        
     curl -XDELETE http://$es_host/$index_name
 fi
}

curl -XGET http://$es_host/_cat/indices | awk -F" " '{print $3}' | egrep "$index_prefix" | sort | while read LINE
do   
	index_name=$LINE;
	index_date=`echo $LINE | awk -F"-" '{print $NF}' | egrep "[0-9]*\.[0-9]*\.[0-9]*" | uniq  | sed 's/\./-/g'`
	if [ $index_date ]; then 
	    delete_indices $index_name $index_date
 fi
done

echo "清理完成！"
