-- TravelBuddy Nearby Places (Supabase)
-- Run this in Supabase SQL Editor after supabase_schema.sql

create extension if not exists "pgcrypto";

create table if not exists public.places (
  id uuid primary key default gen_random_uuid(),
  district text not null,
  name text not null,
  description text not null,
  rating numeric(2,1) not null default 4.5 check (rating >= 0 and rating <= 5),
  latitude double precision not null,
  longitude double precision not null,
  image_url text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_places_district on public.places(district);
create index if not exists idx_places_coordinates on public.places(latitude, longitude);

alter table public.places enable row level security;

drop policy if exists "Public can read places" on public.places;
create policy "Public can read places"
on public.places
for select
using (true);

-- Optional: if you want to upload place photos and use public URLs in image_url
insert into storage.buckets (id, name, public)
values ('place-images', 'place-images', true)
on conflict (id) do nothing;

drop policy if exists "Public can read place images" on storage.objects;
create policy "Public can read place images"
on storage.objects
for select
using (bucket_id = 'place-images');

drop policy if exists "Authenticated can upload place images" on storage.objects;
create policy "Authenticated can upload place images"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'place-images');

truncate table public.places;

insert into public.places (district, name, description, rating, latitude, longitude, image_url)
values
-- Colombo
('Colombo','Galle Face Green','A popular oceanfront urban park ideal for evening walks, street food, and sunset views along the Indian Ocean.',4.8,6.9271,79.8612,null),
('Colombo','Gangaramaya Temple','A famous Buddhist temple combining modern architecture and cultural artifacts, located in the heart of the city.',4.7,6.9571,79.8912,null),
('Colombo','Independence Memorial Hall','A historic monument built to commemorate Sri Lanka''s independence, surrounded by peaceful gardens.',4.6,6.9071,79.9012,null),
('Colombo','Viharamahadevi Park','The largest park in Colombo featuring green landscapes, walking paths, and a large Buddha statue.',4.7,6.9671,79.8312,null),

-- Gampaha
('Gampaha','Negombo Beach','A sandy coastal area known for fishing culture, seafood, and vibrant beachside activities.',4.7,7.0873,79.9994,null),
('Gampaha','Muthurajawela Marsh','A unique wetland ecosystem rich in biodiversity, offering boat tours through mangroves.',4.6,7.1173,80.0294,null),
('Gampaha','Kelaniya Raja Maha Vihara','An ancient Buddhist temple with historical significance and beautiful wall paintings.',4.7,7.0673,80.0394,null),
('Gampaha','Dutch Canal','A colonial-era canal system used for transport, now a scenic attraction for boat rides.',4.5,7.1273,79.9694,null),

-- Kalutara
('Kalutara','Kalutara Bodhiya','A sacred Buddhist site featuring a hollow stupa and religious significance for pilgrims.',4.7,6.5854,79.9607,null),
('Kalutara','Richmond Castle','A historic mansion with colonial architecture and landscaped gardens.',4.6,6.6154,79.9907,null),
('Kalutara','Beruwala Beach','A calm and attractive beach popular for relaxation and water sports.',4.6,6.5654,80.0007,null),
('Kalutara','Brief Garden','A landscaped garden designed with artistic elements and tropical flora.',4.5,6.6254,79.9307,null),

-- Galle
('Galle','Galle Fort','A UNESCO World Heritage Site with colonial buildings, cobblestone streets, and ocean views.',4.9,6.0535,80.2210,null),
('Galle','Unawatuna Beach','A popular tourist beach known for golden sand and clear blue water.',4.8,6.0835,80.2510,null),
('Galle','Jungle Beach','A secluded beach surrounded by forest, offering a peaceful environment.',4.7,6.0335,80.2610,null),
('Galle','Hikkaduwa Beach','A lively beach destination famous for coral reefs and nightlife.',4.7,6.0935,80.1910,null),

-- Matara
('Matara','Polhena Beach','A calm beach protected by coral reefs, ideal for swimming and snorkeling.',4.8,5.9549,80.5549,null),
('Matara','Dondra Head Lighthouse','The tallest lighthouse in Sri Lanka with panoramic ocean views.',4.7,5.9849,80.5849,null),
('Matara','Weherahena Temple','A unique temple known for its underground tunnel and large Buddha statue.',4.6,5.9349,80.5949,null),
('Matara','Mirissa Beach','A famous beach destination for whale watching and vibrant coastal life.',4.8,5.9949,80.5249,null),

-- Hambantota
('Hambantota','Yala National Park','A wildlife sanctuary famous for leopards, elephants, and diverse ecosystems.',4.9,6.1241,81.1185,null),
('Hambantota','Bundala National Park','A bird sanctuary with lagoons attracting migratory birds.',4.7,6.1541,81.1485,null),
('Hambantota','Tangalle Beach','A quiet and scenic beach with natural beauty and fewer crowds.',4.7,6.1041,81.1585,null),
('Hambantota','Ridiyagama Safari Park','A safari park where animals roam freely in large enclosures.',4.6,6.1641,81.0885,null),

-- Kandy
('Kandy','Temple of the Sacred Tooth Relic','A sacred Buddhist temple housing a relic of Lord Buddha.',4.9,7.2906,80.6337,null),
('Kandy','Royal Botanical Gardens Peradeniya','A large garden with diverse plant species and scenic landscapes.',4.8,7.3206,80.6637,null),
('Kandy','Knuckles Mountain Range','A mountain range known for hiking trails and biodiversity.',4.7,7.2706,80.6737,null),
('Kandy','Victoria Dam','A major dam surrounded by hills and scenic viewpoints.',4.6,7.3306,80.6037,null),

-- Matale
('Matale','Sigiriya Rock Fortress','An ancient rock fortress with frescoes, gardens, and panoramic views.',4.9,7.4675,80.6234,null),
('Matale','Dambulla Cave Temple','A historic cave complex filled with Buddha statues and paintings.',4.8,7.4975,80.6534,null),
('Matale','Riverston','A mountainous area with cool climate, waterfalls, and hiking spots.',4.7,7.4475,80.6634,null),
('Matale','Nalanda Gedige','An ancient stone temple blending Hindu and Buddhist architecture.',4.6,7.5075,80.5934,null),

-- Nuwara Eliya
('Nuwara Eliya','Gregory Lake','A scenic lake offering boating and leisure activities.',4.8,6.9497,80.7891,null),
('Nuwara Eliya','Horton Plains National Park','A protected area known for grasslands, wildlife, and trekking trails.',4.8,6.9797,80.8191,null),
('Nuwara Eliya','World''s End','A dramatic cliff with a steep drop offering breathtaking views.',4.9,6.9297,80.8291,null),
('Nuwara Eliya','Pedro Tea Estate','A tea plantation where visitors can learn about tea production.',4.6,6.9897,80.7591,null),

-- Batticaloa
('Batticaloa','Batticaloa Lagoon','A large lagoon known for its scenic beauty and fishing activities.',4.6,7.7102,81.6924,null),
('Batticaloa','Pasikuda Beach','A shallow beach ideal for safe swimming and relaxation.',4.8,7.7402,81.7224,null),
('Batticaloa','Batticaloa Fort','A historic fort built during colonial times.',4.5,7.6902,81.7324,null),
('Batticaloa','Kallady Bridge','A famous bridge associated with the singing fish legend.',4.5,7.7502,81.6624,null),

-- Ampara
('Ampara','Arugam Bay','A world-famous surfing destination with laid-back beach vibes.',4.9,7.2975,81.6820,null),
('Ampara','Kumana National Park','A bird sanctuary with diverse wildlife and wetlands.',4.7,7.3275,81.7120,null),
('Ampara','Muhudu Maha Viharaya','An ancient temple located near the coast.',4.6,7.2775,81.7220,null),
('Ampara','Magul Maha Viharaya','A historic Buddhist temple with archaeological value.',4.6,7.3375,81.6520,null),

-- Badulla
('Badulla','Ella Rock','A hiking destination offering panoramic views of valleys.',4.8,6.9934,81.0550,null),
('Badulla','Nine Arches Bridge','An iconic railway bridge surrounded by lush greenery.',4.9,7.0234,81.0850,null),
('Badulla','Dunhinda Falls','A beautiful waterfall known for its misty surroundings.',4.7,6.9734,81.0950,null),
('Badulla','Lipton''s Seat','A viewpoint where tea plantations can be seen in all directions.',4.8,7.0334,81.0250,null),

-- Anuradhapura
('Anuradhapura','Sri Maha Bodhi','A sacred fig tree believed to be grown from the original Bodhi tree.',4.9,8.3114,80.4037,null),
('Anuradhapura','Ruwanwelisaya','A large stupa and important pilgrimage site.',4.8,8.3414,80.4337,null),
('Anuradhapura','Jetavanaramaya','One of the tallest ancient stupas in the world.',4.8,8.2914,80.4437,null),
('Anuradhapura','Mihintale','A historic site marking the introduction of Buddhism to Sri Lanka.',4.7,8.3514,80.3737,null),

-- Polonnaruwa
('Polonnaruwa','Gal Vihara','A group of Buddha statues carved into rock.',4.8,7.9396,81.0000,null),
('Polonnaruwa','Parakrama Samudraya','A large man-made reservoir.',4.7,7.9696,81.0300,null),
('Polonnaruwa','Polonnaruwa Vatadage','A circular relic house with intricate stone carvings.',4.7,7.9196,81.0400,null),
('Polonnaruwa','Lankatilaka Image House','A tall structure housing a large Buddha statue.',4.6,7.9796,80.9700,null),

-- Kurunegala
('Kurunegala','Ridi Viharaya','A temple built in a silver mine area.',4.6,7.4863,80.3647,null),
('Kurunegala','Athugala Rock','A large rock with a Buddha statue overlooking the city.',4.7,7.5163,80.3947,null),
('Kurunegala','Yapahuwa Rock Fortress','An ancient fortress with stone stairways.',4.7,7.4663,80.4047,null),
('Kurunegala','Panduwasnuwara','An archaeological site with ancient ruins.',4.5,7.5263,80.3347,null),

-- Puttalam
('Puttalam','Wilpattu National Park','The largest national park known for natural lakes and wildlife.',4.8,8.0362,79.8283,null),
('Puttalam','Kalpitiya Lagoon','A coastal lagoon ideal for kite surfing and dolphin watching.',4.7,8.0662,79.8583,null),
('Puttalam','Dutch Fort Kalpitiya','A historic fort from the colonial period.',4.5,8.0162,79.8683,null),
('Puttalam','St. Anne''s Shrine Talawila','A famous Catholic pilgrimage site.',4.6,8.0762,79.7983,null),

-- Jaffna
('Jaffna','Jaffna Fort','A historic fort built by the Portuguese.',4.7,9.6615,80.0255,null),
('Jaffna','Nallur Kandaswamy Temple','A major Hindu temple with vibrant festivals.',4.8,9.6915,80.0555,null),
('Jaffna','Casuarina Beach','A shallow beach with clear water.',4.6,9.6415,80.0655,null),
('Jaffna','Delft Island','An island known for wild ponies and unique landscapes.',4.7,9.7015,79.9955,null),

-- Kilinochchi
('Kilinochchi','Iranamadu Tank','A large reservoir supporting agriculture.',4.5,9.3803,80.3760,null),
('Kilinochchi','Kilinochchi War Memorial','A site commemorating war history.',4.4,9.4103,80.4060,null),
('Kilinochchi','Elephant Pass','A strategic location connecting north and south.',4.6,9.3603,80.4160,null),
('Kilinochchi','Akkarayankulam','A rural area with agricultural significance.',4.3,9.4203,80.3460,null),

-- Mannar
('Mannar','Mannar Island','An island known for birdlife and coastal scenery.',4.6,8.9770,79.9040,null),
('Mannar','Baobab Tree Mannar','A unique tree species believed to be centuries old.',4.5,9.0070,79.9340,null),
('Mannar','Adam''s Bridge','A chain of limestone shoals linking Sri Lanka and India.',4.7,8.9570,79.9440,null),
('Mannar','Thiruketheeswaram Temple','An ancient Hindu temple.',4.6,9.0170,79.8740,null),

-- Vavuniya
('Vavuniya','Madukanda Temple','A historical Buddhist temple.',4.5,8.7514,80.4971,null),
('Vavuniya','Vavuniya Tank','A reservoir used for irrigation.',4.4,8.7814,80.5271,null),
('Vavuniya','Archeological Sites Vavuniya','Areas with ancient ruins and artifacts.',4.3,8.7314,80.5371,null),
('Vavuniya','Wilpattu Entrance Vavuniya','One of the access points to Wilpattu National Park.',4.4,8.7914,80.4671,null),

-- Ratnapura
('Ratnapura','Sinharaja Forest Reserve','A rainforest and UNESCO site rich in biodiversity.',4.9,6.6828,80.3992,null),
('Ratnapura','Adam''s Peak','A sacred mountain climbed by pilgrims.',4.9,6.7128,80.4292,null),
('Ratnapura','Bopath Ella','A waterfall shaped like a leaf.',4.7,6.6628,80.4392,null),
('Ratnapura','Udawalawe National Park','A wildlife park known for elephants.',4.8,6.7228,80.3692,null),

-- Kegalle
('Kegalle','Pinnawala Elephant Orphanage','A sanctuary for orphaned elephants.',4.8,7.2513,80.3464,null),
('Kegalle','Belilena Cave','A prehistoric cave with archaeological findings.',4.6,7.2813,80.3764,null),
('Kegalle','Kitulgala','A location known for white-water rafting.',4.7,7.2313,80.3864,null),
('Kegalle','Alagalla Mountain','A hiking destination with scenic views.',4.6,7.2913,80.3164,null),

-- Trincomalee
('Trincomalee','Nilaveli Beach','A clean and calm beach with white sand.',4.8,8.5874,81.2152,null),
('Trincomalee','Pigeon Island National Park','A marine park with coral reefs.',4.8,8.6174,81.2452,null),
('Trincomalee','Koneswaram Temple','A historic temple on a cliff.',4.7,8.5674,81.2552,null),
('Trincomalee','Marble Beach','A quiet beach with clear waters.',4.7,8.6274,81.1852,null),

-- Monaragala
('Monaragala','Madulsima','A scenic area with mountains and tea estates.',4.7,6.8728,81.3507,null),
('Monaragala','Diyaluma Falls','The second-highest waterfall in Sri Lanka.',4.9,6.9028,81.3807,null),
('Monaragala','Yala Block 5','A less crowded section of Yala National Park.',4.6,6.8528,81.3907,null),
('Monaragala','Buduruwagala Temple','A rock carving site with large Buddha statues.',4.6,6.9128,81.3207,null),

-- Mullaitivu
('Mullaitivu','Mullaitivu Beach','A quiet beach with natural beauty.',4.6,9.2677,80.8141,null),
('Mullaitivu','Nanthi Kadal Lagoon','A lagoon with historical significance.',4.4,9.2977,80.8441,null),
('Mullaitivu','Kokkilai Lagoon','A lagoon rich in birdlife.',4.5,9.2477,80.8541,null),
('Mullaitivu','Mullaitivu War Memorial','A site marking war history.',4.3,9.3077,80.7841,null);

-- ---------------------------------------------------------------------------
-- AFTER YOU UPLOAD IMAGES TO STORAGE BUCKET: place-images
-- ---------------------------------------------------------------------------
-- Recommended naming format for image files:
--   <place-name-slug>.jpg
-- Example:
--   galle-face-green.jpg, gangaramaya-temple.jpg, nine-arches-bridge.jpg
--
-- This update auto-builds image_url from place name.
-- If your file extension is .png, change '.jpg' to '.png' below.

update public.places
set image_url =
  'https://vnqqgxyakcbkeoualauc.supabase.co/storage/v1/object/public/place-images/'
  || lower(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'))
  || '.jpg';

-- Check the first few generated URLs
select name, image_url
from public.places
order by district, name
limit 25;

-- If some place names don't match your uploaded file names, fix manually:
-- update public.places
-- set image_url = 'https://vnqqgxyakcbkeoualauc.supabase.co/storage/v1/object/public/place-images/<exact-file-name>.jpg'
-- where name = '<Exact Place Name>';

-- Optional: find rows still missing image URLs
select id, district, name
from public.places
where image_url is null or image_url = ''
order by district, name;
