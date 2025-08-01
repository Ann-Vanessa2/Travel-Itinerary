-- TRAVEL ANALYTICS STAR SCHEMA

-- DIMENSION TABLES

-- Date Dimension
CREATE TABLE dim_date (
    date_key INTEGER PRIMARY KEY,
    date_value DATE NOT NULL,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    week_of_year INTEGER NOT NULL,
    day_of_month INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT FALSE,
    season VARCHAR(20) NOT NULL
);

-- User Dimension
CREATE TABLE dim_user (
    user_key INTEGER PRIMARY KEY,
    user_id BIGINT NOT NULL,
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    full_name VARCHAR(511),
    role_name VARCHAR(50),
    is_enabled BOOLEAN DEFAULT TRUE,
    registration_date DATE,
    user_tenure_days INTEGER,
    user_status VARCHAR(20)
);

-- Destination Dimension
CREATE TABLE dim_destination (
    destination_key INTEGER PRIMARY KEY,
    destination_id INTEGER NOT NULL,
    destination_name VARCHAR(255) NOT NULL,
    description VARCHAR(2000),
    state VARCHAR(255),
    country VARCHAR(255),
    region VARCHAR(100),
    continent VARCHAR(50),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_description VARCHAR(255),
    destination_type VARCHAR(50)
);

-- Activity Dimension
CREATE TABLE dim_activity (
    activity_key INTEGER PRIMARY KEY,
    activity_id INTEGER NOT NULL,
    activity_name VARCHAR(255) NOT NULL,
    description VARCHAR(2000),
    address VARCHAR(255),
    destination_key INTEGER,
    price_amount DOUBLE PRECISION,
    price_currency VARCHAR(10),
    price_tier VARCHAR(20), -- Low, Medium, High, Premium
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_description VARCHAR(255),
    primary_category VARCHAR(100),
    all_categories VARCHAR(500), -- Comma-separated for reporting
    travel_styles VARCHAR(200), -- Comma-separated travel styles
    has_reviews BOOLEAN DEFAULT FALSE,
    avg_rating DECIMAL(3,2),
    review_count INTEGER DEFAULT 0,
    FOREIGN KEY (destination_key) REFERENCES dim_destination(destination_key)
);

-- Trip Dimension
CREATE TABLE dim_trip (
    trip_key INTEGER PRIMARY KEY,
    trip_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    trip_status VARCHAR(50) NOT NULL,
    trip_duration_days INTEGER,
    number_of_travelers INTEGER NOT NULL DEFAULT 1,
    traveler_group_size VARCHAR(20), -- Solo, Couple, Small Group, Large Group
    total_budget DOUBLE PRECISION,
    budget_tier VARCHAR(20), -- Budget, Mid-range, Luxury
    created_by_user_key INTEGER,
    trip_complexity VARCHAR(20), -- Simple, Moderate, Complex (based on destinations/activities)
    FOREIGN KEY (created_by_user_key) REFERENCES dim_user(user_key)
);

-- Category Dimension
CREATE TABLE dim_category (
    category_key INTEGER PRIMARY KEY,
    category_id INTEGER NOT NULL,
    category_name VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    category_type VARCHAR(50) -- Activity, Destination, etc.
);

-- FACT TABLES

-- Trip Fact Table (Main fact table for trip analysis)
CREATE TABLE fact_trip (
    trip_key INTEGER NOT NULL,
    user_key INTEGER NOT NULL,
    start_date_key INTEGER NOT NULL,
    end_date_key INTEGER NOT NULL,
    created_date_key INTEGER NOT NULL,
    
    -- Measures
    trip_duration_days INTEGER NOT NULL,
    total_budget DOUBLE PRECISION,
    number_of_travelers INTEGER NOT NULL,
    destination_count INTEGER DEFAULT 0,
    activity_count INTEGER DEFAULT 0,
    participant_count INTEGER DEFAULT 1,
    invitation_count INTEGER DEFAULT 0,
    accepted_invitation_count INTEGER DEFAULT 0,
    
    -- Derived measures
    budget_per_traveler DOUBLE PRECISION,
    budget_per_day DOUBLE PRECISION,
    
    PRIMARY KEY (trip_key, user_key),
    FOREIGN KEY (trip_key) REFERENCES dim_trip(trip_key),
    FOREIGN KEY (user_key) REFERENCES dim_user(user_key),
    FOREIGN KEY (start_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (end_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (created_date_key) REFERENCES dim_date(date_key)
);

-- Activity Fact Table (For activity-level analysis)
CREATE TABLE fact_activity_usage (
    activity_key INTEGER NOT NULL,
    trip_key INTEGER NOT NULL,
    user_key INTEGER NOT NULL,
    destination_key INTEGER NOT NULL,
    scheduled_date_key INTEGER,
    
    -- Measures
    activity_price DOUBLE PRECISION,
    display_order INTEGER,
    has_notes BOOLEAN DEFAULT FALSE,
    has_reminder BOOLEAN DEFAULT FALSE,
    
    PRIMARY KEY (activity_key, trip_key),
    FOREIGN KEY (activity_key) REFERENCES dim_activity(activity_key),
    FOREIGN KEY (trip_key) REFERENCES dim_trip(trip_key),
    FOREIGN KEY (user_key) REFERENCES dim_user(user_key),
    FOREIGN KEY (destination_key) REFERENCES dim_destination(destination_key),
    FOREIGN KEY (scheduled_date_key) REFERENCES dim_date(date_key)
);

-- Expense Fact Table (For financial analysis)
CREATE TABLE fact_expense (
    expense_key INTEGER PRIMARY KEY,
    trip_key INTEGER NOT NULL,
    activity_key INTEGER,
    user_key INTEGER NOT NULL,
    expense_date_key INTEGER NOT NULL,
    
    -- Measures
    expense_amount DOUBLE PRECISION NOT NULL,
    activity_name VARCHAR(255),
    description VARCHAR(255),
    
    FOREIGN KEY (trip_key) REFERENCES dim_trip(trip_key),
    FOREIGN KEY (activity_key) REFERENCES dim_activity(activity_key),
    FOREIGN KEY (user_key) REFERENCES dim_user(user_key),
    FOREIGN KEY (expense_date_key) REFERENCES dim_date(date_key)
);

-- Trip Destination Bridge Table (For many-to-many relationship)
CREATE TABLE bridge_trip_destination (
    trip_key INTEGER NOT NULL,
    destination_key INTEGER NOT NULL,
    PRIMARY KEY (trip_key, destination_key),
    FOREIGN KEY (trip_key) REFERENCES dim_trip(trip_key),
    FOREIGN KEY (destination_key) REFERENCES dim_destination(destination_key)
);

-- REMOVED TABLES (Not needed for analytics)

/*
REMOVED TABLES:
1. verification_token - Authentication related, not needed for analytics
2. user_permissions - Permission management, not analytical
3. permissions_user - Permission management, not analytical
4. trip_participants - Consolidated into fact_trip measures
5. trip_invitations - Consolidated into fact_trip measures
6. itineraries - Structure consolidated into fact_activity_usage
7. itinerary_item - Structure consolidated into fact_activity_usage
8. review - Aggregated into dim_activity (avg_rating, review_count)
9. activity_category - Flattened into dim_activity
10. activity_travel_styles - Flattened into dim_activity
11. expense_paid_by - Simplified expense tracking
*/


INSERT INTO dim_date (
    date_key, date_value, year, quarter, month, month_name,
    week_of_year, day_of_month, day_of_week, day_name,
    is_weekend, is_holiday, season
) VALUES
(20240101, '2024-01-01', 2024, 1, 1, 'January', 1, 1, 1, 'Monday', FALSE, TRUE, 'Winter'),
(20240106, '2024-01-06', 2024, 1, 1, 'January', 1, 6, 6, 'Saturday', TRUE, FALSE, 'Winter'),
(20240214, '2024-02-14', 2024, 1, 2, 'February', 7, 14, 3, 'Wednesday', FALSE, TRUE, 'Winter'),
(20240317, '2024-03-17', 2024, 1, 3, 'March', 11, 17, 7, 'Sunday', TRUE, TRUE, 'Spring'),
(20240401, '2024-04-01', 2024, 2, 4, 'April', 14, 1, 1, 'Monday', FALSE, FALSE, 'Spring'),
(20240406, '2024-04-06', 2024, 2, 4, 'April', 14, 6, 6, 'Saturday', TRUE, FALSE, 'Spring'),
(20240501, '2024-05-01', 2024, 2, 5, 'May', 18, 1, 3, 'Wednesday', FALSE, TRUE, 'Spring'),
(20240527, '2024-05-27', 2024, 2, 5, 'May', 22, 27, 1, 'Monday', FALSE, TRUE, 'Spring'),
(20240615, '2024-06-15', 2024, 2, 6, 'June', 24, 15, 6, 'Saturday', TRUE, FALSE, 'Summer'),
(20240704, '2024-07-04', 2024, 3, 7, 'July', 27, 4, 4, 'Thursday', FALSE, TRUE, 'Summer'),
(20240721, '2024-07-21', 2024, 3, 7, 'July', 29, 21, 7, 'Sunday', TRUE, FALSE, 'Summer'),
(20240810, '2024-08-10', 2024, 3, 8, 'August', 32, 10, 7, 'Saturday', TRUE, FALSE, 'Summer'),
(20240902, '2024-09-02', 2024, 3, 9, 'September', 36, 2, 1, 'Monday', FALSE, TRUE, 'Fall'),
(20240921, '2024-09-21', 2024, 3, 9, 'September', 38, 21, 7, 'Saturday', TRUE, FALSE, 'Fall'),
(20241031, '2024-10-31', 2024, 4, 10, 'October', 44, 31, 5, 'Thursday', FALSE, TRUE, 'Fall'),
(20241128, '2024-11-28', 2024, 4, 11, 'November', 48, 28, 5, 'Thursday', FALSE, TRUE, 'Fall'),
(20241224, '2024-12-24', 2024, 4, 12, 'December', 52, 24, 3, 'Tuesday', FALSE, TRUE, 'Winter'),
(20241225, '2024-12-25', 2024, 4, 12, 'December', 52, 25, 4, 'Wednesday', FALSE, TRUE, 'Winter'),
(20241228, '2024-12-28', 2024, 4, 12, 'December', 52, 28, 7, 'Saturday', TRUE, FALSE, 'Winter'),
(20241231, '2024-12-31', 2024, 4, 12, 'December', 53, 31, 3, 'Tuesday', FALSE, TRUE, 'Winter');


INSERT INTO dim_user (user_key, user_id, username, email, first_name, last_name, full_name, role_name, is_enabled, registration_date, user_tenure_days, user_status) VALUES
(1, 1001, 'jane.doe1', 'jane.doe1@example.com', 'Jane', 'Doe', 'Jane Doe', 'Traveler', TRUE, '2023-03-14', 492, 'Active'),
(2, 1002, 'john.smith2', 'john.smith2@example.com', 'John', 'Smith', 'John Smith', 'Admin', TRUE, '2022-09-02', 685, 'Active'),
(3, 1003, 'lisa.jones3', 'lisa.jones3@example.com', 'Lisa', 'Jones', 'Lisa Jones', 'Agent', FALSE, '2021-11-18', 970, 'Inactive'),
(4, 1004, 'mike.brown4', 'mike.brown4@example.com', 'Mike', 'Brown', 'Mike Brown', 'Traveler', TRUE, '2022-01-27', 899, 'Active'),
(5, 1005, 'emma.wilson5', 'emma.wilson5@example.com', 'Emma', 'Wilson', 'Emma Wilson', 'Moderator', TRUE, '2023-05-10', 435, 'Pending'),
(6, 1006, 'tom.jordan6', 'tom.jordan6@example.com', 'Tom', 'Jordan', 'Tom Jordan', 'Traveler', FALSE, '2022-08-19', 699, 'Suspended'),
(7, 1007, 'nina.reed7', 'nina.reed7@example.com', 'Nina', 'Reed', 'Nina Reed', 'Agent', TRUE, '2021-12-05', 953, 'Active'),
(8, 1008, 'alex.morgan8', 'alex.morgan8@example.com', 'Alex', 'Morgan', 'Alex Morgan', 'Admin', TRUE, '2023-01-15', 550, 'Active'),
(9, 1009, 'kate.hall9', 'kate.hall9@example.com', 'Kate', 'Hall', 'Kate Hall', 'Traveler', FALSE, '2021-07-30', 1081, 'Inactive'),
(10, 1010, 'ryan.king10', 'ryan.king10@example.com', 'Ryan', 'King', 'Ryan King', 'Moderator', TRUE, '2023-11-20', 241, 'Active'),
(11, 1011, 'chris.lee11', 'chris.lee11@example.com', 'Chris', 'Lee', 'Chris Lee', 'Traveler', TRUE, '2022-10-10', 647, 'Active'),
(12, 1012, 'mia.fox12', 'mia.fox12@example.com', 'Mia', 'Fox', 'Mia Fox', 'Agent', TRUE, '2023-06-25', 389, 'Pending'),
(13, 1013, 'liam.kent13', 'liam.kent13@example.com', 'Liam', 'Kent', 'Liam Kent', 'Admin', FALSE, '2021-09-14', 1035, 'Suspended'),
(14, 1014, 'zoe.clark14', 'zoe.clark14@example.com', 'Zoe', 'Clark', 'Zoe Clark', 'Moderator', TRUE, '2022-03-03', 863, 'Active'),
(15, 1015, 'ethan.wade15', 'ethan.wade15@example.com', 'Ethan', 'Wade', 'Ethan Wade', 'Traveler', TRUE, '2023-08-01', 352, 'Active'),
(16, 1016, 'sara.long16', 'sara.long16@example.com', 'Sara', 'Long', 'Sara Long', 'Agent', TRUE, '2022-12-12', 584, 'Active'),
(17, 1017, 'luke.scott17', 'luke.scott17@example.com', 'Luke', 'Scott', 'Luke Scott', 'Admin', FALSE, '2021-05-18', 1154, 'Inactive'),
(18, 1018, 'ruby.hughes18', 'ruby.hughes18@example.com', 'Ruby', 'Hughes', 'Ruby Hughes', 'Traveler', TRUE, '2023-10-05', 287, 'Pending'),
(19, 1019, 'dan.cole19', 'dan.cole19@example.com', 'Dan', 'Cole', 'Dan Cole', 'Moderator', TRUE, '2022-07-04', 745, 'Active'),
(20, 1020, 'ivy.turner20', 'ivy.turner20@example.com', 'Ivy', 'Turner', 'Ivy Turner', 'Agent', TRUE, '2021-10-29', 990, 'Suspended');


INSERT INTO dim_destination (
    destination_key, destination_id, destination_name, description, state,
    country, region, continent, latitude, longitude, location_description, destination_type
) VALUES
(1, 1001, 'Accra', 'Capital city of Ghana, known for its beaches and culture.', 'Greater Accra', 'Ghana', 'West Africa', 'Africa', 5.5600, -0.2050, 'Coastal urban city', 'City'),
(2, 1002, 'Kumasi', 'Historical city in Ashanti region.', 'Ashanti', 'Ghana', 'West Africa', 'Africa', 6.6900, -1.6300, 'Cultural and historical center', 'City'),
(3, 1003, 'Cape Coast', 'Famous for its castles and colonial history.', 'Central', 'Ghana', 'West Africa', 'Africa', 5.1100, -1.2500, 'Coastal town with rich history', 'Town'),
(4, 1004, 'Tamale', 'Gateway to northern Ghana.', 'Northern', 'Ghana', 'West Africa', 'Africa', 9.4075, -0.8533, 'Northern administrative capital', 'City'),
(5, 1005, 'Elmina', 'Known for Elmina Castle.', 'Central', 'Ghana', 'West Africa', 'Africa', 5.0847, -1.3509, 'Fishing town and tourist site', 'Town'),
(6, 1006, 'Takoradi', 'Harbor city and industrial hub.', 'Western', 'Ghana', 'West Africa', 'Africa', 4.9000, -1.7833, 'Major port city', 'City'),
(7, 1007, 'Mole National Park', 'Largest wildlife reserve in Ghana.', 'Savannah', 'Ghana', 'West Africa', 'Africa', 9.7000, -1.8000, 'Wildlife and safari destination', 'Park'),
(8, 1008, 'Lake Volta', 'One of the largest man-made lakes.', 'Volta', 'Ghana', 'West Africa', 'Africa', 7.7000, -0.1000, 'Inland water-based destination', 'Lake'),
(9, 1009, 'Boti Falls', 'Popular waterfall site in the Eastern Region.', 'Eastern', 'Ghana', 'West Africa', 'Africa', 6.2333, -0.1667, 'Natural waterfall', 'Nature'),
(10, 1010, 'Ho', 'Capital of Volta Region.', 'Volta', 'Ghana', 'West Africa', 'Africa', 6.6000, 0.4667, 'Quiet scenic town', 'City'),
(11, 1011, 'Nzulezo', 'Stilt village on water.', 'Western', 'Ghana', 'West Africa', 'Africa', 5.0167, -2.5000, 'Unique village on a lake', 'Village'),
(12, 1012, 'Wli Waterfalls', 'Tallest waterfall in West Africa.', 'Volta', 'Ghana', 'West Africa', 'Africa', 7.1333, 0.5667, 'Tropical rainforest waterfall', 'Nature'),
(13, 1013, 'Ada Foah', 'Estuary and beach town.', 'Greater Accra', 'Ghana', 'West Africa', 'Africa', 5.7833, 0.6333, 'Beach and lagoon destination', 'Beach'),
(14, 1014, 'Busua', 'Surfing and beach resort town.', 'Western', 'Ghana', 'West Africa', 'Africa', 4.8167, -1.9333, 'Popular surfing spot', 'Beach'),
(15, 1015, 'Axim', 'Historic coastal town.', 'Western', 'Ghana', 'West Africa', 'Africa', 4.8667, -2.2333, 'Quiet fishing town with history', 'Town'),
(16, 1016, 'Techiman', 'Agricultural market hub.', 'Bono East', 'Ghana', 'West Africa', 'Africa', 7.5833, -1.9333, 'Trade and farming community', 'City'),
(17, 1017, 'Wa', 'Upper West regional capital.', 'Upper West', 'Ghana', 'West Africa', 'Africa', 10.0600, -2.5090, 'Remote town in northwest Ghana', 'City'),
(18, 1018, 'Kintampo Falls', 'Beautiful cascading waterfalls.', 'Bono East', 'Ghana', 'West Africa', 'Africa', 8.0500, -1.7333, 'Tourist natural site', 'Nature'),
(19, 1019, 'Aburi', 'Mountain town with botanical gardens.', 'Eastern', 'Ghana', 'West Africa', 'Africa', 5.8500, -0.1667, 'Hill station with cool climate', 'Town'),
(20, 1020, 'Paga', 'Known for its sacred crocodile ponds.', 'Upper East', 'Ghana', 'West Africa', 'Africa', 10.9833, -0.9000, 'Cultural animal sanctuary', 'Village');


INSERT INTO dim_activity (activity_key, activity_id, activity_name, description, address, destination_key, price_amount, price_currency, price_tier, latitude, longitude, location_description, primary_category, all_categories, travel_styles, has_reviews, avg_rating, review_count) VALUES
(1, 1001, 'Ocean Kayaking Tour', 'Guided kayak tour along the coastline.', '123 Beach Ave', 1, 55.00, 'USD', 'Medium', 36.7783, -119.4179, 'California Coast', 'Outdoor Adventure', 'Outdoor,Water Sports', 'Adventure,Nature', TRUE, 4.6, 120),
(2, 1002, 'Mountain Hiking Expedition', 'Hike up to the summit with a professional guide.', 'Trailhead Rd', 2, 80.00, 'USD', 'High', 39.7392, -104.9903, 'Rocky Mountains', 'Hiking', 'Adventure,Fitness', 'Adventure,Fitness', TRUE, 4.8, 87),
(3, 1003, 'Local Wine Tasting', 'Taste premium wines from local vineyards.', '456 Winery Lane', 3, 40.00, 'USD', 'Low', 38.2975, -122.2869, 'Napa Valley', 'Food & Drink', 'Food,Drink,Local', 'Culinary,Relaxation', TRUE, 4.5, 204),
(4, 1004, 'Ancient Ruins Tour', 'Historical walk through ancient ruins.', '789 History Blvd', 1, 60.00, 'USD', 'Medium', 41.9028, 12.4964, 'Rome', 'Cultural', 'History,Walking', 'Culture,Education', TRUE, 4.7, 321),
(5, 1005, 'Jungle Safari Ride', 'Experience exotic wildlife in a natural reserve.', 'Jungle Base Camp', 2, 120.00, 'USD', 'Premium', -1.2921, 36.8219, 'Nairobi National Park', 'Wildlife Safari', 'Animals,Nature', 'Wildlife,Photography', TRUE, 4.9, 158),
(6, 1006, 'City Bike Tour', 'Explore the city on guided bike tours.', '10 Main St', 3, 25.00, 'USD', 'Low', 52.5200, 13.4050, 'Berlin Center', 'Urban Exploration', 'City,Biking,Leisure', 'Culture,Fitness', TRUE, 4.3, 76),
(7, 1007, 'Underwater Diving Session', 'Dive with professionals and see coral reefs.', 'Blue Reef Base', 4, 150.00, 'USD', 'Premium', -17.7134, 178.0650, 'Fiji Coral Coast', 'Water Sports', 'Diving,Snorkeling', 'Adventure,Nature', TRUE, 4.8, 212),
(8, 1008, 'Cooking with Locals', 'Learn to cook traditional dishes.', '89 Market Road', 1, 30.00, 'USD', 'Low', 35.6895, 139.6917, 'Tokyo', 'Cultural Activity', 'Cooking,Culture', 'Culinary,Culture', TRUE, 4.6, 94),
(9, 1009, 'Zipline Adventure', 'High-speed ziplines across forest canopy.', 'Zip Forest Base', 5, 65.00, 'USD', 'Medium', 10.5000, -85.2500, 'Costa Rica Jungle', 'Extreme Adventure', 'Zipline,Outdoor', 'Adventure,Thrill', TRUE, 4.9, 133),
(10, 1010, 'Museum Day Pass', 'All-access pass to major museums.', 'Museum Mile', 2, 18.00, 'USD', 'Low', 40.7794, -73.9632, 'New York', 'Education', 'Museums,Culture', 'Education,Culture', TRUE, 4.2, 65),
(11, 1011, 'Ski & Snowboard Package', 'Winter sports day with gear rental.', 'Snowy Hills Resort', 3, 95.00, 'USD', 'High', 46.8523, -121.7603, 'Alpine Slopes', 'Winter Sports', 'Skiing,Boarding', 'Adventure,Fitness', TRUE, 4.7, 201),
(12, 1012, 'Sunset Cruise', 'Evening boat cruise with dinner.', 'Dock 7', 4, 75.00, 'USD', 'Medium', 25.7617, -80.1918, 'Miami Marina', 'Leisure', 'Cruise,Dinner', 'Romantic,Relaxation', TRUE, 4.6, 110),
(13, 1013, 'Yoga Retreat Session', 'Morning yoga and meditation in nature.', 'Zen Camp', 1, 45.00, 'USD', 'Low', 34.0522, -118.2437, 'Los Angeles Hills', 'Wellness', 'Yoga,Meditation', 'Wellness,Relaxation', TRUE, 4.4, 67),
(14, 1014, 'Hot Air Balloon Ride', 'Panoramic view from the skies.', 'Skyfield Launchpad', 5, 180.00, 'USD', 'Premium', 33.4484, -112.0740, 'Arizona Desert', 'Scenic Tour', 'Ballooning,Adventure', 'Adventure,Scenic', TRUE, 4.9, 145),
(15, 1015, 'Local Market Experience', 'Explore traditional markets with a guide.', 'Old Town Market', 2, 20.00, 'USD', 'Low', 51.5074, -0.1278, 'London', 'Cultural', 'Markets,Local', 'Culture,Shopping', TRUE, 4.3, 53),
(16, 1016, 'Rainforest Trek', 'Guided trek through rainforest ecosystem.', 'Eco Base Camp', 4, 85.00, 'USD', 'High', -3.4653, -62.2159, 'Amazon Basin', 'Nature Walk', 'Rainforest,Trekking', 'Adventure,Nature', TRUE, 4.8, 121),
(17, 1017, 'Street Food Crawl', 'Try 10+ local dishes in one evening.', 'Food Alley', 3, 35.00, 'USD', 'Low', 13.7563, 100.5018, 'Bangkok', 'Food Tour', 'Street Food,Cultural', 'Culinary,Urban', TRUE, 4.7, 177),
(18, 1018, 'Camel Desert Ride', 'Sunset camel ride through the dunes.', 'Dune Entry Point', 5, 70.00, 'USD', 'Medium', 24.4539, 54.3773, 'Abu Dhabi Desert', 'Adventure', 'Camel Ride,Desert', 'Adventure,Scenic', TRUE, 4.6, 89),
(19, 1019, 'Artisan Workshop', 'Create your own craft with local artists.', 'Crafts Center', 1, 28.00, 'USD', 'Low', 48.8566, 2.3522, 'Paris', 'Hands-On Activity', 'Crafts,Culture', 'Culture,Learning', TRUE, 4.5, 44),
(20, 1020, 'Historic Train Ride', 'Ride a vintage train through scenic routes.', 'Old Rail Station', 2, 50.00, 'USD', 'Medium', 47.6062, -122.3321, 'Seattle', 'Sightseeing', 'Train,History', 'Scenic,Education', TRUE, 4.6, 77);


INSERT INTO dim_trip VALUES
(1, 2001, 'European Getaway', 'Completed', 12, 2, 'Couple', 3200.00, 'Mid-range', 1, 'Moderate'),
(2, 2002, 'Safari Adventure', 'Planned', 9, 4, 'Small Group', 5600.00, 'Luxury', 2, 'Complex'),
(3, 2003, 'Island Hopping', 'Cancelled', 7, 1, 'Solo', 1800.00, 'Budget', 3, 'Simple'),
(4, 2004, 'Alaskan Cruise', 'Completed', 14, 6, 'Large Group', 8200.00, 'Luxury', 4, 'Moderate'),
(5, 2005, 'Japanese Culture Tour', 'Completed', 10, 2, 'Couple', 4700.00, 'Mid-range', 5, 'Complex'),
(6, 2006, 'Australian Road Trip', 'Planned', 15, 3, 'Small Group', 3900.00, 'Budget', 6, 'Moderate'),
(7, 2007, 'South America Trek', 'Completed', 20, 5, 'Large Group', 6100.00, 'Mid-range', 7, 'Complex'),
(8, 2008, 'City Tour USA', 'Planned', 5, 1, 'Solo', 1200.00, 'Budget', 8, 'Simple'),
(9, 2009, 'Northern Lights Expedition', 'Completed', 6, 2, 'Couple', 3500.00, 'Mid-range', 9, 'Moderate'),
(10, 2010, 'Himalayan Retreat', 'Cancelled', 12, 4, 'Small Group', 4300.00, 'Mid-range', 10, 'Complex'),
(11, 2011, 'Egyptian Escape', 'Completed', 8, 3, 'Small Group', 2500.00, 'Budget', 11, 'Moderate'),
(12, 2012, 'Vietnam Culinary Tour', 'Completed', 6, 2, 'Couple', 2200.00, 'Mid-range', 12, 'Simple'),
(13, 2013, 'Bali Wellness Retreat', 'Planned', 10, 1, 'Solo', 3100.00, 'Luxury', 13, 'Simple'),
(14, 2014, 'Mediterranean Explorer', 'Completed', 11, 2, 'Couple', 5200.00, 'Luxury', 14, 'Moderate'),
(15, 2015, 'Scandinavian Summer', 'Cancelled', 7, 1, 'Solo', 1900.00, 'Budget', 15, 'Simple'),
(16, 2016, 'Andean Adventure', 'Completed', 9, 5, 'Large Group', 4800.00, 'Mid-range', 16, 'Moderate'),
(17, 2017, 'India Golden Triangle', 'Planned', 6, 3, 'Small Group', 2700.00, 'Budget', 17, 'Complex'),
(18, 2018, 'Canadian Rockies Hiking', 'Completed', 13, 4, 'Small Group', 3500.00, 'Mid-range', 18, 'Moderate'),
(19, 2019, 'New Zealand Expedition', 'Planned', 16, 6, 'Large Group', 7600.00, 'Luxury', 19, 'Complex'),
(20, 2020, 'Dubai City Break', 'Completed', 4, 2, 'Couple', 2400.00, 'Luxury', 20, 'Simple');


INSERT INTO dim_category VALUES
(1, 1001, 'Beach', 'Relaxing coastal areas with sand and sun.', 'Destination'),
(2, 1002, 'Mountain', 'High altitude scenic spots ideal for hiking.', 'Destination'),
(3, 1003, 'Cultural', 'Destinations rich in local traditions and heritage.', 'Activity'),
(4, 1004, 'Historical', 'Sites with significant historical value.', 'Activity'),
(5, 1005, 'Wildlife Safari', 'Exploration of natural habitats and animals.', 'Activity'),
(6, 1006, 'Urban City', 'Modern city destinations with diverse attractions.', 'Destination'),
(7, 1007, 'Culinary', 'Food-focused experiences and cooking tours.', 'Activity'),
(8, 1008, 'Adventure', 'Adrenaline-pumping activities like rafting and ziplining.', 'Activity'),
(9, 1009, 'Wellness', 'Retreats focused on health, yoga, and relaxation.', 'Activity'),
(10, 1010, 'Island', 'Tropical and exotic island escapes.', 'Destination'),
(11, 1011, 'Cruise', 'Traveling via luxury ships across multiple destinations.', 'Activity'),
(12, 1012, 'Hiking Trails', 'Outdoor walking trips in nature.', 'Activity'),
(13, 1013, 'Desert', 'Trips to arid landscapes with unique scenery.', 'Destination'),
(14, 1014, 'Winter Sports', 'Skiing, snowboarding and other snowy activities.', 'Activity'),
(15, 1015, 'National Parks', 'Protected nature reserves for exploration.', 'Destination'),
(16, 1016, 'Festival Tours', 'Trips scheduled around regional or international festivals.', 'Activity'),
(17, 1017, 'Photography', 'Tours centered around capturing scenic and cultural sites.', 'Activity'),
(18, 1018, 'Road Trips', 'Travel involving long drives across scenic routes.', 'Activity'),
(19, 1019, 'Backpacking', 'Low-budget travel often involving multiple stops.', 'Activity'),
(20, 1020, 'Luxury Retreat', 'High-end, all-inclusive leisure trips.', 'Activity');


INSERT INTO fact_trip (
    trip_key, user_key, start_date_key, end_date_key, created_date_key,
    trip_duration_days, total_budget, number_of_travelers,
    destination_count, activity_count, participant_count,
    invitation_count, accepted_invitation_count,
    budget_per_traveler, budget_per_day
) VALUES
(1, 1, 20240701, 20240707, 20240615, 7, 1400.00, 2, 3, 5, 2, 4, 3, 700.00, 200.00),
(2, 2, 20240810, 20240820, 20240705, 11, 3000.00, 4, 2, 7, 4, 6, 5, 750.00, 272.73),
(3, 3, 20240915, 20240918, 20240801, 4, 1200.00, 1, 1, 3, 1, 1, 1, 1200.00, 300.00),
(4, 4, 20240722, 20240729, 20240610, 8, 2500.00, 3, 4, 6, 3, 5, 4, 833.33, 312.50),
(5, 5, 20240805, 20240809, 20240701, 5, 1000.00, 2, 1, 2, 2, 2, 2, 500.00, 200.00),
(6, 6, 20240718, 20240725, 20240620, 8, 1800.00, 2, 2, 4, 2, 2, 2, 900.00, 225.00),
(7, 7, 20240901, 20240910, 20240810, 10, 2200.00, 3, 3, 5, 3, 4, 3, 733.33, 220.00),
(8, 8, 20240815, 20240817, 20240720, 3, 600.00, 1, 1, 1, 1, 1, 1, 600.00, 200.00),
(9, 9, 20240705, 20240714, 20240601, 10, 2800.00, 4, 3, 6, 4, 4, 4, 700.00, 280.00),
(10, 10, 20240725, 20240801, 20240625, 8, 1500.00, 2, 2, 3, 2, 3, 2, 750.00, 187.50),
(11, 11, 20240810, 20240814, 20240715, 5, 900.00, 2, 1, 2, 2, 1, 1, 450.00, 180.00),
(12, 12, 20240920, 20240925, 20240820, 6, 2100.00, 3, 3, 4, 3, 2, 2, 700.00, 350.00),
(13, 13, 20240710, 20240715, 20240605, 6, 1000.00, 1, 1, 2, 1, 1, 1, 1000.00, 166.67),
(14, 14, 20240805, 20240813, 20240701, 9, 2700.00, 3, 2, 5, 3, 3, 3, 900.00, 300.00),
(15, 15, 20240901, 20240908, 20240805, 8, 1600.00, 2, 2, 3, 2, 2, 2, 800.00, 200.00),
(16, 16, 20240719, 20240721, 20240615, 3, 500.00, 1, 1, 1, 1, 0, 0, 500.00, 166.67),
(17, 17, 20240728, 20240804, 20240630, 8, 2400.00, 4, 3, 6, 4, 5, 4, 600.00, 300.00),
(18, 18, 20240818, 20240822, 20240718, 5, 1300.00, 2, 1, 3, 2, 2, 2, 650.00, 260.00),
(19, 19, 20240703, 20240708, 20240601, 6, 1200.00, 2, 2, 4, 2, 2, 2, 600.00, 200.00),
(20, 20, 20240905, 20240912, 20240810, 8, 2000.00, 3, 3, 5, 3, 3, 3, 666.67, 250.00);


INSERT INTO fact_activity_usage VALUES
(101, 201, 301, 401, 20240718, 120.00, 1, TRUE, TRUE),
(102, 202, 302, 402, 20240719, 75.50, 2, FALSE, TRUE),
(103, 203, 303, 403, 20240720, 60.00, 3, TRUE, FALSE),
(104, 204, 304, 404, 20240721, 95.00, 1, FALSE, FALSE),
(105, 205, 305, 405, 20240722, 110.25, 2, TRUE, TRUE),
(106, 206, 306, 406, 20240723, 80.75, 3, FALSE, TRUE),
(107, 207, 307, 407, 20240724, 150.00, 4, TRUE, FALSE),
(108, 208, 308, 408, 20240725, 200.00, 1, TRUE, TRUE),
(109, 209, 309, 409, 20240726, 135.00, 2, FALSE, FALSE),
(110, 210, 310, 410, 20240727, 90.00, 3, TRUE, TRUE),
(111, 211, 311, 411, 20240728, 115.00, 1, FALSE, TRUE),
(112, 212, 312, 412, 20240729, 125.00, 2, TRUE, FALSE),
(113, 213, 313, 413, 20240730, 170.00, 3, FALSE, FALSE),
(114, 214, 314, 414, 20240731, 180.00, 4, TRUE, TRUE),
(115, 215, 315, 415, 20240801, 95.00, 1, TRUE, TRUE),
(116, 216, 316, 416, 20240802, 105.00, 2, FALSE, TRUE),
(117, 217, 317, 417, 20240803, 60.00, 3, TRUE, FALSE),
(118, 218, 318, 418, 20240804, 200.00, 4, FALSE, FALSE),
(119, 219, 319, 419, 20240805, 145.00, 1, TRUE, TRUE),
(120, 220, 320, 420, 20240806, 75.00, 2, FALSE, TRUE);


INSERT INTO fact_expense VALUES
(1, 201, 101, 301, 20240710, 120.00, 'Museum Tour', 'Entrance ticket and guide'),
(2, 202, 102, 302, 20240711, 80.50, 'Bike Rental', 'Full-day bike rental'),
(3, 203, 103, 303, 20240712, 45.75, 'Lunch', 'Meal at local restaurant'),
(4, 204, NULL, 304, 20240713, 30.00, NULL, 'Snacks and drinks'),
(5, 205, 105, 305, 20240714, 200.00, 'Boat Ride', 'Private boat hire'),
(6, 206, 106, 306, 20240715, 15.25, 'Taxi', 'Hotel to airport'),
(7, 207, NULL, 307, 20240716, 60.00, NULL, 'Souvenir shopping'),
(8, 208, 108, 308, 20240717, 95.00, 'Cooking Class', 'Cultural cooking experience'),
(9, 209, 109, 309, 20240718, 110.00, 'Hiking Tour', 'Guided mountain hike'),
(10, 210, NULL, 310, 20240719, 22.50, NULL, 'Groceries'),
(11, 211, 111, 311, 20240720, 89.99, 'City Pass', 'Access to attractions'),
(12, 212, 112, 312, 20240721, 45.00, 'Yoga Session', 'Group class on the beach'),
(13, 213, NULL, 313, 20240722, 150.00, NULL, 'Emergency health expense'),
(14, 214, 114, 314, 20240723, 66.60, 'Train Ticket', 'Intercity transport'),
(15, 215, NULL, 315, 20240724, 19.95, NULL, 'Cafe breakfast'),
(16, 216, 116, 316, 20240725, 33.33, 'Scuba Diving', 'Introductory dive'),
(17, 217, 117, 317, 20240726, 55.55, 'Art Workshop', 'Painting experience'),
(18, 218, NULL, 318, 20240727, 99.99, NULL, 'Mobile data pack'),
(19, 219, 119, 319, 20240728, 72.72, 'Zip Line', 'Adventure park fee'),
(20, 220, NULL, 320, 20240729, 18.18, NULL, 'Laundry service');


INSERT INTO bridge_trip_destination VALUES
(201, 401),
(202, 402),
(203, 403),
(204, 404),
(205, 405),
(206, 406),
(207, 407),
(208, 408),
(209, 409),
(210, 410),
(211, 411),
(212, 412),
(213, 413),
(214, 414),
(215, 415),
(216, 416),
(217, 417),
(218, 418),
(219, 419),
(220, 420);
