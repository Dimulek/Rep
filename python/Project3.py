import pyodbc
import random
import smtplib

server = 'DESKTOP-0A0VKP5\DIMULEK' 
database = 'Project3DB'
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

dishesID = {}

def SignIn(login, password):
    setConnection()
    cursor.execute(f"SELECT ID_Visitor, Role_ID, Email_Visitor FROM Visitor where Login_Visitor = \'{login}\' and Password_Visitor = \'{password}\'")
    table = cursor.fetchall()
    try:
        if(sendCode(table[0][2]) == False):
            return
    except: 
        print("Произошла ошибка при авторизации!")
        return
    print("Вы успешно авторизировались!\n")
    global roleID
    global visitorID
    visitorID = table[0][0]
    roleID = table[0][1]
    cursor.execute(f"exec addMoney {visitorID}")
    cursor.commit()
    cnxn.close()

def Register(login, password, email):
    try:
        if(sendCode(email) == False):
            return
    except: 
        print("Не удалось отправить код!")
        return
    setConnection()
    cursor.execute(f"SELECT count(*) from Visitor where Login_Visitor = \'{login}\'")
    
    if(cursor.fetchall()[0][0] == 0):
        cursor.execute(f"INSERT INTO Visitor (Login_Visitor, Password_Visitor, Email_Visitor) values(\'{login}\', \'{password}\', \'{email}\')")
        cursor.commit()
    cnxn.close()

def getBalance():
    setConnection()
    cursor.execute(f"SELECT Money_Left from Visitor Where ID_Visitor = {visitorID}")
    print(cursor.fetchall()[0][0])
    cnxn.close()
    if(roleID == 1):
        getCardType(visitorID)

def getCardType(visitor):
    setConnection()
    cursor.execute(f"SELECT * from getCardType({visitor})")
    table = cursor.fetchall()
    print(f"Тип карты - {table[0][0]}\nПроцент скидки - {table[0][1]}")
    cnxn.close()

def getAllIngridientsTypes():
    setConnection()
    cursor.execute(f"SELECT ID_IngridientType, Name_IngridientType FROM IngridientType where Name_IngridientType != 'Ошибка' order by ID_IngridientType ASC")
    table = cursor.fetchall()
    cnxn.close()
    return table

def getAllIngridientsOfTypes(IngridientID):
    setConnection()
    cursor.execute(f"SELECT ID_Ingridient, Name_Ingridient, Count_Ingridient, CostInDish_Ingridient, Cost_Ingridient FROM Ingridient where IngridientType_ID = {IngridientID} order by ID_Ingridient ASC")
    table = cursor.fetchall()
    cnxn.close()
    return table
 
def updateIngridient(Ingridient, costIngridient):
    try:
        if(costIngridient < Ingridient[4]):
            return
    except:
        return
    setConnection()
    cursor.execute(f"UPDATE Ingridient set CostInDish_Ingridient = {costIngridient} WHERE ID_Ingridient = {Ingridient[0]}")
    cursor.commit()
    cnxn.close()

def updateIngridientCount(Ingridient, countIngridient):
    try:
        if(countIngridient < 1):
            return
    except:
        return
    setConnection()
    cursor.execute(f"exec buyMoreIngridients {visitorID}, {Ingridient[0]}, {countIngridient}")
    cursor.commit()
    cnxn.close()

def getAllIngridientsOfDish(dishNumber):
    setConnection()
    print("DishNuber = "); 
    print(dishNumber); 
    print("OrderID = "); 
    print(orderID); 
    cursor.execute(f"SELECT ID_DishIngridients, Name_Ingridient from DishesOfOrder inner join DishIngridients on DishesOfOrder_ID = ID_DishesOfOrder inner join Ingridient on Ingridient_ID = ID_Ingridient where DishesOfOrder_ID = (select ID_DishesOfOrder from DishesOfOrder where OrderOfVisitor_ID = {orderID} ORDER BY ID_DishesOfOrder ASC OFFSET ({dishNumber-1}) ROWS FETCH NEXT 1 ROWS ONLY)")
    table = cursor.fetchall()
    cnxn.close()
    return table

def createOrderWithCountDishes(countOfDish):
    try:
        if(countOfDish < 1):
            SignOut()
            return
    except:
        return
    global countDishes
    countDishes = countOfDish
    
    setConnection()
    cursor.execute(f"INSERT into OrderOfVisitor (Visitor_ID, DishCount_OrderOfVisitor) values ({visitorID}, {countOfDish})")
    cursor.commit()
    cursor.execute(f"SELECT ID_OrderOfVisitor from OrderOfVisitor where Visitor_ID = {visitorID} order by ID_OrderOfVisitor DESC")
    global orderID
    orderID = cursor.fetchall()[0][0]
    while(countOfDish > 0):
        cursor.execute(f"INSERT into DishesOfOrder(OrderOfVisitor_ID) values ({orderID})")
        cursor.commit()
        countOfDish = countOfDish-1
    cnxn.close()

def addIngridientInDish(ingridientID, dishNumber):
    setConnection()
    cursor.execute(f"exec buyNewIngridient {orderID}, {dishNumber}, {ingridientID}")
    cursor.commit()
    cnxn.close()

def removeIngridientFromDish(dish_ID, orderIngridientID):
    setConnection()
    cursor.execute(f"EXEC removeIngridient {orderID}, {dish_ID}, {orderIngridientID}")
    cursor.commit()
    cnxn.close()

def lookHistory(clientID):
    setConnection()
    cursor.execute(f"SELECT ID_DishesOfOrder, FullCost_DishesOfOrder - ((FullCost_DishesOfOrder/100) * Percent_OrderOfVisitor),OrderOfVisitor_ID, String_AGG(Name_Ingridient, '|') from DishesOfOrder inner join OrderOfVisitor on OrderOfVisitor_ID = ID_OrderOfVisitor left join DishIngridients on ID_DishesOfOrder = DishesOfOrder_ID left join Ingridient on ID_Ingridient = Ingridient_ID where Visitor_ID = {clientID} and Status_OrderOfVisitor = 1 Group by ID_DishesOfOrder, FullCost_DishesOfOrder, Percent_OrderOfVisitor, OrderOfVisitor_ID")
    dishIndex = 1
    for row in cursor.fetchall():
        dishContext = (str(row[3])).replace("|", "\n\t")
        print(f"Лазанья №{dishIndex}: Стоимость - {row[1]}\nСостав:\n\t{dishContext}")
        dishIndex = dishIndex + 1
    cnxn.close()

def orderSuccsess():
    global orderID
    global countDishes
    setConnection()
    cursor.execute(f"EXEC succsessOrder {orderID}, {visitorID}")
    cursor.commit()
    cnxn.close()
    setConnection()
    cursor.execute(f"SELECT Status_OrderOfVisitor from OrderOfVisitor where ID_OrderOfVisitor = {orderID}")
    status = str(cursor.fetchall()[0][0])
    print(status)
    if(status == "1"):
        orderID = - 1
        countDishes = -1
        print("Заказ успешно оформлен!")
    cnxn.close()

def orderDelete():
    global orderID
    global countDishes
    orderID = - 1
    countDishes = -1
    setConnection()
    cursor.execute(f"EXEC deleteOrder {orderID}")
    cursor.commit()
    cnxn.close()

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

def getAdminWindow():
    print("AdminLog\n\n")
    match(input("1) Посмотреть историю заказов выбранного пользователя \n2) Изменить данные ингридиентов \n3) Выйти")):
        case "1":
            try:
                idVisitor = int(input("Введите номер пользователя\n"))
                lookHistory(idVisitor)
                getCardType(idVisitor)
            except:
                return
        case "2":
            getBalance()
            linesSize = getWindowComponent(getAllIngridientsTypes(), 1, 1)
            try:
                chooseline = int(input("\n"))
            except:
                return
            if(chooseline < 1 or chooseline > linesSize + 1):
                return
            IngridientsList = getAllIngridientsOfTypes(chooseline)
            linesSize = getWindowComponent(IngridientsList, 4, 1)
            try:
                chooseline = int(input("\n\nВыбирите ингридиент\n"))
            except:
                return
            if(chooseline < 1 or chooseline > linesSize + 1):
                return
    
            try:
                chooseAct = int(input("\n1) Изенить стоимости игридиента для пользователя\n2) Увеличить количество на складе\n"))
                if(chooseAct == 1):
                    updateIngridient(IngridientsList[chooseline-1], float(input("Enter new cost\n")));
                if(chooseAct == 2):
                    updateIngridientCount(IngridientsList[chooseline-1], int(input("Enter count of buing\n")))
            except:
                return
        case "3":
            SignOut()

def getUserWindow():

    if(countDishes < 1 or orderID == -1):
        match(input("1) Сделать заказ \n2) Посмотрет историяю \n3) Выйти\n")):
            case "1":
                try:
                    createOrderWithCountDishes(int(input("Введите количество покупаемого продукта. (При 5 и более блюд скидка 5%)\n")))
                except:
                    return
            case "2":
                lookHistory(visitorID)
            case "3":
                SignOut()
    else:
        print("\n\nVisitorLog\n\n")
        getBalance()
        index = 1
        while(index <= countDishes):
            print(f"{index}) Лазанья")
            index += 1
        try:
            chooseLine = int(input("Выбирите номер блюда\n-1) Завершить заказ\n-2) Отменить заказ"))
        except:
            return
        if(chooseLine == -1):
            orderSuccsess()
            return
        if(chooseLine == -2):
            orderDelete()
            return
        try:
            chooseAct = int(input("Выбирете действие\n1) Добавить новый ингридиент\n2) Удалить ингридиент\n"))
        except:
            return
        if(chooseAct == 1):
            linesSize = getWindowComponent(getAllIngridientsTypes(), 1, 1)
            try:
                chooselineIngridientType = int(input("\n"))
            except:
                return
            if(chooselineIngridientType < 1 or chooselineIngridientType > linesSize + 1):
                return
            IngridientsList = getAllIngridientsOfTypes(chooselineIngridientType)
            linesSize = getWindowComponent(IngridientsList, 3, 1)
            try:
                chooselineIngridient = int(input("\n\nВыбирите ингридиент\n"))
            except:
                return
            if(chooselineIngridient <= 0 or chooselineIngridient > linesSize):
                return
            addIngridientInDish(IngridientsList[chooselineIngridient-1][0], chooseLine)
        if(chooseAct == 2):
            ingridientsOfDish = getAllIngridientsOfDish(chooseLine)
            lineSize = getWindowComponent(ingridientsOfDish, 1,1)
            try:
                chooseline = int(input())
            except:
                return
            if(chooseline < 1 or chooseline > lineSize):
                return
            removeIngridientFromDish(chooseLine, ingridientsOfDish[chooseline-1][0])
        
        
def SignOut():
    global roleID
    global visitorID
    roleID = -1
    visitorID = -1

def sendCode(emeil):
    return True;
    try:
        smtpObj = smtplib.SMTP('smtp.gmail.com', 587)
        smtpObj.starttls()
        smtpObj.ehlo()
        smtpObj.login('pythonforproject737@gmail.com','fpdxbksjsyqlnuza')
        rand = random.randint(0, 99999)
        smtpObj.sendmail("PythonForProject737@gmail.com",emeil, str(rand))
        smtpObj.quit()
    except:
        print("Не удалось отправить код подтверждения на почту!")
        return False
    return str(rand) == input("Введите код подтверждения\n")

while(1):
    if(roleID == -1 and visitorID == -1):
        chose = input("Выберите действие\n1) Авторизация\n2) Регистрация\n")
        if(chose == "1"):
            SignIn(input("  Ввдите логин\n"), input("  Введите пароль\n"))
        if(chose == "2"):
            Register(input("  Придумайте свой логин\n"), input("  Придумайте пароль\n"), input("  Введите свою почту\n"))
        continue
    if(roleID == 1):
        getUserWindow()
    if(roleID == 2):
        getAdminWindow()