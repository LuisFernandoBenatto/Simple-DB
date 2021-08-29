all:
	@echo "Hello $(LOGNAME), nothing to do by default"
	@echo "Try 'make help'"

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build images and run the containers
	@[ -f .env ] || cp template.env .env
	@[ -f postgres/.env ] || cp postgres/template.env postgres/.env
	@docker-compose build
	@docker-compose up -d

create-db: ## Reset demo-data to postgres container
	@docker-compose exec postgres chown -R postgres /backup
	@docker-compose exec --user="postgres" postgres /bin/bash -c "psql -c 'DROP DATABASE dummydb'" || true
	@docker-compose exec --user="postgres" postgres /bin/bash -c "psql -c 'CREATE DATABASE dummydb ENCODING 'UTF8' TEMPLATE template0'" || true

up: ## Start containers and run the project in dev mode
	@docker-compose start

down: ## Stop containers
	@docker-compose stop

remove: ## Remove all containers
	@docker-compose down

cmd: ## Command line inside postgres container
	@docker-compose exec --user postgres postgres /bin/bash

restart: ## Restart all containers
	@docker-compose restart

create-tables:
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE "User" (user_id INT PRIMARY KEY, type VARCHAR (50) NOT NULL, first_name VARCHAR (50) NOT NULL, last_name VARCHAR (50) NOT NULL, email VARCHAR (255) UNIQUE NOT NULL, password VARCHAR (50) NOT NULL);"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE UserPhone (user_id INT NOT NULL, phone VARCHAR (50) NOT NULL, PRIMARY KEY (user_id, phone), FOREIGN KEY (user_id) REFERENCES "User" (user_id) ON DELETE CASCADE);"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE Employee (user_id INT PRIMARY KEY, internal_code VARCHAR (150) NOT NULL, zip_code VARCHAR (30) NOT NULL, city_name VARCHAR (80) NOT NULL, neighborhood VARCHAR (255), street VARCHAR (255), number VARCHAR (255), FOREIGN KEY (user_id) REFERENCES "User" (user_id));"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE Supplier (supplier_id INT PRIMARY KEY, cnpj VARCHAR (100) NOT NULL, corporate_name VARCHAR (200) NOT NULL, email VARCHAR (255) UNIQUE NOT NULL, description VARCHAR (255), photo_path VARCHAR (255), zip_code VARCHAR (30) NOT NULL, city_name VARCHAR (80) NOT NULL, neighborhood VARCHAR (255), street VARCHAR (255), number VARCHAR (255));"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE SupplierPhone (supplier_id INT NOT NULL, phone VARCHAR (50) NOT NULL, PRIMARY KEY (supplier_id, phone), FOREIGN KEY (supplier_id) REFERENCES Supplier (supplier_id) ON DELETE CASCADE);"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE Category (category_id INT PRIMARY KEY, name VARCHAR (255) NOT NULL, description VARCHAR (255));"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE Product (product_id INT PRIMARY KEY, is_service BOOLEAN NOT NULL DEFAULT FALSE, code VARCHAR (255), name VARCHAR (255) NOT NULL, price DECIMAL NOT NULL, is_high_demand BOOLEAN NOT NULL DEFAULT FALSE, description VARCHAR (255));"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE ProductCategory (product_id INT NOT NULL, category_id INT NOT NULL, PRIMARY KEY (product_id, category_id), FOREIGN KEY (product_id) REFERENCES Product (product_id) ON DELETE CASCADE, FOREIGN KEY (category_id) REFERENCES Category (category_id) ON DELETE CASCADE);"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE "Order" (order_id INT PRIMARY KEY, supplier_id INT NOT NULL, date TIMESTAMP NOT NULL, status VARCHAR (15) NOT NULL, payment_method VARCHAR(20) NOT NULL, number VARCHAR(150), description VARCHAR(255), FOREIGN KEY (supplier_id) REFERENCES Supplier (supplier_id) ON DELETE SET NULL);"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE OrderItem (order_item_id INT PRIMARY KEY, order_id INT NOT NULL, product_id INT NOT NULL, quantity INT NOT NULL, unit_price DECIMAL NOT NULL, FOREIGN KEY (order_id) REFERENCES "Order" (order_id) ON DELETE CASCADE, FOREIGN KEY (product_id) REFERENCES Product (product_id) ON DELETE SET NULL);"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE UserOrder (user_id INT NOT NULL, order_id INT NOT NULL, PRIMARY KEY (user_id, order_id), FOREIGN KEY (user_id) REFERENCES "User" (user_id) ON DELETE CASCADE, FOREIGN KEY (order_id) REFERENCES "Order" (order_id) ON DELETE CASCADE);"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE Sale (sale_id INT PRIMARY KEY, user_id INT NOT NULL, date TIMESTAMP NOT NULL, status VARCHAR (15) NOT NULL, payment_method VARCHAR(20) NOT NULL, discount DECIMAL, FOREIGN KEY (user_id) REFERENCES "User" (user_id) ON DELETE SET NULL);"
	@docker-compose exec --user="postgres" -it postgres psql dummydb -U postgres -c "CREATE TABLE SaleItem (sale_item_id INT PRIMARY KEY, sale_id INT NOT NULL, product_id INT NOT NULL, quantity INT NOT NULL, unit_price DECIMAL NOT NULL, FOREIGN KEY (sale_id) REFERENCES Sale (sale_id) ON DELETE CASCADE, FOREIGN KEY (product_id) REFERENCES Product (product_id) ON DELETE SET NULL);"
	@echo "🎉 Tables created 🎉"

.DEFAULT_GOAL := help
