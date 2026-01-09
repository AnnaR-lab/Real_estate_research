-- Задача 2: Сезонность объявлений
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
filtered_id AS(
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
-- Расчет цены за 1 м2
-- Фильтр для объявлений 2015 - 2018, фильтр по населенным пунктам типа "Город"
-- Итого 14045 объявлений
filtered_flats AS (
	SELECT f.id,
		DATE_TRUNC('month', a.first_day_exposition)::date AS start_date,
		CASE 
			WHEN a.days_exposition IS NULL THEN NULL 
			ELSE DATE_TRUNC('month', a.first_day_exposition + (a.days_exposition * INTERVAL '1 day'))::date
		END AS close_date,
		a.last_price / f.total_area AS sq_meter_price,
		f.total_area 
	FROM real_estate.flats f
	LEFT JOIN real_estate.advertisement a USING(id)
	WHERE EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018
		AND f.id IN (SELECT id FROM filtered_id)
		AND type_id = 'F8EM'
),
-- Расчет открытых объявлений по месяцам
-- Итого 14045 объявлений
new_adds AS (
	SELECT  
		TO_CHAR(start_date, 'TMMonth')  AS i_month,
		EXTRACT(MONTH FROM start_date) AS i_num_month,
		COUNT(id) AS new_adds,
		ROUND(AVG(sq_meter_price)) AS avg_sq_meter_price,
		ROUND(AVG(total_area)::NUMERIC, 1) AS avg_total_area
	FROM filtered_flats
	GROUP BY i_month, i_num_month
),
-- Расчет открытых объявлений по месяцам
-- Итого 13194 объявлений
closed_adds AS (
	SELECT  
		TO_CHAR(close_date, 'TMMonth')  AS i_month, 
		COUNT(id) AS closed_adds,
		ROUND(AVG(sq_meter_price)) AS avg_sq_meter_price,
		ROUND(AVG(total_area)::NUMERIC, 1) AS avg_total_area
	FROM filtered_flats
	WHERE close_date IS NOT NULL 
	GROUP BY i_month
)
SELECT  
		na.i_month, 
		na.new_adds AS total_new_ads,
		ROUND(na.new_adds / (SUM(na.new_adds) OVER())::NUMERIC, 3) AS total_new_ads_share,
		RANK() OVER(ORDER BY na.new_adds DESC) AS new_adds_rank,
		na.avg_sq_meter_price AS new_AVG_sq_meter_price,
		na.avg_total_area AS new_AVG_total_area,
		ca.closed_adds AS total_closed_ads,
		ROUND(ca.closed_adds / (SUM(ca.closed_adds) OVER())::NUMERIC, 3) AS total_closed_ads_share,
		RANK() OVER(ORDER BY ca.closed_adds DESC) AS closed_adds_rank,
		ca.avg_sq_meter_price AS closed_AVG_sq_meter_price,
		ca.avg_total_area AS closed_AVG_total_area
FROM new_adds na
LEFT JOIN closed_adds ca USING(i_month)
ORDER BY na.i_num_month;
