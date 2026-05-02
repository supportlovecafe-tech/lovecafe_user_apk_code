-- -----------------------------------------------------------------------------
-- CINEMA EATS - PREMIUM UI SEED DATA
-- Run this in your Supabase SQL Editor to instantly make your app look stunning!
-- -----------------------------------------------------------------------------

-- 1. DELETE EXISTING DATA (Optional: comment this out if you want to keep existing data)
-- WARNING: This will clear existing menu items and cinemas.
DELETE FROM public.food_items;
DELETE FROM public.screens;
DELETE FROM public.cinemas;

-- 2. SEED PREMIUM CINEMAS & MENU
DO $$
DECLARE
    cinema_id_1 uuid;
    cinema_id_2 uuid;
BEGIN
    -- 🎬 Premium Cinema 1
    INSERT INTO public.cinemas (name, location, rating, feature, image_url)
    VALUES (
        'CineSeat Luxe Edition', 
        'Downtown High Street', 
        '4.9', 
        'Luxury Dining & IMAX', 
        'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=1000&q=80'
    ) RETURNING id INTO cinema_id_1;

    -- 🎬 Premium Cinema 2
    INSERT INTO public.cinemas (name, location, rating, feature, image_url)
    VALUES (
        'Director''s Cut Gold', 
        'Marina Bay Mall', 
        '4.8', 
        'Recliners & Gourmet', 
        'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1000&q=80'
    ) RETURNING id INTO cinema_id_2;

    -- 📺 Screens for Cinema 1
    INSERT INTO public.screens (cinema_id, name, floor, tag) VALUES (cinema_id_1, 'Screen 1 (IMAX)', 'Level 3', 'IMAX');
    INSERT INTO public.screens (cinema_id, name, floor, tag) VALUES (cinema_id_1, 'Screen 2 (VIP)', 'Level 3', 'VIP LUXE');
    INSERT INTO public.screens (cinema_id, name, floor, tag) VALUES (cinema_id_1, 'Screen 3 (4DX)', 'Level 4', '4DX');

    -- 📺 Screens for Cinema 2
    INSERT INTO public.screens (cinema_id, name, floor, tag) VALUES (cinema_id_2, 'Screen 1 (Gold)', 'Level 1', 'GOLD CLASS');
    INSERT INTO public.screens (cinema_id, name, floor, tag) VALUES (cinema_id_2, 'Screen 2 (Dolby)', 'Level 1', 'ATMOS');

    -- 🍔 PREMIUM MENU ITEMS (Cinema 1)
    INSERT INTO public.food_items (cinema_id, name, description, price, category, image_url) VALUES 
    (cinema_id_1, 'Truffle Gold Popcorn', 'Freshly popped corn tossed in rich black truffle oil and parmesan dust.', 450, 'Popcorn', 'https://images.unsplash.com/photo-1578849278619-e734e0eb2853?w=800&q=80'),
    (cinema_id_1, 'Caramel Crunch Popcorn', 'Sweet and salty artisan caramel glazed popcorn.', 380, 'Popcorn', 'https://images.unsplash.com/photo-1505656149129-106518cbac63?w=800&q=80'),
    (cinema_id_1, 'Wagyu Beef Sliders', 'Twin slider buns with premium wagyu beef patties, melted gruyere, and secret sauce.', 950, 'Meals', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80'),
    (cinema_id_1, 'Margherita Artisan Pizza', 'Wood-fired sourdough base with san marzano tomatoes and fresh mozzarella.', 650, 'Meals', 'https://images.unsplash.com/photo-1604068549290-dea0e4a305ca?w=800&q=80'),
    (cinema_id_1, 'Loaded Nachos Grande', 'Crispy tortilla chips smothered in melted cheddar, jalapeños, and fresh guacamole.', 420, 'Snacks', 'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=800&q=80'),
    (cinema_id_1, 'Crispy Calamari Rings', 'Golden fried calamari served with a zesty garlic aioli dip.', 580, 'Snacks', 'https://images.unsplash.com/photo-1626074961596-cab914d9392e?w=800&q=80'),
    (cinema_id_1, 'Iced Hazelnut Latte', 'Premium espresso blended with milk, ice, and roasted hazelnut syrup.', 320, 'Beverages', 'https://images.unsplash.com/photo-1461023058943-0708e5f23a54?w=800&q=80'),
    (cinema_id_1, 'Berry Blast Smoothie', 'A refreshing blend of wild berries, yogurt, and a touch of honey.', 350, 'Beverages', 'https://images.unsplash.com/photo-1553530666-ba11a90a2bf9?w=800&q=80');

    -- 🍔 PREMIUM MENU ITEMS (Cinema 2)
    INSERT INTO public.food_items (cinema_id, name, description, price, category, image_url) VALUES 
    (cinema_id_2, 'Classic Salted Popcorn', 'The timeless cinema classic, perfectly salted.', 300, 'Popcorn', 'https://images.unsplash.com/photo-1585647347384-2593bc35786b?w=800&q=80'),
    (cinema_id_2, 'Cheese Burst Popcorn', 'Rich, gooey cheddar cheese tossed popcorn.', 380, 'Popcorn', 'https://images.unsplash.com/photo-1572177990156-f00e57f00bf5?w=800&q=80'),
    (cinema_id_2, 'Gourmet Hot Dog', 'Smoked chicken frank in a brioche bun with caramelized onions.', 450, 'Meals', 'https://images.unsplash.com/photo-1619740455993-9e612b1af08a?w=800&q=80'),
    (cinema_id_2, 'Spicy Chicken Wings', 'Crispy wings tossed in fiery buffalo sauce with blue cheese dip.', 550, 'Snacks', 'https://images.unsplash.com/photo-1569691899455-88464f6d3ab1?w=800&q=80'),
    (cinema_id_2, 'Fresh Lime Soda', 'Refreshing chilled soda with squeezed lime and mint.', 180, 'Beverages', 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=800&q=80');

END;
$$;
