/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName FROM Warehouse.StockItems
where StockItemName like '%urgent%' or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

-- select * from Purchasing.Suppliers
-- select * from Purchasing.PurchaseOrders
-- order  by SupplierID

select Suppliers.SupplierID, SupplierName from Purchasing.Suppliers
left join Purchasing.PurchaseOrders
on Suppliers.SupplierID = PurchaseOrders.SupplierID
where PurchaseOrders.PurchaseOrderID is null


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

--select OrderID,CustomerID,OrderDate,PickingCompletedWhen from Sales.Orders 
--select OrderID,Quantity,UnitPrice from Sales.OrderLines
--select CustomerID,CustomerName from Sales.Customers

select Sales.Orders.OrderID,CustomerName,
convert (varchar, OrderDate, 104) as [Дата],
format(OrderDate, 'MMMM', 'ru-ru') as [Месяц Ru],
datepart(quarter, OrderDate) as [Квартал],
case
when month(OrderDate) in (1,2,3,4) then 1
when month(OrderDate) in (5,6,7,8) then 2
when month(OrderDate) in (9,10,11,12) then 3
end [Треть_года]
from Sales.Orders
left join Sales.OrderLines on Sales.Orders.OrderID = Sales.OrderLines.OrderID
left join Sales.Customers on Sales.Orders.CustomerID = Sales.Customers.CustomerID
where Sales.OrderLines.PickingCompletedWhen is not null
and (UnitPrice > 100 or Quantity > 20)
ORDER BY Квартал, Треть_года, Дата
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

--1 select Purchasing.Suppliers.SupplierID, Purchasing.Suppliers.SupplierName, Purchasing.Suppliers.DeliveryMethodID
--from Purchasing.Suppliers
--2 select  Purchasing.PurchaseOrders.SupplierID, Purchasing.PurchaseOrders.DeliveryMethodID, Purchasing.PurchaseOrders.ExpectedDeliveryDate, Purchasing.PurchaseOrders.ContactPersonID
--from Purchasing.PurchaseOrders
--3 select Application.DeliveryMethods.DeliveryMethodID, Application.DeliveryMethods.DeliveryMethodName
--from Application.DeliveryMethods
-- 4 select Application.People.PersonID, Application.People.FullName
--from Application.People

select  DeliveryMethodName, Purchasing.PurchaseOrders.ExpectedDeliveryDate, SupplierName, FullName
from Purchasing.PurchaseOrders
left join Purchasing.Suppliers on Purchasing.PurchaseOrders.SupplierID = Purchasing.Suppliers.SupplierID
left join Application.DeliveryMethods on Purchasing.PurchaseOrders.DeliveryMethodID = Application.DeliveryMethods.DeliveryMethodID
left join Application.People on Purchasing.PurchaseOrders.ContactPersonID = Application.People.PersonID
where Purchasing.PurchaseOrders.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31'
and (DeliveryMethodName like 'Air Freight' or DeliveryMethodName like 'Refrigerated Air Freight')
and IsOrderFinalized = 1


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/
select * from Sales.Customers
select * from Sales.Orders
select * from Application.People

-- вариант 1
select Sales.Orders.OrderDate
	, Sales.Customers.CustomerName
	, Application.People.FullName as SalesPersons
from Sales.Orders
left join Sales.Customers on Sales.Orders.CustomerID = Sales.Customers.CustomerID
left join Application.People on Sales.Orders.SalespersonPersonID = Application.People.PersonID
order by OrderDate desc
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY

-- вариант 2
select top (10) Sales.Orders.OrderDate
	, Sales.Customers.CustomerName
	, Application.People.FullName as SalesPersons
from Sales.Orders
left join Sales.Customers on Sales.Orders.CustomerID = Sales.Customers.CustomerID
left join Application.People on Sales.Orders.SalespersonPersonID = Application.People.PersonID
order by OrderDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select * from Sales.Customers
select * from Warehouse.StockItems
select * from Warehouse.StockItemTransactions

select distinct Warehouse.StockItemTransactions.CustomerID
	, Sales.Customers.CustomerName
	, Sales.Customers.PhoneNumber
	, Warehouse.StockItems.StockItemName
from Warehouse.StockItemTransactions
left join Sales.Customers on Warehouse.StockItemTransactions.CustomerID = Sales.Customers.CustomerID
left join Warehouse.StockItems on Warehouse.StockItemTransactions.StockItemID = Warehouse.StockItems.StockItemID
where StockItemName like 'Chocolate frogs 250g' and Warehouse.StockItemTransactions.CustomerID is not null

