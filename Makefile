NAME = inception

all:
	docker compose -f srcs/docker-compose.yml up --build -d
up:
	docker compose -f srcs/docker-compose.yml up -d

down:
	docker compose -f srcs/docker-compose.yml down

clean:
	docker compose -f srcs/docker-compose.yml down --volumes --remove-orphans

fclean: clean
	docker system prune -af

re: fclean all