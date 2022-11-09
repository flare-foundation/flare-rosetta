docker stop costwo_offline
docker rm costwo_offline
docker run -d --name costwo_offline -p 8081:8080 -p 19650:9650 -p 19651:9651 -e MODE=offline -v /opt/flare/db_offline:/app/flare/db flarefoundation/flare-rosetta:v0.7.1 costwo
