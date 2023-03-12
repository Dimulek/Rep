use master
go

drop database lasania
go

create database lasania
go

use lasania
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
Login_Visitor varchar(50) not null,
Password_Visitor varchar(50) not null,
Money_Left decimal(15,2) not null default(1000.00),
Role_ID int not null default(1),
constraint UQ_Login unique(Login_Visitor),
PRIMARY KEY (ID_Visitor),
FOREIGN KEY(Role_ID) REFERENCES Role(ID_Role)
)
go

insert into Visitor(Login_Visitor, Password_Visitor, Role_ID)
values ('dimulek', 'dimulek', 2),
('qweqwe', 'qweqwe', 1)
go

create table OrderOfVisitor(
ID_OrderOfVisitor int not null identity(1,1),
Visitor_ID int not null,
CountDishes_OrderOfVisitor int not null,
DateEnd_OrderOfVisitor datetime not null default(getdate())
PRIMARY KEY (ID_OrderOfVisitor),
FOREIGN KEY(Visitor_ID) REFERENCES Visitor(ID_Visitor)
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
('Хлебная продукция')
go

create table Ingridient(
ID_Ingridient int not null identity(1,1),
Name_Ingridient varchar(50) not null,
IngridientType_ID int not null,
Count_Ingridient int not null default(0),
Cost_Ingridient decimal(7,2) not null,
CostToBuy_Ingridient decimal(7,2) not null,
constraint UQ_Name_Ingridient unique(Name_Ingridient),
constraint Ch_Cost_Ingridient check(Cost_Ingridient > CostToBuy_Ingridient),
PRIMARY KEY (ID_Ingridient),
FOREIGN KEY(IngridientType_ID) REFERENCES IngridientType(ID_IngridientType)
)
go

insert into Ingridient(Name_Ingridient, IngridientType_ID, Cost_Ingridient, CostToBuy_Ingridient, Count_Ingridient)
values ('Шампиньоны', 1, 150.00, 100.00, 1),
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
('Сухари', 9, 150.00, 100.00, 1), ('Листы лазаньи', 9, 150.00, 100.00, 1)
go

create table OrderIngridients(
ID_OrderIngridients int not null identity(1,1),
OrderOfVisitor_ID int not null,
Ingridient_ID int null,
DishNumber_OrderIngridients int not null,
PRIMARY KEY (ID_OrderIngridients),
FOREIGN KEY(OrderOfVisitor_ID) REFERENCES OrderOfVisitor(ID_OrderOfVisitor),
FOREIGN KEY(Ingridient_ID) REFERENCES Ingridient(ID_Ingridient)
)
go

create or alter procedure buyMoreIngridients(
@Admin_ID int,
@IngridientID int,
@CountDish int
)
as
	declare @cost decimal(15,2) = ((select CostToBuy_Ingridient from Ingridient where ID_Ingridient = @IngridientID) * @CountDish)
	if((select Money_Left from Visitor where ID_Visitor = @Admin_ID) >= @cost)
	begin
		update Visitor set Money_Left = Money_Left - @cost where ID_Visitor = @Admin_ID
		update Ingridient set Count_Ingridient = Count_Ingridient + @CountDish where ID_Ingridient = @IngridientID
		
	end
go

create or alter procedure buyNewIngridient(
@Visitor_ID int,
@order_ID int,
@Ingridient_ID int,
@DishNumber int
)
as
	if((select Cost_Ingridient from Ingridient where ID_Ingridient = @Ingridient_ID)
	<=
	(select Money_Left from Visitor where ID_Visitor = @Visitor_ID)
	and
	(select Count_Ingridient from Ingridient where ID_Ingridient = @Ingridient_ID) != 0)
	begin
		update Ingridient set Count_Ingridient = Count_Ingridient - 1 where ID_Ingridient = @Ingridient_ID
		insert into OrderIngridients (OrderOfVisitor_ID, Ingridient_ID, DishNumber_OrderIngridients)
		values (@Order_ID, @Ingridient_ID, @DishNumber)
		update Visitor set Money_Left = Money_Left + (select Cost_Ingridient from Ingridient where ID_Ingridient = @Ingridient_ID)
			where ID_Visitor = 1
		update Visitor set Money_Left = Money_Left - (select Cost_Ingridient from Ingridient where ID_Ingridient = @Ingridient_ID)
			where ID_Visitor = @Visitor_ID
	end
go

create or alter procedure removeIngridient(
@Visitor_ID int,
@OrderIngridient_ID int
)
as
	Declare @Ingridient_ID int = (select Ingridient_ID from OrderIngridients where ID_OrderIngridients = @OrderIngridient_ID) 
	update Ingridient set Count_Ingridient = Count_Ingridient + 1 where ID_Ingridient = @Ingridient_ID
	delete from OrderIngridients where ID_OrderIngridients = @OrderIngridient_ID
	update Visitor set Money_Left = Money_Left - (select Cost_Ingridient from Ingridient where ID_Ingridient = @Ingridient_ID)
		where ID_Visitor = 1
	update Visitor set Money_Left = Money_Left + (select Cost_Ingridient from Ingridient where ID_Ingridient = @Ingridient_ID)
		where ID_Visitor = @Visitor_ID
go

create or alter procedure addMoney(
@Visitor_ID int)
as
	update Visitor set Money_Left = Money_Left + 1000 where ID_Visitor =  @Visitor_ID
go

create or alter function getPercentMoney(
@Order_ID int
)
Returns decimal(15,2)
as
Begin
	Declare @totalMoney decimal(15,2) = (((select SUM(Cost_Ingridient) from OrderOfVisitor 
	inner join OrderIngridients on ID_OrderOfVisitor = OrderOfVisitor_ID
	inner join Ingridient on ID_Ingridient = Ingridient_ID
	where ID_OrderOfVisitor = @Order_ID) / 100) * 15)
	
	return @totalMoney
END
go