CREATE TABLE service (
  id INT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  price INT NOT NULL
);

CREATE TABLE position (
  id INT PRIMARY KEY,
  name VARCHAR(50) NOT NULL
);

CREATE TABLE employee (
  id INT PRIMARY KEY,
  fio VARCHAR(80) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  position_id INT REFERENCES position(id) NOT NULL
);

CREATE TABLE discont (
  id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  percent SMALLINT NOT NULL
);

CREATE TABLE paymentmethod (
  id INT PRIMARY KEY,
  name VARCHAR(15) NOT NULL
);

CREATE TABLE kind (
  id INT PRIMARY KEY,
  name VARCHAR(20) NOT NULL
);

CREATE TABLE breed (
  id INT PRIMARY KEY,
  kind_id INT REFERENCES kind(id) NOT NULL,
  name VARCHAR(50) NOT NULL
);

CREATE TABLE client (
  id INT PRIMARY KEY,
  date DATE NOT NULL,
  contract INT,
  fio VARCHAR(80) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(50)
);

CREATE TABLE pet (
  id INT PRIMARY KEY,
  client_id INT REFERENCES client(id) NOT NULL,
  kind_id INT REFERENCES kind(id) NOT NULL,
  name VARCHAR(50),
  breed_id INT REFERENCES breed(id)
);

CREATE TABLE orders (
  id INT PRIMARY KEY,
  date DATE NOT NULL,
  service_id INT REFERENCES service(id) NOT NULL,
  client_id INT REFERENCES client(id) NOT NULL,
  pet_id INT REFERENCES pet(id) NOT NULL,
  employee_id INT REFERENCES employee(id) NOT NULL,
  payment_method_id INT REFERENCES paymentmethod(id),
  quantity SMALLINT NOT NULL,
  discont_id INT REFERENCES discont(id)
)