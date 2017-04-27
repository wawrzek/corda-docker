```
docker-compose up &
```

The `Dockerfile` exposes the application ports, and `docker-compose.yml` provides a mapping
between the host machine (your EC2 instance) and the running Docker container so that, say, 
Docker port 3000 is mapped to host port 80. Therefore you get to see your application's output 
in your browser.

The `docker-compose.yml` also contains information for tagging your images to make them easier to
push to an upstream repository (such as Docker Hub).

### Stop your containers

Docker Compose will also ensure all containers are shut down gracefully.
```
docker-compose stop
```


