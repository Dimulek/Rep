use master
go
drop database Project3DB
go
create database Project3DB
go
use Project3DB
go

create table Role(
ID_Role int not null IDENTITY (1,1),
Name_Role varchar(50) not null
constraint UQ_Name_Role unique(Name_Role),
PRIMARY KEY (ID_Role)
)
go
insert into Role(Name_Role)
values ('Пользователь'), ('Администратор')
go
create table Visitor(
ID_Visitor int not null IDENTITY (1,1),
--Login_Visitor varchar(50) not null,
--Password_Visitor varchar(50) not null,
--Money_Left decimal(15,2) not null default(100000.00),
--Email_Visitor varchar(max) not null,
Role_ID int not null default(1),
constraint UQ_Login unique(Login_Visitor),
PRIMARY KEY (ID_Visitor),
FOREIGN KEY(Role_ID) REFERENCES Role(ID_Role)
)
go
insert into Visitor(Login_Visitor, Password_Visitor, Role_ID, Email_Visitor)
values ('dimulek', 'dimulek', 2, 'dimulek14@mail.ru'),
('qweqwe', 'qweqwe', 1, 'dimulek20@gmail.com')
go
create table OrderOfVisitor(
ID_OrderOfVisitor int not null identity(1,1),
Visitor_ID int not null,
DishCount_OrderOfVisitor int not null default(0),
Status_OrderOfVisitor int not null default(0),
Percent_OrderOfVisitor int not null default(0),
DateEnd_OrderOfVisitor datetime not null default(getdate())
PRIMARY KEY (ID_OrderOfVisitor),
FOREIGN KEY(Visitor_ID) REFERENCES Visitor(ID_Visitor)
)
go
create table DishesOfOrder(
ID_DishesOfOrder int not null identity(1,1),
OrderOfVisitor_ID int not null,
FullCost_DishesOfOrder decimal(25, 2) not null default(50)
PRIMARY KEY (ID_DishesOfOrder),
FOREIGN KEY(OrderOfVisitor_ID) REFERENCES OrderOfVisitor(ID_OrderOfVisitor)
)
go
create table IngridientType(
ID_IngridientType int not null identity(1,1),
Name_IngridientType varchar(50) not null
constraint UQ_Name_IngridientType unique(Name_IngridientType),
PRIMARY KEY (ID_IngridientType)
)
go
insert into IngridientType(Name_IngridientType)
values ('Грибы'),
('Овощи'),
('Сыр'),
('Молочная продукция'),
('Мясная продукция'),
('Приправы'),
('Орехи'),
('Соусы'),
('Хлебная продукция'),
('Ошибка')
go
create table Ingridient(
ID_Ingridient int not null identity(1,1),
Name_Ingridient varchar(50) not null,
IngridientType_ID int not null,
Count_Ingridient int not null default(0),
Cost_Ingridient decimal(7,2) not null,
CostInDish_Ingridient decimal(7,2) not null,
constraint UQ_Name_Ingridient unique(Name_Ingridient),
constraint Ch_Cost_Ingridient check(Cost_Ingridient < CostInDish_Ingridient),
PRIMARY KEY (ID_Ingridient),
FOREIGN KEY(IngridientType_ID) REFERENCES IngridientType(ID_IngridientType)
)
go
insert into Ingridient(Name_Ingridient, IngridientType_ID, 
CostInDish_Ingridient, Cost_Ingridient, Count_Ingridient)
values ('Шампиньоны', 1, 150.00, 100.00, 100),
('Лук   ', 2, 150.00, 100.00, 1), ('Чеснок', 2, 150.00, 100.00, 1), ('Петрушка', 2, 150.00, 100.00, 1), 
('Перец ', 2, 150.00, 100.00, 1), ('Орегано', 2, 150.00, 100.00, 1), ('Помидор', 2, 150.00, 100.00, 1), 
('Шпинат', 2, 150.00, 100.00, 1), ('Тыква', 2, 150.00, 100.00, 1), ('Баклажан', 2, 150.00, 100.00, 1), 
('Базилик', 2, 150.00, 100.00, 1), ('Тимьян', 2, 150.00, 100.00, 1), ('Броколи', 2, 150.00, 100.00, 1),
('Пармизан', 3, 150.00, 100.00, 1), ('Риккота', 3, 150.00, 100.00, 1), 
('Моцарелла', 3, 150.00, 100.00, 1), ('Твердый сыр', 3, 150.00, 100.00, 1), ('Чедер', 3, 150.00, 100.00, 1),
('Молоко', 4, 150.00, 100.00, 1), ('Творог', 4, 150.00, 100.00, 1),
('Варенная курица', 5, 150.00, 100.00, 1), ('Жаренная курица', 5, 150.00, 100.00, 1), 
('Говяжий фарш', 5, 150.00, 100.00, 1), ('Яица', 5, 150.00, 100.00, 1),
('Соль', 6, 150.00, 100.00, 1), ('Молотый чили', 6, 150.00, 100.00, 1),
('Мускатные орехи', 7, 150.00, 100.00, 1), ('Грецкие орехи', 7, 150.00, 100.00, 1),
('Соус маринара', 8, 150.00, 100.00, 1), ('Томатная паста', 8, 150.00, 100.00, 1),
('Сухари', 9, 150.00, 100.00, 1), ('Листы лазаньи', 9, 150.00, 100.00, 1),
('Таракан', 10, 0.1, 0, 0)
go
create table DishIngridients(
ID_DishIngridients int not null identity(1,1),
DishesOfOrder_ID int not null,
Ingridient_ID int not null,
PRIMARY KEY (ID_DishIngridients),
FOREIGN KEY(DishesOfOrder_ID) REFERENCES DishesOfOrder(ID_DishesOfOrder),
FOREIGN KEY(Ingridient_ID) REFERENCES Ingridient(ID_Ingridient)
)
go
create or alter procedure buyMoreIngridients(
@Admin_ID int,
@IngridientID int,
@CountDish int
)
as
	declare @cost decimal(15,2) = ((select Cost_Ingridient from Ingridient where ID_Ingridient = @IngridientID) * @CountDish)
	if((select Money_Left from Visitor where ID_Visitor = @Admin_ID) >= @cost)
	begin
		update Visitor set Money_Left = Money_Left - @cost where ID_Visitor = @Admin_ID
		update Ingridient set Count_Ingridient = Count_Ingridient + @CountDish where ID_Ingridient = @IngridientID
	end
go
create or alter procedure buyNewIngridient(
@Order_ID int,
@Dish_ID int,
@Ingridient_ID int
)
as
	Declare @id_Dish int = (select ID_DishesOfOrder from DishesOfOrder where OrderOfVisitor_ID = @Order_ID 
	ORDER BY ID_DishesOfOrder ASC
	OFFSET @Dish_ID-1 ROWS FETCH NEXT 1 ROWS ONLY)
	insert into DishIngridients(DishesOfOrder_ID, Ingridient_ID)
	values (@id_Dish, @Ingridient_ID)
	update DishesOfOrder set FullCost_DishesOfOrder = 
	FullCost_DishesOfOrder + 
	(select CostInDish_Ingridient from Ingridient where ID_Ingridient = @Ingridient_ID) 
	where ID_DishesOfOrder = @id_Dish
go
	
create or alter procedure removeIngridient(
@Order_ID int,
@Dish_ID int,
@DishIngridients_ID int
)
as
	Declare @id_Dish int = (select ID_DishesOfOrder from DishesOfOrder where OrderOfVisitor_ID = @Order_ID 
	ORDER BY ID_DishesOfOrder ASC
	OFFSET @Dish_ID-1 ROWS FETCH NEXT 1 ROWS ONLY)

	Declare @Ingridient_ID int = (select Ingridient_ID from DishIngridients where ID_DishIngridients = @DishIngridients_ID) 
	
	update DishesOfOrder set FullCost_DishesOfOrder = 
	FullCost_DishesOfOrder - 
	(select CostInDish_Ingridient from Ingridient where ID_Ingridient = @Ingridient_ID)
	where ID_DishesOfOrder = @id_Dish
	delete from DishIngridients where ID_DishIngridients = @DishIngridients_ID
go

create or alter procedure deleteOrder(
@Order_ID int
)
as
	while(select count(ID_DishesOfOrder) from OrderOfVisitor
	inner join DishesOfOrder on OrderOfVisitor_ID = ID_DishesOfOrder
	where ID_OrderOfVisitor = @Order_ID) > 0
	begin
		Declare @DishID int = (select Top(1) ID_DishesOfOrder from DishesOfOrder where OrderOfVisitor_ID = @Order_ID)
		delete from DishIngridients where DishesOfOrder_ID = @DishID
		delete from DishesOfOrder where ID_DishesOfOrder = @DishID
	end
	delete from OrderOfVisitor where ID_OrderOfVisitor = @Order_ID
go

create or alter procedure succsessOrder(
@Order_ID int,
@Visitor_ID int
)
as
	Declare @countDish int = (select count(*) from OrderOfVisitor 
		inner join DishesOfOrder on ID_OrderOfVisitor = OrderOfVisitor_ID 
		where ID_OrderOfVisitor = @Order_ID)
	Declare @countDish2 int = @CountDish
	Declare @MoneySum decimal(25,2) = 0
	Declare @percent int = 0
	if(@countDish >= 5)
		set @percent = 5

	while(@countDish > 0)
	begin
		Declare @DishID int = (select ID_DishesOfOrder from OrderOfVisitor 
			inner join DishesOfOrder on OrderOfVisitor_ID = ID_OrderOfVisitor
			where ID_OrderOfVisitor = @Order_ID
			ORDER BY ID_DishesOfOrder DESC
			OFFSET @countDish-1 ROWS FETCH NEXT 1 ROWS ONLY)

		set @MoneySum = @MoneySum + (select FullCost_DishesOfOrder 
			from DishesOfOrder where ID_DishesOfOrder = @DishID)
		set @countDish = @countDish - 1

	end

	if((select Money_Left from Visitor where ID_Visitor = @Visitor_ID) >= @MoneySum
	and
	(select dbo.checkIngridient(@Order_ID)) != 0)
	
	begin
		while @countDish2 > 0
		begin
			Declare @Dish_ID int = (select ID_DishesOfOrder from OrderOfVisitor 
			inner join DishesOfOrder on OrderOfVisitor_ID = ID_OrderOfVisitor
			where ID_OrderOfVisitor = @Order_ID
			ORDER BY ID_DishesOfOrder DESC
			OFFSET @countDish2-1 ROWS FETCH NEXT 1 ROWS ONLY)

			Declare @countIngridientDish int = (select count(*) from DishIngridients where DishesOfOrder_ID = @Dish_ID)

			while(@countIngridientDish > 0)
			begin
				update Ingridient set Count_Ingridient = Count_Ingridient - 1 
				where ID_Ingridient = 
				(select Ingridient_ID from DishIngridients 
				where DishesOfOrder_ID = @Dish_ID 
				ORDER BY Ingridient_ID DESC OFFSET @countIngridientDish-1 ROWS FETCH NEXT 1 ROWS ONLY) 
				set @countIngridientDish = @countIngridientDish - 1
			end
			set @countDish2 = @countDish2 - 1
		end

		set @percent = (@percent + (select Top(1) percentCount from getCardType(1)))

		Declare @BadFoodID int = (select Top(1)ID_Ingridient from Ingridient where IngridientType_ID = 10)
		Declare @DishIndex int = (ABS(CHECKSUM(NEWID()) % (1 - 1 + 1)) + 1)

		if(@DishIndex = (ABS(CHECKSUM(NEWID()) % (1 - 1 + 1)) + 1))
		begin
			insert into DishIngridients(DishesOfOrder_ID, Ingridient_ID)
			values((select ID_DishesOfOrder from DishesOfOrder where OrderOfVisitor_ID = @Order_ID 
			ORDER BY ID_DishesOfOrder DESC
				OFFSET @DishIndex-1 ROWS FETCH NEXT 1 ROWS ONLY), @BadFoodID)
			set @percent += 5
		end

		set @MoneySum = @MoneySum - ((@MoneySum/100) * @percent)

		update Visitor set Money_Left = Money_Left - @MoneySum where ID_Visitor = (select ID_Visitor from OrderOfVisitor inner join Visitor on Visitor_ID = ID_Visitor where ID_OrderOfVisitor = @Order_ID)
		update Visitor set Money_Left = Money_Left + @MoneySum where ID_Visitor = 1
		update OrderOfVisitor set Status_OrderOfVisitor = 1, Percent_OrderOfVisitor = @percent where ID_OrderOfVisitor = @Order_ID
	end
go


create or alter procedure addMoney(
@Visitor_ID int)
as
	update Visitor set Money_Left = Money_Left + 1000 where ID_Visitor =  @Visitor_ID
go

create or alter view countIngridientDish
as
	select ID_Ingridient as "КодИнгридиента", ID_DishesOfOrder as "КодЗаказа", count(ID_DishIngridients) as "Количество" from DishIngridients
	inner join DishesOfOrder on ID_DishesOfOrder = DishesOfOrder_ID
	inner join Ingridient on ID_Ingridient = Ingridient_ID
	Group by ID_Ingridient, ID_DishesOfOrder
go

create or alter function checkIngridient(
@Order_ID int
)
returns int
as
begin
	Declare @countIngridient int = (select count(*) from Ingridient)
	while(@countIngridient > 0)
	begin
		Declare @ingridientType_ID int = (select IngridientType_ID from Ingridient ORDER BY ID_Ingridient DESC OFFSET @countIngridient-1 ROWS FETCH NEXT 1 ROWS ONLY)
		if(@ingridientType_ID  != 10)
		begin
			if((select Количество from countIngridientDish where КодЗаказа = @Order_ID
			ORDER BY КодИнгридиента DESC OFFSET @countIngridient-1 ROWS FETCH NEXT 1 ROWS ONLY) 
			> 
			(select Count_Ingridient from Ingridient
			ORDER BY ID_Ingridient DESC OFFSET @countIngridient-1 ROWS FETCH NEXT 1 ROWS ONLY))
				return 0
		end
		set @countIngridient = @countIngridient - 1
	end
	return 1
end
go

create or alter function getCardType(
@Visitor_ID int
)
Returns @table table(cardName varchar(25),
percentCount int)
as
Begin
	Declare @moneyCountSpend decimal(25, 2) = (select SUM(FullCost_DishesOfOrder) from OrderOfVisitor inner join DishesOfOrder on OrderOfVisitor_ID = ID_OrderOfVisitor
	where Visitor_ID = @Visitor_ID and Status_OrderOfVisitor = 1)
	if(@moneyCountSpend > 10000)
		insert into @table(cardName, percentCount)
		values('Золотая', 20)
	else if(@moneyCountSpend > 5000)
		insert into @table(cardName, percentCount)
		values('Серебрянная', 10)
	else if(@moneyCountSpend > 1000)
		insert into @table(cardName, percentCount)
		values('Бронзовая', 5)
	else 
		insert into @table(cardName, percentCount)
			values('Отсутствует', 0)
	Return;
END
go

--EXEC succsessOrder 1, 1


SELECT ID_DishesOfOrder, FullCost_DishesOfOrder - 
((FullCost_DishesOfOrder/100) * Percent_OrderOfVisitor),OrderOfVisitor_ID, 
String_AGG(Name_Ingridient, '|') 
from DishesOfOrder 
inner join OrderOfVisitor on OrderOfVisitor_ID = ID_OrderOfVisitor 
left join DishIngridients on ID_DishesOfOrder = DishesOfOrder_ID 
left join Ingridient on ID_Ingridient = Ingridient_ID 
where Visitor_ID = 2 and Status_OrderOfVisitor = 1 
Group by ID_DishesOfOrder, FullCost_DishesOfOrder, Percent_OrderOfVisitor, OrderOfVisitor_ID

--SELECT ID_DishIngridients, Name_Ingridient from DishesOfOrder 
--left join DishIngridients on DishesOfOrder_ID = ID_DishesOfOrder 
--left join Ingridient on Ingridient_ID = ID_Ingridient 
--where ID_DishesOfOrder = 4
--(select ID_DishesOfOrder from DishesOfOrder where OrderOfVisitor_ID = 1 ORDER BY ID_DishesOfOrder DESC	OFFSET (1) ROWS FETCH NEXT 1 ROWS ONLY)

SELECT ID_DishIngridients, Name_Ingridient from DishesOfOrder inner join DishIngridients on DishesOfOrder_ID = ID_DishesOfOrder inner join Ingridient on Ingridient_ID = ID_Ingridient where OrderOfVisitor_ID = 1 
ORDER BY ID_DishesOfOrder DESC	OFFSET (0) ROWS FETCH NEXT 1 ROWS ONLY

select * from DishesOfOrder
select * from IngridientType

SELECT ID_DishIngridients, Name_Ingridient from DishesOfOrder inner join DishIngridients on DishesOfOrder_ID = ID_DishesOfOrder inner join Ingridient on Ingridient_ID = ID_Ingridient where DishesOfOrder_ID = (select ID_DishesOfOrder from DishesOfOrder where OrderOfVisitor_ID = 4 ORDER BY ID_DishesOfOrder ASC OFFSET (0) ROWS FETCH NEXT 1 ROWS ONLY)