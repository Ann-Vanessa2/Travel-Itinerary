CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY,
    username varchar(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    password VARCHAR(255),
    profile_image_url VARCHAR(255),
    profile_picture_key VARCHAR(255),
    role SMALLINT,
    social_id VARCHAR(255),
    social_provider VARCHAR(255),
    is_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS verification_token (
    id BIGINT PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    expiration TIMESTAMP WITH TIME ZONE,
    verification_token VARCHAR(255) NOT NULL,
    token_type VARCHAR(50),
    user_id BIGINT NOT NULL
);

-- User Permissions Table
CREATE TABLE user_permissions (
    user_id BIGINT NOT NULL,
    permissions VARCHAR(100) NOT NULL
);

-- Permissions_User Table
CREATE TABLE permissions_user (
    user_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL
);

-- Trip Table
CREATE TABLE trip (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    trip_status VARCHAR(50) NOT NULL,
    total_budget DOUBLE PRECISION,
    user_id INTEGER NOT NULL,
    number_of_travelers INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    last_modified_by INTEGER
);

-- Destination Table
CREATE TABLE destination (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(2000),
    state VARCHAR(255),
    country VARCHAR(255),
    image_url VARCHAR(1000),
    geolocation_latitude DOUBLE PRECISION,
    geolocation_longitude DOUBLE PRECISION,
    geolocation_description VARCHAR(255)
);

-- Activity Table
CREATE TABLE activity (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(2000),
    address VARCHAR(255) NOT NULL,
    image_url VARCHAR(1000),
    source_website_url VARCHAR(1000),
    destination_id INTEGER NOT NULL,
    geolocation_latitude DOUBLE PRECISION,
    geolocation_longitude DOUBLE PRECISION,
    geolocation_description VARCHAR(255),
    price_amount DOUBLE PRECISION,
    price_currency VARCHAR(10),
    price_description VARCHAR(255),
    FOREIGN KEY (destination_id) REFERENCES destination(id)
);

-- Trip Participants Table
CREATE TABLE trip_participants (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    user_email VARCHAR(255),
    role VARCHAR(50),
    is_active BOOLEAN,
    joined_at TIMESTAMP,
    UNIQUE (trip_id, user_id),
    FOREIGN KEY (trip_id) REFERENCES trip(id)
);

-- Trip Invitations Table
CREATE TABLE trip_invitations (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER NOT NULL,
    inviter_id INTEGER NOT NULL,
    invitee_email VARCHAR(255) NOT NULL,
    invitation_token VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    trip_title VARCHAR(255),
    inviter_name VARCHAR(255),
    created_at TIMESTAMP,
    expires_at TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES trip(id)
);

-- Expenses Table
CREATE TABLE expenses (
    id SERIAL PRIMARY KEY,
    amount DOUBLE PRECISION NOT NULL,
    activity_id INTEGER,
    activity_name VARCHAR(255),
    description VARCHAR(255),
    date DATE NOT NULL,
    trip_id INTEGER,
    FOREIGN KEY (activity_id) REFERENCES activity(id),
    FOREIGN KEY (trip_id) REFERENCES trip(id)
);

-- Itineraries Table
CREATE TABLE itineraries (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER NOT NULL,
    FOREIGN KEY (trip_id) REFERENCES trip(id)
);

-- Itinerary Item Table
CREATE TABLE itinerary_item (
    id SERIAL PRIMARY KEY,
    itinerary_id INTEGER NOT NULL,
    scheduled_time TIMESTAMP NOT NULL,
    activity_id INTEGER,
    destination_id INTEGER,
    notes VARCHAR(255),
    reminder_time TIMESTAMP,
    display_order INTEGER,
    FOREIGN KEY (itinerary_id) REFERENCES itineraries(id),
    FOREIGN KEY (activity_id) REFERENCES activity(id),
    FOREIGN KEY (destination_id) REFERENCES destination(id)
);

-- Category Table
CREATE TABLE category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255)
);

-- Review Table
CREATE TABLE review (
    id SERIAL PRIMARY KEY,
    activity_id INTEGER NOT NULL,
    rating INTEGER,
    comment VARCHAR(2000),
    reviewer_name VARCHAR(255),
    created_at TIMESTAMP,
    FOREIGN KEY (activity_id) REFERENCES activity(id)
);

-- Trip Destinations (Join Table)
CREATE TABLE trip_destinations (
    trip_id INTEGER NOT NULL,
    destination_id INTEGER NOT NULL,
    PRIMARY KEY (trip_id, destination_id),
    FOREIGN KEY (trip_id) REFERENCES trip(id),
    FOREIGN KEY (destination_id) REFERENCES destination(id)
);

-- Activity Category (Join Table)
CREATE TABLE activity_category (
    activity_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    PRIMARY KEY (activity_id, category_id),
    FOREIGN KEY (activity_id) REFERENCES activity(id),
    FOREIGN KEY (category_id) REFERENCES category(id)
);

-- Activity Travel Styles Table
CREATE TABLE activity_travel_styles (
    activity_id INTEGER NOT NULL,
    travel_style VARCHAR(50) NOT NULL,
    FOREIGN KEY (activity_id) REFERENCES activity(id)
);

-- Expense Paid By (Join Table)
CREATE TABLE expense_paid_by (
    expense_id INTEGER NOT NULL,
    user_id VARCHAR(255),
    FOREIGN KEY (expense_id) REFERENCES expenses(id)
);
