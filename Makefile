all:
	mkdir -p /home/jbahmida/data/wordpress /home/jbahmida/data/mariadb /home/jbahmida/data/uptime_kuma 
	docker compose -f srcs/docker-compose.yml up -d --build
stop:
	docker compose -f srcs/docker-compose.yml stop
start:
	docker compose -f srcs/docker-compose.yml start
down:
	docker compose -f srcs/docker-compose.yml down
clean: down
	docker rmi -f mariadb wordpress nginx cadvisor uptime-kuma redis 2>/dev/null || true
fclean: clean
	@echo "Backing up uptime-kuma data..."
	sudo rm -rf /home/jbahmida/backup_uptime_kuma
	sudo cp -r /home/jbahmida/data/uptime_kuma /home/jbahmida/backup_uptime_kuma
	docker volume rm -f srcs_wordpress_data srcs_mariadb_data srcs_uptime-kuma_data  2>/dev/null || true
	sudo rm -rf /home/jbahmida/data/wordpress/* /home/jbahmida/data/mariadb/* /home/jbahmida/data/uptime_kuma/*
re: fclean
	mkdir -p /home/jbahmida/data/wordpress /home/jbahmida/data/mariadb /home/jbahmida/data/uptime_kuma 
	@echo "Restoring uptime-kuma data..."
	sudo cp -r /home/jbahmida/backup_uptime_kuma/. /home/jbahmida/data/uptime_kuma/
	docker compose -f srcs/docker-compose.yml up -d --build
redis-check:
	docker exec -it redis redis-cli ping
	docker exec -it wordpress wp redis status --allow-root
	docker exec -it wordpress php -m | grep redis
prune:
	docker builder prune -af
.PHONY: all stop start down clean fclean re redis-check prune