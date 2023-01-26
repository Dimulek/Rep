firstNumber = int(input("Введите первое число\n"))
while 1:
    act = int(input("1) Сумма\n2) Разность\n3) Умножение\n4) Деление\n5) Завершить вычисления\n"))

    if(act == 5):
        break
    secondNumber = int(input("Введите второе число\n"))
    if(act == 1):
        print("Сложение")
        firstNumber = firstNumber + secondNumber
    if(act == 2):
        print("Вычитание")
        firstNumber = firstNumber - secondNumber
    if(act == 3):
        print("Умножение")
        firstNumber = firstNumber * secondNumber
    if(act == 4):
        print("Деление")
        firstNumber = firstNumber / secondNumber
    print(f"Ответ = {firstNumber}\n")
print(f"Конечный ответ = {firstNumber}\n")