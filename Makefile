all:
	mkdir -p /home/jbahmida/data/wordpress /home/jbahmida/data/mariadb
	docker compose -f srcs/docker-compose.yml up -d --build

stop:
	docker compose -f srcs/docker-compose.yml stop

start:
	docker compose -f srcs/docker-compose.yml start

down:
	docker compose -f srcs/docker-compose.yml down

clean: down
	docker rmi -f mariadb wordpress nginx 2>/dev/null || true

fclean: clean
	docker volume rm -f srcs_wordpress_data srcs_mariadb_data 2>/dev/null || true
	sudo rm -rf /home/jbahmida/data/wordpress/* /home/jbahmida/data/mariadb/*

re: fclean all

.PHONY: all stop start down clean fclean re