# Data Description

This file contains a detailed description of the tables and columns used in the real estate project for Saint Petersburg and the Leningrad Region.

## Table: advertisement
Contains information about property listings.

| Column                | Type   | Description                                             |
|-----------------------|--------|---------------------------------------------------------|
| `id`                  | int    | Listing identifier (primary key)                        |
| `first_day_exposition`| date   | Date the listing was posted                              |
| `days_exposition`     | int    | Duration of listing on the website (in days)            |
| `last_price`          | float  | Price of the apartment in RUB                            |

---

## Table: flats
Contains information about apartments.

| Column             | Type    | Description                                                                 |
|-------------------|---------|-----------------------------------------------------------------------------|
| `id`               | int     | Apartment identifier (primary key, linked to `advertisement.id`)             |
| `city_id`          | int     | City identifier (foreign key, linked to `city.city_id`)                      |
| `type_id`          | int     | Settlement type identifier (foreign key, linked to `type.type_id`)           |
| `total_area`       | float   | Total area of the apartment (m²)                                           |
| `rooms`            | int     | Number of rooms                                                             |
| `ceiling_height`   | float   | Ceiling height (m)                                                          |
| `floors_total`     | int     | Total number of floors in the building                                      |
| `living_area`      | float   | Living area (m²)                                                            |
| `floor`            | int     | Floor on which the apartment is located                                     |
| `is_apartment`     | int     | Whether the apartment is an “apartment” type (1 — yes, 0 — no)             |
| `open_plan`        | int     | Whether the apartment has an open plan layout (1 — yes, 0 — no)             |
| `kitchen_area`     | float   | Kitchen area (m²)                                                           |
| `balcony`          | int     | Number of balconies                                                          |
| `airports_nearest` | float   | Distance to the nearest airport (meters)                                    |
| `parks_around3000` | int     | Number of parks within a 3 km radius                                        |
| `ponds_around3000` | int     | Number of water bodies within a 3 km radius                                  |

---

## Table: city
Contains information about cities.

| Column     | Type   | Description                        |
|------------|--------|------------------------------------|
| `city_id`  | int    | City identifier (primary key)      |
| `city`     | str    | Name of the city                   |

---

## Table: type
Contains information about settlement types.

| Column    | Type   | Description                           |
|-----------|--------|---------------------------------------|
| `type_id` | int    | Settlement type identifier (primary key) |
| `type`    | str    | Name of the settlement type           |
