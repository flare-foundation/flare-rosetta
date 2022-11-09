docker stop costwo_online
docker rm costwo_online
docker run -d --name costwo_online -p 8080:8080 -p 9650:9650 -p 9651:9651 -e MODE=online -v /opt/flare/db_online:/app/flare/db flarefoundation/flare-rosetta:v0.7.1 costwo
