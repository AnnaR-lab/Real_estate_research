-- Задача 1: Время активности объявлений

--Категории по количеству дней активности: 
--Fast:   1-30 days — около одного месяца;
--Short:  31-90 days — от одного до трёх месяцев;
--Medium: 91-180 days — от трёх месяцев до полугода;
--Long:   181+ days — более полугода
--Non category: в продаже


--Для каждой категории изучите количество продаваемых квартир, а также их параметры:
-- включая среднюю стоимость квадратного метра, 
-- среднюю площадь недвижимости, 
-- количество комнат и балконов. 

--Сравните объявления Санкт-Петербурга и городов Ленинградской области.
--При работе с данными используйте только объявления о продаже недвижимости в городах за 2015–2018 годы включительно.


-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS (
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
-- Категоризация по локациям, Категоризация по дням активности, расчет цены за 1 м2
-- Фильтр для объявлений 2015 - 2018, фильтр по населенным пунктам типа "Город"
filtered_flats AS (
	SELECT *, 
		CASE 
			WHEN f.city_id = '6X8I' THEN 'Санкт-Петербург'
			ELSE 'ЛенОбл'
		END AS i_location,
		CASE 
			WHEN a.days_exposition BETWEEN 1 AND 30 THEN '1: 1-30 days'
			WHEN a.days_exposition BETWEEN 31 AND 90 THEN '2: 31-90 days'
			WHEN a.days_exposition BETWEEN 91 AND 180 THEN '3: 91-180 days'
			WHEN a.days_exposition IS NULL THEN '5: Non Category'
			ELSE '4: 181+ days'
		END AS category,
		a.last_price / f.total_area AS sq_meter_price,
		CASE 
			WHEN f.floor = 1 OR f.floor = f.floors_total THEN 1
			ELSE 0
		END AS floor_mark
	FROM real_estate.flats f
	LEFT JOIN real_estate.advertisement a USING(id)
	WHERE EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018
		AND f.id IN (SELECT id FROM filtered_id)
		AND type_id = 'F8EM'
)
SELECT i_location, 
		category,
		COUNT(id) AS total_adds,
		ROUND(COUNT(id) / (SUM(COUNT(id)) OVER(PARTITION BY i_location)), 3) AS category_share,
		ROUND(AVG(sq_meter_price)::NUMERIC) AS avg_sq_meter_price,
		ROUND(AVG(total_area)::NUMERIC, 1) AS avg_total_area,
		ROUND(AVG(rooms)::NUMERIC) AS avg_rooms,
		PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY rooms) AS P50_rooms,
		ROUND(AVG(balcony)::NUMERIC, 1) AS avg_balcony,
		PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY balcony) AS P50_balcony,
		ROUND(AVG(kitchen_area)::NUMERIC, 1) AS kitchen_area,
		ROUND(AVG(floor_mark)::NUMERIC, 3) AS share_of_last_floor_adds,
		ROUND(AVG(floor), 1) AS avg_floor,
		PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY floor) AS P50_floor,
		AVG(ceiling_height) AS avg_ceiling_height,
		ROUND(COUNT(id) FILTER(WHERE rooms = 0) / COUNT(id)::NUMERIC, 3) AS studio_share,
		ROUND(COUNT(id) FILTER(WHERE rooms = 1) / COUNT(id)::NUMERIC, 3) AS single_room_share,
		ROUND(COUNT(id) FILTER(WHERE rooms = 2) / COUNT(id)::NUMERIC, 3) AS double_room_share,
		ROUND(COUNT(id) FILTER(WHERE is_apartment = 1) / COUNT(id)::NUMERIC, 3) AS appartment_share,
		ROUND(COUNT(id) FILTER(WHERE open_plan  = 1) / COUNT(id)::NUMERIC, 3) AS open_plan_share,
		AVG(airports_nearest) AS avg_airport_distance,
		PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY parks_around3000) AS P50_park_num,
		PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY ponds_around3000) AS P50_pond_num
FROM filtered_flats
GROUP BY i_location, category
ORDER BY i_location, category;
