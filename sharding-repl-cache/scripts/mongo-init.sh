#!/bin/bash


echo "initialize config"
docker compose exec -it configSvr mongosh --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSvr:27017" }
    ]
  }
);
EOF

echo "initialize shard-1"
docker compose exec -it shard1-r1 mongosh --port 27011 --quiet <<EOF
rs.initiate(
    {_id: "shard1", members: [
        {_id: 1, host: "shard1-r1:27011"},
        {_id: 2, host: "shard1-r2:27012"},
        {_id: 3, host: "shard1-r3:27013"}
    ]}) 
exit();
EOF

echo "initialize shard-2"
docker compose exec -it shard2-r1 mongosh --port 27014 --quiet <<EOF
rs.initiate({_id: "shard2", members: [
    {_id: 4, host: "shard2-r1:27014"},
    {_id: 5, host: "shard2-r2:27015"},
    {_id: 6, host: "shard2-r3:27016"}
]})
exit();
EOF

echo "initialize router"
docker compose exec -it mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard( "shard1/shard1-r1:27011");
sh.addShard( "shard2/shard2-r1:27014");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
use somedb;
print("populating data...");
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
db.helloDoc.countDocuments();
exit();
EOF

echo "check shard-1 documents count and replicas status"
docker compose exec -it shard1-r1 mongosh --port 27011 --quiet <<EOF
rs.status()
use somedb;
db.helloDoc.countDocuments();
exit();
EOF

echo "check shard-2 documents count and replicas status"
docker compose exec -it shard2-r1 mongosh --port 27014 --quiet <<EOF
rs.status()
use somedb;
db.helloDoc.countDocuments();
exit();
EOF