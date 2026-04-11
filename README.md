# ⏳ Tempra

Tempra turns paper time-tracking into a simple digital grid, giving you the real-time stats you need to stop wasting precious hours. The project was inspired by an experiment shared in this [POV article](https://bookbase.substack.com/p/pov-11-konyv-7-kozos-pont?utm_source=substack&publication_id=1116676&post_id=188358380&utm_medium=email&utm_content=share&utm_campaign=email-share&action=share&isFreemail=true&r=2y2ee7&triedRedirect=true), which used a manual paper-based system to track time and optimize focus.

## 💡 The Why
The methodology in the article is a great way to see the "truth" of your day, but paper gets hard to analyze over time. I built Tempra to solve three specific problems:

- Frictionless Entry: Instead of a notebook, you use a digital grid. It takes seconds to "paint" your day with your finger using a gesture-based 24x4 layout.
- Exposing "Time Leaks": The article highlights how easily time is lost to doomscrolling or being unproductive. Tempra turns those leaks into visual statistics so you can see the cost of your distractions.
- Contextual Benchmarking: Paper can’t tell you how you compare to the world. Tempra is designed to show if you are in the "Top 0.5% of Focus" for the day, turning personal growth into a measurable achievement.

## 🛠 Tech Stack
- Frontend: Flutter (Mobile app)
- Backend: Express.js (Node server)
- Live Data: Supabase (Auth + daily logs)
- Big Data: Google BigQuery (Statistics & Analytics)
- Pipeline: Python (Moves data from Supabase to BigQuery)

## 🧠 Data Strategy: Why BigQuery?
A major part of this project was choosing the right tool for the right job. I split the data into two parts: OLTP and OLAP.

### OLTP (Supabase / PostgreSQL)
Why: When you log in or save a 15-minute block, the app needs to find your record and update it instantly. PostgreSQL uses Indexing for this, which is great for fast, single-row lookups. However it underperforms at multi-row lookups.

### OLAP (BigQuery)
Why: To give you a "Spotify Wrapped" stats view, the app has to scan (hopefully more than) thousands of rows to calculate averages and percentages. Doing this in Supabase would slow the app down as it scales. BigQuery is built for these massive multi-row "scans." by enabling clustering and partitioning.

### 📈 Partitioning & Clustering
To keep the app fast and the costs low, I used:

- Partitioning (by Date): I put data into "buckets" based on the day. When the app asks for "this week's stats," BigQuery only looks at those 7 buckets instead of scanning the whole database.

- Clustering (by User ID): Inside those date buckets, I group all data by the user_id. This means if the app grows to 10,000 users, BigQuery can jump much faster to your data without reading everyone else's.

## ✨ Features
### The 24x4 Grid
A simple grid representing 24 hours in 15-minute chunks. You can "paint" your day with your finger to log activities.

### Statistics
- Time Distribution: A colored breakdown of your day.
- Productivity Filter: You can choose which categories (like "Deep Work") count as productive and which (like "Doomscrolling") count as waste.
- Daily Insights: Dynamic text that tells you how your productivity was today.

### Notifications
- Modifiable notifications. You can set it to send you reminders every 15 minutes, hour, 2 hours, 4 hours, or at a specific time of day.

## 🏗 How It Works
1. Log: You save your day in the app.
2. Store: Data goes to Supabase so you can see it instantly.
3. Sync: Every night, a Python script moves that data into BigQuery. The pipeline is designed to be idempotent, meaning if the script runs twice by mistake, it won't create duplicate entries.
4. Transformation: Dataform cleans raw logs into partitioned/clustered Fact/Dim tables.
5. Analyze: When you open the Statistics tab, the Express API asks BigQuery for the "big picture" and sends the results back to your app.

## 🚀 Plans for POST-MVP
- AI Coach: Using the data in BigQuery to suggest changes (e.g., "You lose 30% more time when you gym after 6 PM").
- Share Cards: Beautifully designed and possibly animated images of your stats to flex on others.
- Streak system

## 🛠 Setup
1. npm install in /backend
2. flutter pub get in /app
3. Setup your Dataform pipeline from /dataform
4. Set your .env keys for your Supabase and Google Cloud using .env.example
5. Start the backend server with ``npm run dev`` and the flutter app with ``flutter run``