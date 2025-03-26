#!/bin/bash

docker compose exec -it configSvr mongosh <<EOF
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

docker compose exec -it shard1-r1 mongosh --port 27011 <<EOF
rs.initiate(
    {_id: "shard1", members: [
        {_id: 1, host: "shard1-r1:27011"},
        {_id: 2, host: "shard1-r2:27012"},
        {_id: 3, host: "shard1-r3:27013"}
    ]}) 
EOF

docker compose exec -it shard2-r1 mongosh --port 27014 --quiet <<EOF
rs.initiate({_id: "shard2", members: [
    {_id: 4, host: "shard2-r1:27014"},
    {_id: 5, host: "shard2-r2:27015"},
    {_id: 6, host: "shard2-r3:27016"}
]}) 
EOF

docker exec -it mongos_router mongosh --port 27020 <<EOF
sh.addShard( "shard1/shard1-r1:27011");
sh.addShard( "shard2/shard2-r1:27014");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
db.helloDoc.countDocuments() 
EOF