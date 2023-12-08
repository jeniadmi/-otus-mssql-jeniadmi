/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

select * from Sales.Invoices
select top (1) * from Sales.InvoiceLines
select top (1) * from Application.People

--1
select PersonID, FullName
from Application.People 
left join (
select * from Sales.Invoices
where InvoiceDate = '2015-07-04') as Table1
on PersonID = Table1.SalespersonPersonID
where  IsSalesPerson = 1 and Table1.SalespersonPersonID is null


--2
GO
WITH Table1
AS 
(
	select * from Sales.Invoices
where InvoiceDate = '2015-07-04'
)
SELECT PersonID, FullName
FROM [Application].People 
	LEFT JOIN Table1 
		ON Table1.SalespersonPersonID = PersonID
where IsSalesPerson = 1 and Table1.SalespersonPersonID is null


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
select top (1) * from Warehouse.StockItems
--1
select StockItemID, StockItemName, sum (UnitPrice * (TaxRate / 100) + UnitPrice) as Price from Warehouse.StockItems 
group by StockItemID, StockItemName
having sum (UnitPrice * (TaxRate / 100) + UnitPrice) like (select min (UnitPrice * (TaxRate / 100) + UnitPrice) from Warehouse.StockItems)

--2
GO
WITH minprice (StockItemID, Price)
as
(select top (1) StockItemID, min (UnitPrice * (TaxRate / 100) + UnitPrice) as Price from Warehouse.StockItems
group by StockItemID order by Price)
select Warehouse.StockItems.StockItemID, StockItemName, minprice.Price from Warehouse.StockItems
left join minprice on Warehouse.StockItems.StockItemID = minprice.StockItemID
where minprice.Price is not NULL
group by Warehouse.StockItems.StockItemID, StockItemName, minprice.Price

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--1
select Sales.Customers.CustomerID, Sales.Customers.CustomerName,Sales.Customers.PhoneNumber,Sales.Customers.DeliveryAddressLine1, TableTOP5.TransactionAmount
from
(
select top (5) CustomerID, TransactionAmount from Sales.CustomerTransactions
order by TransactionAmount desc) as TableTOP5
left join Sales.Customers on TableTOP5.CustomerID = Sales.Customers.CustomerID

--2
GO
WITH TableTOP5
as
(
select top (5) CustomerID, TransactionAmount from Sales.CustomerTransactions
order by TransactionAmount desc)
select Sales.Customers.CustomerID, Sales.Customers.CustomerName,Sales.Customers.PhoneNumber,Sales.Customers.DeliveryAddressLine1, TableTOP5.TransactionAmount
from TableTOP5
left join Sales.Customers on TableTOP5.CustomerID = Sales.Customers.CustomerID


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

select top (1) * from Warehouse.StockItems
select top (1) * from Application.Cities
select top (1) * from Sales.Invoices
select top (1) * from Application.People
select top (1) * from Sales.Customers

--1
select DISTINCT TableTOP3Price.UnitPrice, Application.Cities.CityID, Application.Cities.CityName, Application.People.FullName
from (
select top (3) StockItemID, StockItemName, SupplierID, UnitPrice from Warehouse.StockItems
order by UnitPrice desc) as TableTOP3Price
join Sales.Invoices on TableTOP3Price.SupplierID = Sales.Invoices.PackedByPersonID
join Application.People on Sales.Invoices.PackedByPersonID = Application.People.PersonID
join Sales.Customers on Sales.Invoices.CustomerID = Sales.Customers.CustomerID
join Application.Cities on Sales.Customers.DeliveryCityID = Application.Cities.CityID
order by TableTOP3Price.UnitPrice desc

--2
GO
WITH TableTOP3Price
as
(
select top (3) StockItemID, StockItemName, SupplierID, UnitPrice from Warehouse.StockItems
order by UnitPrice desc)
select DISTINCT TableTOP3Price.UnitPrice, Application.Cities.CityID, Application.Cities.CityName, Application.People.FullName
from TableTOP3Price
join Sales.Invoices on TableTOP3Price.SupplierID = Sales.Invoices.PackedByPersonID
join Application.People on Sales.Invoices.PackedByPersonID = Application.People.PersonID
join Sales.Customers on Sales.Invoices.CustomerID = Sales.Customers.CustomerID
join Application.Cities on Sales.Customers.DeliveryCityID = Application.Cities.CityID
order by TableTOP3Price.UnitPrice desc


-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
