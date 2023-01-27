SummDays = 0

def math(monthName, daysCount):
    global SummDays
    count = 0
    for i in range(int(daysCount+1)):
        for string in str(i):
            count += int(string)
    
    print(monthName + " - " + str(count))
    SummDays +=count
    return count        

math("Январь",31)
if(int(input("Високостный? (1 - да)")) == 1):
    math("Февраль",29)
else:
    math("Февраль",28)
math("Март",31)
math("Апрель",30)
math("Май",31)
math("Июнь",30)
math("Июль",31)
math("Август",31)
math("Сентябрь",30)
math("Октябрь",31)
math("Ноябрь",30)
math("Декабрь",31)

print(SummDays)