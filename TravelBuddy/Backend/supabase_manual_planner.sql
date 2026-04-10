-- TravelBuddy Manual Planner Categories + Places
-- Run in Supabase SQL Editor

create extension if not exists "pgcrypto";

create table if not exists public.manual_planner_places (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  name text not null,
  district text not null,
  latitude double precision not null,
  longitude double precision not null,
  rating numeric(2,1) not null check (rating >= 0 and rating <= 5),
  image_url text,
  description text not null,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_manual_planner_category on public.manual_planner_places(category);
create index if not exists idx_manual_planner_district on public.manual_planner_places(district);

alter table public.manual_planner_places enable row level security;

drop policy if exists "Public can read manual planner places" on public.manual_planner_places;
create policy "Public can read manual planner places"
on public.manual_planner_places
for select
using (true);

truncate table public.manual_planner_places;

insert into public.manual_planner_places (category, name, district, latitude, longitude, rating, image_url, description)
values
-- MUST VISIT
('must_visit','Sigiriya Rock Fortress','Matale',7.9570,80.7603,4.9,'https://example.com/sigiriya.jpg','Sigiriya is an ancient rock fortress rising dramatically above the plains. It features frescoes, gardens, and royal ruins. It is one of Sri Lanka''s most iconic UNESCO heritage sites.'),
('must_visit','Temple of the Tooth Relic','Kandy',7.2936,80.6413,4.8,'https://example.com/kandy.jpg','This sacred temple holds a relic of the Buddha''s tooth. It is a major pilgrimage site for Buddhists. The surrounding architecture and lake create a peaceful atmosphere.'),
('must_visit','Galle Fort','Galle',6.0260,80.2170,4.7,'https://example.com/galle.jpg','A colonial fort built by Portuguese and Dutch settlers. It features cobbled streets and historic buildings. It blends European architecture with local culture.'),
('must_visit','Ella','Badulla',6.8667,81.0466,4.8,'https://example.com/ella.jpg','Ella is a scenic mountain village surrounded by greenery. It is famous for Nine Arches Bridge and viewpoints. The calm vibe attracts travelers worldwide.'),
('must_visit','Yala National Park','Hambantota',6.3725,81.5185,4.7,'https://example.com/yala.jpg','Yala is famous for leopards and diverse wildlife. Safaris offer thrilling nature experiences. It is one of the best wildlife parks in Sri Lanka.'),
('must_visit','Nuwara Eliya','Nuwara Eliya',6.9497,80.7891,4.6,'https://example.com/nuwara.jpg','Known as Little England due to its climate and buildings. It has tea plantations and cool weather. A perfect escape from tropical heat.'),

-- HIKING
('hiking','Adam''s Peak','Ratnapura',6.8096,80.4994,4.9,'https://example.com/adamspeak.jpg','A sacred mountain climbed by thousands of pilgrims. The sunrise from the summit is breathtaking. The trail combines spirituality and adventure.'),
('hiking','Ella Rock','Badulla',6.8665,81.0460,4.7,'https://example.com/ellarock.jpg','A scenic hike through tea plantations and forests. The summit gives panoramic valley views. It is popular among tourists and locals.'),
('hiking','Knuckles Range','Matale',7.4445,80.8200,4.8,'https://example.com/knuckles.jpg','A biodiversity hotspot with challenging trails. It offers misty mountains and waterfalls. Ideal for serious hikers.'),
('hiking','Horton Plains','Nuwara Eliya',6.8000,80.8000,4.7,'https://example.com/horton.jpg','A plateau with grasslands and forests. World''s End offers a dramatic cliff view. Perfect for early morning hikes.'),
('hiking','Lakegala','Kandy',7.4010,80.8800,4.6,'https://example.com/lakegala.jpg','A steep and adventurous hike. It offers breathtaking views of Knuckles. Best for experienced trekkers.'),
('hiking','Little Adam''s Peak','Badulla',6.8720,81.0480,4.6,'https://example.com/littleadams.jpg','A beginner-friendly hiking trail. Surrounded by tea plantations. The summit view is stunning and relaxing.'),

-- CAMPING
('camping','Meemure','Kandy',7.4330,80.8330,4.9,'https://example.com/meemure.jpg','A remote village with untouched nature. Perfect for camping and trekking. It offers rivers, forests, and waterfalls.'),
('camping','Riverston','Matale',7.5250,80.7500,4.6,'https://example.com/riverston.jpg','A cool and misty mountain area. Great for camping with scenic views. Known for mini World''s End.'),
('camping','Belihuloya','Ratnapura',6.7167,80.7833,4.5,'https://example.com/belihuloya.jpg','A peaceful location with rivers and waterfalls. Ideal for nature camping. It has a relaxing environment.'),
('camping','Sinharaja Forest','Ratnapura',6.4000,80.5000,4.8,'https://example.com/sinharaja.jpg','A UNESCO rainforest reserve. Rich in biodiversity and wildlife. Camping offers a deep jungle experience.'),
('camping','Knuckles Camping','Matale',7.4440,80.8200,4.8,'https://example.com/knucklescamp.jpg','A natural camping experience in mountains. Cool climate and scenic beauty. Great for group adventures.'),
('camping','Yala Camping','Hambantota',6.3700,81.5200,4.7,'https://example.com/yalacamp.jpg','Safari-style camping in the wild. Close encounters with wildlife. A thrilling overnight experience.'),

-- RAFTING
('rafting','Kitulgala','Kegalle',6.9900,80.4170,4.9,'https://example.com/kitulgala.jpg','The best rafting destination in Sri Lanka. Rapids provide thrilling water adventure. Suitable for beginners and pros.'),
('rafting','Kelani River','Kegalle',6.9950,80.4200,4.8,'https://example.com/kelani.jpg','A popular river for white-water rafting. It has multiple rapid levels. Surrounded by lush greenery.'),
('rafting','Sitawaka River','Colombo',6.9500,80.1000,4.5,'https://example.com/sitawaka.jpg','A lesser-known rafting spot. Offers a calm but fun experience. Ideal for beginners.'),
('rafting','Mahaweli River','Kandy',7.2900,80.6300,4.6,'https://example.com/mahaweli.jpg','The longest river in Sri Lanka. Offers gentle rafting experiences. Scenic surroundings enhance the journey.'),
('rafting','Kalu River','Ratnapura',6.6800,80.4000,4.5,'https://example.com/kalu.jpg','Known for smooth rafting routes. Surrounded by rainforest landscapes. A relaxing water activity.'),
('rafting','Gin River','Galle',6.1000,80.3000,4.4,'https://example.com/gin.jpg','A calm river ideal for beginners. Offers scenic views and wildlife. Great for a relaxed rafting trip.'),

-- TRAIL TRACKING
('trail_tracking','Sinharaja Trail','Ratnapura',6.4000,80.5000,4.8,'https://example.com/sinharajatrail.jpg','A dense rainforest trekking experience. Rich in biodiversity and rare species. Ideal for eco-tourism lovers.'),
('trail_tracking','Knuckles Trail','Matale',7.4440,80.8200,4.8,'https://example.com/knucklestrek.jpg','A challenging trekking destination. Includes forests, rivers, and mountains. Perfect for adventure seekers.'),
('trail_tracking','Ella Forest Trail','Badulla',6.8700,81.0500,4.6,'https://example.com/ellatrail.jpg','A peaceful forest trail near Ella. Offers scenic beauty and wildlife. Easy to moderate difficulty.'),
('trail_tracking','Horton Plains Trail','Nuwara Eliya',6.8000,80.8000,4.7,'https://example.com/hortontrail.jpg','A loop trail through plains and forests. Includes World''s End viewpoint. A popular trekking spot.'),
('trail_tracking','Riverston Trail','Matale',7.5250,80.7500,4.6,'https://example.com/riverstontrail.jpg','A misty trail with stunning views. Cool climate makes it enjoyable. Ideal for short treks.'),
('trail_tracking','Belihuloya Trail','Ratnapura',6.7167,80.7833,4.5,'https://example.com/belihuloyatrail.jpg','A scenic trekking area with rivers. Offers peaceful nature walks. Great for beginners.'),

-- FOOD
('food','Colombo Street Food','Colombo',6.9271,79.8612,4.7,'https://example.com/colombofood.jpg','Offers a variety of local street foods. Includes kottu, hoppers, and seafood. A must-try for food lovers.'),
('food','Negombo Seafood','Gampaha',7.2083,79.8358,4.6,'https://example.com/negombofood.jpg','Famous for fresh seafood dishes. Coastal flavors dominate the cuisine. Perfect for seafood lovers.'),
('food','Kandy Traditional Food','Kandy',7.2906,80.6337,4.5,'https://example.com/kandyfood.jpg','Known for authentic Sri Lankan rice and curry. Includes traditional sweets. Offers cultural dining experience.'),
('food','Jaffna Cuisine','Jaffna',9.6615,80.0255,4.8,'https://example.com/jaffnafood.jpg','Spicy and unique Tamil cuisine. Includes crab curry and dosai. Rich in flavor and tradition.'),
('food','Galle Cafes','Galle',6.0260,80.2170,4.6,'https://example.com/gallefood.jpg','Mix of local and international dishes. Located inside historic fort. Offers a cozy dining experience.'),
('food','Ella Chill Cafes','Badulla',6.8667,81.0466,4.7,'https://example.com/ellafood.jpg','Relaxed cafes with scenic views. Popular among tourists. Great for casual dining.'),

-- CULTURE
('culture','Kandy Esala Perahera','Kandy',7.2936,80.6413,4.9,'https://example.com/perahera.jpg','A grand cultural festival with elephants and dancers. Celebrates the sacred tooth relic. One of Asia''s biggest festivals.'),
('culture','Kataragama Temple','Monaragala',6.4130,81.3320,4.7,'https://example.com/kataragama.jpg','A multi-religious sacred site. Attracts pilgrims from all communities. Rich spiritual significance.'),
('culture','Dambulla Cave Temple','Matale',7.8567,80.6490,4.8,'https://example.com/dambulla.jpg','A temple complex inside caves. Contains ancient Buddha statues and paintings. A UNESCO heritage site.'),
('culture','Jaffna Cultural Center','Jaffna',9.6615,80.0255,4.6,'https://example.com/jaffnaculture.jpg','Promotes Tamil culture and arts. Hosts events and exhibitions. A modern cultural landmark.'),
('culture','Galle Cultural Shows','Galle',6.0260,80.2170,4.5,'https://example.com/galleculture.jpg','Traditional dance and music performances. Showcases Sri Lankan heritage. Popular among tourists.'),
('culture','Colombo Museum','Colombo',6.9271,79.8612,4.6,'https://example.com/museum.jpg','Displays Sri Lankan history and artifacts. Located in a colonial building. Offers educational insights.'),

-- HISTORY
('history','Anuradhapura','Anuradhapura',8.3114,80.4037,4.9,'https://example.com/anuradhapura.jpg','Ancient capital with ruins and stupas. Rich in Buddhist heritage. A UNESCO site.'),
('history','Polonnaruwa','Polonnaruwa',7.9403,81.0188,4.8,'https://example.com/polonnaruwa.jpg','Medieval capital with preserved ruins. Includes statues and temples. A historical treasure.'),
('history','Yapahuwa','Kurunegala',7.8200,80.3000,4.6,'https://example.com/yapahuwa.jpg','Ancient rock fortress. Features stone stairways and ruins. Offers historical insight.'),
('history','Mihintale','Anuradhapura',8.3500,80.5000,4.7,'https://example.com/mihintale.jpg','Birthplace of Buddhism in Sri Lanka. Sacred mountain site. Offers scenic views.'),
('history','Ritigala','Anuradhapura',8.2000,80.6500,4.6,'https://example.com/ritigala.jpg','Ancient monastery ruins in jungle. Surrounded by mystery and nature. A unique historical site.'),
('history','Fort Frederick','Trincomalee',8.5700,81.2330,4.5,'https://example.com/frederick.jpg','A colonial fort with ocean views. Built by Portuguese. Rich in history.'),

-- BUNGEE / ADVENTURE
('bungee','Kitulgala Bungee','Kegalle',6.9900,80.4170,4.8,'https://example.com/bungee1.jpg','Sri Lanka''s top bungee jumping spot. Jump over scenic river views. A thrilling experience.'),
('bungee','Ella Flying Ravana Zipline','Badulla',6.8700,81.0500,4.7,'https://example.com/zipline.jpg','One of Asia''s longest ziplines. Offers high-speed adventure. Amazing mountain views.'),
('bungee','Colombo Adventure Park','Colombo',6.9000,79.9000,4.5,'https://example.com/adventure.jpg','Includes climbing and rope courses. Suitable for all ages. A fun urban adventure.'),
('bungee','Nuwara Eliya Adventure Park','Nuwara Eliya',6.9497,80.7891,4.6,'https://example.com/adventure2.jpg','Offers outdoor adventure activities. Surrounded by cool climate. Great for families.'),
('bungee','Belihuloya Adventure Camp','Ratnapura',6.7167,80.7833,4.5,'https://example.com/adventure3.jpg','Includes climbing, rafting, and trekking. Nature-based adventure spot. Ideal for groups.'),
('bungee','Riverston Adventure','Matale',7.5250,80.7500,4.6,'https://example.com/adventure4.jpg','Offers hiking and outdoor challenges. Scenic mountain environment. A hidden adventure hub.'),

-- HIDDEN GEMS
('hidden_gems','Nilaveli Beach','Trincomalee',8.7000,81.2000,4.7,'https://example.com/nilaveli.jpg','A quiet and clean beach. Crystal-clear water and soft sand. Less crowded than other beaches.'),
('hidden_gems','Madulsima','Badulla',6.9000,81.1000,4.8,'https://example.com/madulsima.jpg','Famous for Pekoe Trail views. Offers stunning sunrise scenery. A peaceful escape.'),
('hidden_gems','Kalpitiya','Puttalam',8.2000,79.7000,4.6,'https://example.com/kalpitiya.jpg','Known for dolphin watching. A hidden coastal paradise. Ideal for water sports.'),
('hidden_gems','Jaffna Islands','Jaffna',9.7000,80.0000,4.7,'https://example.com/islands.jpg','Remote islands with unique culture. Beautiful beaches and temples. Less explored by tourists.'),
('hidden_gems','Diyaluma Falls','Badulla',6.7300,81.0200,4.9,'https://example.com/diyaluma.jpg','Second highest waterfall in Sri Lanka. Natural infinity pools at the top. A hidden natural wonder.'),
('hidden_gems','Meemure Village','Kandy',7.4330,80.8330,4.9,'https://example.com/meemure2.jpg','Remote village with untouched beauty. Offers authentic rural experience. Perfect hidden getaway.');

-- Validate rows
select category, count(*) as place_count
from public.manual_planner_places
group by category
order by category;
