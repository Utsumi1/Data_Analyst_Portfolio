--- В данном скрипте отображены запросы к БД клиники для оценки и подведения итогов её работы

-- Общее количество оказанных услуг
select count(*)
  from orders;

-- Количество уникальных пациентов
select count(distinct client_id) as cnt_client
  from orders;

-- Количество постоянных пациентов
select count(*)
  from (select pet_id
        from orders
        group by pet_id
        having count(*) > 1) as returning_pets;

-- Среднее количество приёмов на одного пациента (посещаемость), за всё время
select count(client_id) / count (distinct client_id)
from orders;

-- Общее количество оказанных услуг по врачам
with cnt_employee_priem as
  (select employee_id, date, count(*) as cnt
  from orders
  group by employee_id, date)
select fio, sum(cnt) as sum_cnt
  from cnt_employee_priem as c
  join employee as e
  on c.employee_id = e.id
  group by fio

--Количество проданных абонементов
select count(pet_id) as cnt_abon
  from orders
  where service_id > 15 and discont_id is null

-- Средняя длительность лечения (между первым и последним визитом)
with treat_pet as
  (select pet_id, max(date) - min(date) as days
  from orders
  group by pet_id)
select round(avg(days), 0)
  from treat_pet;

--- Общий доход за всё время работы клиники
with amount as
  (select client_id,  price, percent,
  case when discont_id = null then price * percent * quantity
        when discont_id >= 1 then (price-(price*percent)/100)*quantity
  end amount_price
  from orders as o
  join service as s
  on o.service_id = s.id
  full join discont as d
  on o.discont_id = d.id)
select sum(amount_price)
  from amount;

-- Средний чек (ARPV)
with sum_amount as
  (select sum(amount) as summ -- доход за весь год
  from (select o.id, date, service_id, client_id, quantity, discont_id, percent, price, s.name,
  case when discont_id is not null then (price-(price*percent)/100)*quantity
  else price*quantity end amount
  from orders as o
  full join discont as d
  on o.discont_id = d.id
  join service as s
  on o.service_id = s.id) as a),
cnt_client as
  (select sum(cnt_day) as sum_cnt -- количество посещений уникальных пациентов
  from (select date, count(distinct client_id) as cnt_day
        from orders
        group by date) as cnt_d)
select
  round(summ/sum_cnt, 2) as avg_client_sum
  from sum_amount, cnt_client;