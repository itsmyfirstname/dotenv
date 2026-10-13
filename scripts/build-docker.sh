docker run -it -v ~/.config:/root/.config:z -v /home/mehays/projects/dotenv/common:/home/mehays/projects/dotenv/common:z devcontainer:latest

docker build -t devcontainer:latest -f devcontainer.Dockerfile .
