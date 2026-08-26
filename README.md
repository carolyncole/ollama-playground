# ollama-playground
Place to store code from our olama experiments

## Build the container
```
docker build -t ollama-playground .
```

## Run the container
```
docker run -it --name ollama-playground  --publish 3001:3000 --publish 2301:2300 --volume .:/usr/src/app ollama-playground
```

## Install an agent in your docker

Choose your agent to connect with ollama
```
docker exec -it ollama-playground npm install -g opencode-ai
```

```
docker exec -it ollama-playground npm --force install -g --ignore-scripts @earendil-works/pi-coding-agent
```

## Attach to the running container

```
docker exec -w /usr/src/app -it ollama-playground bash
```

## Run opencode
\model allows you to change models
Ollama (local) is your machine

```
opencode
```

## Run PI
\model allows you to change models
Ollama (local) is your machine

```
opencode
```
