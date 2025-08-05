-- Прежде всего нужно получить очищенные табличные данные

with tab_data as
    (select
        card as client_id,
        doc_id,
        datetime::date as date,
        max(datetime::date) over() as curr_date,
        summ_with_disc
    from bonuscheques
    where length(card) = 13);

-- В очищенной таблице я убрала все записи о покупках, которые совершались в оффлайн режиме. В данном случае это избавляет нас от анонимных покупателей. Выделила даты первой и последующих покупок каждого покупателя.

-- Далее высчитываю RFM-метрики:

rfm_metrika as
    (select
        client_id,
        min(curr_date - date) as recency,
        count(distinct doc_id) as frequency,
        sum(summ_with_disc) as monetary
    from tab_data
    group by client_id);

-- Границы сегментов определяю с помощью перцентилей. Данный инструмент позволяет нам разложить на равные группы весь массив данных. В итоге разбиваю покупателей на 3 группы:

rfm_gruppa as
    (select
        percentile_cont(0.33) within group (order by recency) as r_group1,
        percentile_cont(0.66) within group (order by recency) as r_group2,
        percentile_cont(0.33) within group (order by frequency) as f_group1,
        percentile_cont(0.66) within group (order by frequency) as f_group2,
        percentile_cont(0.33) within group (order by monetary) as m_group1,
        percentile_cont(0.66) within group (order by monetary) as m_group2
    from rfm_metrika);

-- В зависимости от границ присваиваю оценки от 1 до 3:

rfm_gran as
    (select
        client_id,
        recency,
        frequency,
        monetary,
        case
            when recency <= r_group1 then 3
            when recency <= r_group2 then 2
            else 1
            end as r_gr,
        case
            when frequency <= f_group1 then 1
            when frequency <= f_group1 then 2
            else 3
            end as f_gr,
        case
            when monetary <= f_group1 then 1
            when monetary <= f_group1 then 2
            else 3
            end as m_gr
    from rfm_metrika
    cross join rfm_gruppa);

-- На основе оценки определяю сегменты. Я выделила 7 логических групп, т.к. не имеет смысла работать по отдельной схеме с каждой группой (27). Это слишком затратно. Сегменты дополняю бизнес-логикой:

rfm_segment as
    (select
        client_id,
        recency,
        frequency,
        monetary,
        r_gr,
        f_gr,
        m_gr,
        concat(r_gr, f_gr, m_gr) as rfm_cell,
        case
            when concat(r_gr, f_gr, m_gr) in ('111') then 'Самые активные'
            when concat(r_gr, f_gr, m_gr) in ('121', '131', '123', '122', '113', '112') then 'Лояльные покупатели'
            when concat(r_gr, f_gr, m_gr) in ('133', '132') then 'Новые покупатели'
            when concat(r_gr, f_gr, m_gr) like '2%' then 'Спящие'
            when concat(r_gr, f_gr, m_gr) like '31%' then 'Бывшие лояльные'
            when concat(r_gr, f_gr, m_gr) like '32%' then 'На грани ухода'
            when concat(r_gr, f_gr, m_gr) like '33%' then 'Потерянные'
            end as segment
    from rfm_gran);

-- По итогу составляю финальный отчёт с рекомендациями по маркетинговым действиям. Получается 7 рабочих сегментов, которые объединены общими паттернами поведения:

select
    segment,
    count(*) as customers_cnt,
    round(count(*) * 100 / (select count(*) from rfm_segment), 2) as percent_total,
    round(avg(recency), 2) as avg_r_days,
    round(avg(frequency), 2) as avg_f,
    round(avg(monetary), 2) as avg_m,
    round(sum(monetary), 2) as sum_m,
    round(sum(monetary) * 100 / (select sum(monetary) from rfm_segment), 2) as revenue_percent,
    case segment
        when 'Самые активные' then 'Покупали часто, недавно и много'
        when 'Лояльные покупатели' then 'Тратят немного, но регулярно'
        when 'Новые покупатели' then 'Одна покупка'
        when 'Спящие' then 'Недавно совершали покупку'
        when 'Бывшие лояльные' then 'Покупали часто, но давно'
        when 'На грани ухода' then 'Покупали давно и редко'
        when 'Потерянные' then 'Перестали совершать покупки'
        end as marketing,
    case segment
        when 'Самые активные' then 'Предложить персональную скидку, вступление в премиальную программу'
        when 'Лояльные покупатели' then 'Предложить подарки, начисление бонусов за сделанные покупки'
        when 'Новые покупатели' then 'Поздравить с покупкой, предложить выгодные акции'
        when 'Спящие' then 'Рассказать о действующих акциях'
        when 'Бывшие лояльные' then 'Предложить индивидуальную скидку на основе изучения прошлых покупок'
        when 'На грани ухода' then 'Предложить дополнительные бонусы при совершении покупки в ближайшие недели'
        when 'Потерянные' then 'Не целесообразно. Необходимо дополнительно изучить чеки данной группы и в зависимости от группы товара/суммы чека пересмотреть маркетинг'
        end as recommended
    from rfm_segment
    group by segment
    order by revenue_percent desc
