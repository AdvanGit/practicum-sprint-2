echo "first request"
time curl -o /dev/null -s http://localhost:8080/helloDoc/users
echo
echo "second request"
time curl -o /dev/null -s http://localhost:8080/helloDoc/users
echo
echo "Redis cache status at JSON format"
info=$(docker compose exec -T redis_1 redis-cli INFO stats)

status=$(echo "$info" | grep -v '^#' | awk -F: '{print "  \"" $1 "\": \"" $2 "\","}')
status=$(echo "$status" | sed '$s/,$//')
json="{\n$status\n}"
echo -e "$json"
echo