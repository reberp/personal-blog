Steps for updating content and testing locally. Could also use the Hugo image but I already have this here and it's what it deploys onto so might as well just use it.

Build docker image
```
docker build -t test .
```

Run Image
```
docker run -p 8080:8080 -v $PWD/local-dev/nginx.conf:/etc/nginx.conf test
```

Check webpage at localhost:8080
