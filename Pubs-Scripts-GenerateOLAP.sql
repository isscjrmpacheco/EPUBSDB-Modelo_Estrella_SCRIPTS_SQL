CREATE DATABASE PUBS_DW

GO

USE PUBS_DW

GO

CREATE TABLE DIM_TIEMPO
(
	PK_DIM_TIEMPO INT PRIMARY KEY,
	A�O INT NOT NULL,
	SEMESTRE TINYINT NOT NULL,
	BIMESTRE TINYINT NOT NULL,
	TRIMESTRE TINYINT NOT NULL,
	CUATRIMESTRE TINYINT NOT NULL,
	MES_ESPA�OL NVARCHAR(30) NOT NULL,
	MES_INGLES NVARCHAR(30) NOT NULL,
	MES_NUMERO TINYINT NOT NULL,
	DIA_MES_ESPA�OL NVARCHAR(30) NOT NULL,
	DIA_MES_INGLES NVARCHAR(30) NOT NULL
)

INSERT INTO DIM_TIEMPO
(
	PK_DIM_TIEMPO,
	A�O,
	SEMESTRE,
	BIMESTRE,
	TRIMESTRE,
	CUATRIMESTRE,
	MES_ESPA�OL,
	MES_INGLES,
	MES_NUMERO,
	DIA_MES_ESPA�OL,
	DIA_MES_INGLES
)
SELECT DISTINCT 
	CONVERT(INT, REPLACE(CONVERT(NVARCHAR, CONVERT(DATE, ord_date)), '-', '')),
	YEAR(ord_date),
	((DATEPART(QUARTER, ord_date)-1)/2)+1,
	(MONTH(ord_date)+1)/2,
	DATEPART(QUARTER, ord_date),
	(DATEPART(MONTH, ord_date) / 4 + 1),
	FORMAT(ord_date, 'MMMM', 'es-es'),
	FORMAT(ord_date, 'MMMM', 'en-US'),
	MONTH(ord_date),
	FORMAT(ord_date, 'd-MMMM', 'es-es'),
	FORMAT(ord_date, 'd-MMMM', 'en-US')
FROM
	pubs..sales
WHERE
	ord_date IS NOT NULL AND
	(ord_date >= '1993-05-22 00:00:00.000' AND ord_date <= '1994-09-14 00:00:00.000')


CREATE TABLE DIM_LUGAR
(
	PK_DIM_LUGAR INT PRIMARY KEY,
	ID_LUGAR CHAR(4) NOT NULL,
	CIUDAD VARCHAR(20) NOT NULL,
	ESTADO VARCHAR(15) NOT NULL,
	CODIGO_POSTAL CHAR(5) NOT NULL
)

SET NOCOUNT ON;
WITH LugarAutonumeric AS 
(
	SELECT 
		ROW_NUMBER() OVER(ORDER BY stor_id ASC) AS PK_LUGAR,
		stor_id,
		city,
		CASE [state] WHEN 'WA' THEN 'WASHINGTONG' WHEN 'CA' THEN 'CALIFORNIA' WHEN 'OR' THEN 'OREGON' END AS ESTADO,
		zip
	FROM
		pubs..stores
	WHERE 
		city IS NOT NULL AND [state] IS NOT NULL AND zip IS NOT NULL
)
INSERT INTO DIM_LUGAR
SELECT * FROM LugarAutonumeric


CREATE TABLE DIM_AUTOR
(
	PK_DIM_AUTOR INT PRIMARY KEY,
	ID_AUTOR VARCHAR(11) NOT NULL,
	NOMBRE_AUTOR VARCHAR(20) NOT NULL,
	APELLIDO_AUTOR VARCHAR(40) NOT NULL
)

SET NOCOUNT ON;
WITH AutorAutonumeric AS 
(
	SELECT 
		ROW_NUMBER() OVER(ORDER BY au_id ASC) AS PK_AUTOR,
		au_id,
		au_fname,
		au_lname
	FROM
		pubs..authors
	WHERE 
		au_fname IS NOT NULL AND au_lname IS NOT NULL
)
INSERT INTO DIM_AUTOR
SELECT * FROM AutorAutonumeric


CREATE TABLE DIM_EDITORIAL
(
	PK_DIM_EDITORIAL INT PRIMARY KEY,
	ID_EDITORIAL CHAR(4) NOT NULL,
	NOMBRE_EDITORIAL VARCHAR(40) NOT NULL
)

SET NOCOUNT ON;
WITH EditorialAutonumeric AS 
(
	SELECT 
		ROW_NUMBER() OVER(ORDER BY pub_id ASC) AS PK_EDITORIAL,
		pub_id,
		pub_name
	FROM
		pubs..publishers
	WHERE 
		pub_name IS NOT NULL
)
INSERT INTO DIM_EDITORIAL
SELECT * FROM EditorialAutonumeric


CREATE TABLE DIM_LIBRO
(
	PK_DIM_LIBRO INT PRIMARY KEY,
	ID_LIBRO VARCHAR(6) NOT NULL,
	NOMBRE_LIBRO VARCHAR(80) NOT NULL,
	TIPO_LIBRO CHAR(12) NOT NULL,
	PRECIO_LIBRO MONEY NOT NULL,
	FECHA_PUBLICACION DATETIME NOT NULL
)

SET NOCOUNT ON;
WITH LibroAutonumeric AS 
(
	SELECT 
		ROW_NUMBER() OVER(ORDER BY title_id ASC) AS PK_LIBRO,
		title_id,
		title,
		[type],
		price,
		pubdate
	FROM
		pubs..titles
	WHERE 
		title IS NOT NULL AND [type] IS NOT NULL AND price IS NOT NULL AND pubdate IS NOT NULL AND title_id IS NOT NULL
)
INSERT INTO DIM_LIBRO
SELECT * FROM LibroAutonumeric


CREATE TABLE DIM_TIENDA
(
	PK_DIM_TIENDA INT PRIMARY KEY,
	ID_TIENDA CHAR(4) NOT NULL,
	NOMBRE_TIENDA VARCHAR(40) NOT NULL
)

SET NOCOUNT ON;
WITH TiendaAutonumeric AS 
(
	SELECT 
		ROW_NUMBER() OVER(ORDER BY stor_id ASC) AS PK_TIENDA,
		stor_id,
		stor_name
	FROM
		pubs..stores
	WHERE 
		stor_name IS NOT NULL
)
INSERT INTO DIM_TIENDA
SELECT * FROM TiendaAutonumeric


CREATE TABLE FACT_VENTAS
(
	FK_DIM_TIEMPO INT,
	FK_DIM_LUGAR INT,
	FK_DIM_AUTOR INT,
	FK_DIM_EDITORIAL INT,
	FK_DIM_LIBRO INT,
	FK_DIM_TIENDA INT,
	VENTAS MONEY,
	PRIMARY KEY(FK_DIM_TIEMPO, FK_DIM_LUGAR, FK_DIM_AUTOR, FK_DIM_EDITORIAL, FK_DIM_LIBRO, FK_DIM_TIENDA)
)

ALTER TABLE FACT_VENTAS ADD CONSTRAINT FK_FACTVENTAS_DIMTIEMPO FOREIGN KEY(FK_DIM_TIEMPO) REFERENCES DIM_TIEMPO(PK_DIM_TIEMPO)

ALTER TABLE FACT_VENTAS ADD CONSTRAINT FK_FACTVENTAS_DIMLUGAR FOREIGN KEY(FK_DIM_LUGAR) REFERENCES DIM_LUGAR(PK_DIM_LUGAR)

ALTER TABLE FACT_VENTAS ADD CONSTRAINT FK_FACTVENTAS_DIMAUTOR FOREIGN KEY(FK_DIM_AUTOR) REFERENCES DIM_AUTOR(PK_DIM_AUTOR)

ALTER TABLE FACT_VENTAS ADD CONSTRAINT FK_FACTVENTAS_DIMEDITORIAL FOREIGN KEY(FK_DIM_EDITORIAL) REFERENCES DIM_EDITORIAL(PK_DIM_EDITORIAL)

ALTER TABLE FACT_VENTAS ADD CONSTRAINT FK_FACTVENTAS_DIMLIBRO FOREIGN KEY(FK_DIM_LIBRO) REFERENCES DIM_LIBRO(PK_DIM_LIBRO)

ALTER TABLE FACT_VENTAS ADD CONSTRAINT FK_FACTVENTAS_DIMTIENDA FOREIGN KEY(FK_DIM_TIENDA) REFERENCES DIM_TIENDA(PK_DIM_TIENDA)

INSERT INTO FACT_VENTAS
SELECT
	DIM_TIEMPO.PK_DIM_TIEMPO,
	DIM_LUGAR.PK_DIM_LUGAR,
	DIM_AUTOR.PK_DIM_AUTOR,
	DIM_EDITORIAL.PK_DIM_EDITORIAL,
	DIM_LIBRO.PK_DIM_LIBRO,
	DIM_TIENDA.PK_DIM_TIENDA,
	sales.qty * titles.price
FROM pubs..titles
INNER JOIN pubs..sales ON pubs..titles.title_id = pubs..sales.title_id
INNER JOIN DIM_TIEMPO ON CONVERT(INT, REPLACE(CONVERT(NVARCHAR, CONVERT(DATE, pubs..sales.ord_date)), '-', '')) = DIM_TIEMPO.PK_DIM_TIEMPO
INNER JOIN DIM_LUGAR ON pubs..sales.stor_id = DIM_LUGAR.ID_LUGAR
INNER JOIN pubs..titleauthor ON pubs..sales.title_id = pubs..titleauthor.title_id
INNER JOIN DIM_AUTOR ON pubs..titleauthor.au_id = DIM_AUTOR.ID_AUTOR
INNER JOIN DIM_EDITORIAL ON pubs..titles.pub_id = DIM_EDITORIAL.ID_EDITORIAL
INNER JOIN DIM_LIBRO ON pubs..sales.title_id = DIM_LIBRO.ID_LIBRO
INNER JOIN DIM_TIENDA ON pubs..sales.stor_id = DIM_TIENDA.ID_TIENDA