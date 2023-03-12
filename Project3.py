import pyodbc
import random

server = 'DESKTOP-0A0VKP5\DIMULEK' 
database = 'lasania'
# ENCRYPT defaults to yes starting in ODBC Driver 18. It's good to always specify ENCRYPT=yes on the client side to avoid MITM attacks.

cnxn = pyodbc.connect(f'Driver=SQL Server; Server={server}; Database={database}; Trusted_Connection=yes;')
cursor = cnxn.cursor()

def setConnection():
    global cnxn
    global cursor
    cnxn = pyodbc.connect(f'Driver=SQL Server; Server={server}; Database={database}; Trusted_Connection=yes;')
    cursor = cnxn.cursor()

roleID = -1
visitorID = -1

countDishes = -1
orderID = -1

def SignIn(login, password):
    global roleID
    global visitorID
    cursor.execute(f"SELECT ID_Visitor, Role_ID FROM Visitor where Login_Visitor = \'{login}\' and Password_Visitor = \'{password}\'")
    table = cursor.fetchall()

    visitorID = table[0][0]
    roleID = table[0][1]
    if(visitorID != -1):
        cursor.execute(f"exec addMoney {visitorID}")
        cursor.commit()

def Register(login, password):
    cursor.execute(f"INSERT INTO Visitor (Login_Visitor, Password_Visitor) values(\'{login}\', \'{password}\')")
    cursor.commit()

def getBalance():
    cursor.execute(f"SELECT Money_Left from Visitor Where ID_Visitor = {visitorID}")
    print(cursor.fetchall()[0][0])

def getAllIngridientsTypes():
    cursor.execute(f"SELECT ID_IngridientType, Name_IngridientType FROM IngridientType order by ID_IngridientType ASC")
    return cursor.fetchall()

def getAllIngridientsOfTypes(IngridientID):
    cursor.execute(f"SELECT ID_Ingridient, Name_Ingridient, Count_Ingridient, Cost_Ingridient, CostToBuy_Ingridient FROM Ingridient where IngridientType_ID = {IngridientID} order by ID_Ingridient ASC")
    return cursor.fetchall()
 
def updateIngridient(Ingridient, costIngridient):
    if(costIngridient > Ingridient[5]):
        cursor.execute(f"UPDATE Ingridient set Cost_Ingridient = {costIngridient} WHERE ID_Ingridient = {Ingridient[0]}")
        cursor.commit()

def updateIngridientCount(Ingridient, countIngridient):
    if(countIngridient < 1): return
    cursor.execute(f"exec buyMoreIngridients {visitorID}, {Ingridient[0]}, {countIngridient}")
    cursor.commit()

def getAllIngridientsOfDish(dishNumber):
    cursor.execute(f"SELECT ID_OrderIngridients, Name_Ingridient from OrderIngridients inner join Ingridient on Ingridient_ID = ID_Ingridient where DishNumber_OrderIngridients = {dishNumber} and OrderOfVisitor_ID = {orderID}")
    return cursor.fetchall()

def getWindowComponent(componentAttribute, columnCount, columnBegin):
    numberLine = 1
    for type in componentAttribute:
        i=0
        col = str(numberLine)
        col += ")  "
        while i < columnCount:
            col += str(type[i + columnBegin])
            col += "\t"
            i += 1
        print(f"{col}")
        numberLine += 1
    return len(componentAttribute)

def createOrderWithCountDishes(countOfDish):
    global countDishes
    countDishes = countOfDish
    if(countDishes < 1):
        SignOut()
        return
    cursor.execute(f"insert into OrderOfVisitor (Visitor_ID, CountDishes_OrderOfVisitor) values ({visitorID}, {countOfDish})")
    cursor.commit()
    cursor.execute(f"SELECT ID_OrderOfVisitor from OrderOfVisitor where Visitor_ID = {visitorID} order by ID_OrderOfVisitor DESC")
    global orderID
    orderID = cursor.fetchall()[0][0]

def addIngridientInDish(ingridientID, dishNumber):
    cursor.execute(f"exec buyNewIngridient {visitorID}, {orderID}, {ingridientID}, {dishNumber}")
    cursor.commit()

def getAllIngridientsOfDish(dishNumber):
    cursor.execute(f"SELECT ID_OrderIngridients, Name_Ingridient from OrderIngridients inner join Ingridient on ID_Ingridient = Ingridient_ID where DishNumber_OrderIngridients = {dishNumber} and OrderOfVisitor_ID = {orderID}")
    return cursor.fetchall()

def removeIngridientFromDish(orderIngridientID):
    cursor.execute(f"EXEC removeIngridient {visitorID}, {orderIngridientID}")
    cursor.commit()

def lookHistory():
    cursor.execute(f"SELECT ID_OrderOfVisitor, DishNumber_OrderIngridients,  SUM(Cost_Ingridient), String_AGG(Name_Ingridient, '|') from OrderOfVisitor inner join OrderIngridients on ID_OrderOfVisitor = OrderOfVisitor_ID inner join Ingridient on ID_Ingridient = Ingridient_ID where Visitor_ID = {visitorID} Group by ID_OrderOfVisitor, DishNumber_OrderIngridients")
    for row in cursor.fetchall():
        x = row[3].replace("|", "\n\t")
        print(f"Лазанья: Стоимость - {row[2]}\nСостав:\n\t{x}")

def getPercentMoney():
    cursor.execute(f"UPDATE Visitor set Money_Left = Money_Left + (select dbo.getPercentMoney({orderID})) where ID_Visitor = {visitorID}")
    cursor.execute(f"UPDATE Visitor set Money_Left = Money_Left - (select dbo.getPercentMoney({orderID})) where ID_Visitor = 1")
    cursor.commit()
    cursor.execute(f"select dbo.getPercentMoney({orderID})")
    print(f"\nСкидка составляет - {cursor.fetchall()[0][0]}\n\n")

def getAdminWindow():
    print("AdminLog\n\n")
    getBalance()
    linesSize = getWindowComponent(getAllIngridientsTypes(), 1, 1)
    chooseline = int(input("\n"))
    if(chooseline < 1 or chooseline > linesSize + 1):
        SignOut()
        return
    IngridientsList = getAllIngridientsOfTypes(chooseline)
    linesSize = getWindowComponent(IngridientsList, 4, 1)
    chooseline = int(input("\n\nВыбирите ингридиент\n"))
    if(chooseline < 1 or chooseline > linesSize + 1):
        return
    chooseAct = int(input("\n1) Изенить стоимости игридиента для пользователя\n2) Увеличить количество на складе\n"))
    if(chooseAct == 1):
        updateIngridient(IngridientsList[chooseline-1], float(input("Enter new cost\n")));
    if(chooseAct == 2):
        updateIngridientCount(IngridientsList[chooseline-1], int(input("Enter count of buing\n")))

def getUserWindow():
    global orderID
    global countDishes
    if(orderID == -1 or countDishes < 1):
        if(int(input("Выберите действие\n1) Сделать заказ\n2) Посмотреть историю заказов\n")) == 2):
            lookHistory()
            return
        createOrderWithCountDishes(int(input("Введите количество покупаемого продукта\n")))
    if(countDishes < 1):
        return
    print("\n\nVisitorLog\n\n")
    getBalance()
    index = 1
    while(index <= countDishes):
        print(f"{index}) Лазанья")
        index += 1
    chooseLine = int(input("Выбирите номер блюда\n"))
    if(chooseLine<=0 or chooseLine > index):
        if(random.randint(0, 5) == random.randint(0, 5)):
            print("Блюдо испорчено!\nВам полагается СКИДКА 15%")
            getPercentMoney()
        print("Заказ оформлен")
        orderID = -1
        countDishes = -1
        return
    chooseAct = int(input("Выбирете действие\n1) Добавить новый ингридиент\n2) Удалить ингридиент\n"))
    if(chooseAct == 1):
        linesSize = getWindowComponent(getAllIngridientsTypes(), 1, 1)
        chooselineIngridientType = int(input("\n"))
        if(chooselineIngridientType < 1 or chooselineIngridientType > linesSize + 1):
            return
        IngridientsList = getAllIngridientsOfTypes(chooselineIngridientType)
        linesSize = getWindowComponent(IngridientsList, 3, 1)
        chooselineIngridient = int(input("\n\nВыбирите ингридиент\n"))
        if(chooselineIngridient <= 0 or chooselineIngridient > linesSize):
            return
        addIngridientInDish(IngridientsList[chooselineIngridient-1][0], chooseLine)
    if(chooseAct == 2):
        ingridientsOfDish = getAllIngridientsOfDish(chooseLine)
        lineSize = getWindowComponent(ingridientsOfDish, 1,1)
        chooseline = int(input())
        if(chooseline < 1 or chooseline > lineSize):
            return
        removeIngridientFromDish(ingridientsOfDish[chooseline-1][0])
        

def SignOut():
    global roleID
    global visitorID
    roleID = -1
    visitorID = -1



while(1):
    if(roleID == -1 and visitorID == -1):
        chose = int(input("Выберите действие\n1) Авторизация\n2) Регистрация\n"))
        if(chose == 1):
            SignIn(input("  Ввдите логин\n"), input("  Введите пароль\n"))
        if(chose == 2):
            Register(input("  Придумайте свой логин\n"), input("  Придумайте пароль\n"))
        continue
    if(roleID == 1):
        getUserWindow()
    if(roleID == 2):
        getAdminWindow()