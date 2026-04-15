Project Overview:
This project is a Smart Geo-Tagged Landmarks Android application developed using Flutter. The app interacts with a provided REST API to display, manage, and visit geographic landmarks. Each landmark contains a title, location (latitude & longitude), image, and a server-generated score.

Features Implemented:
- View landmarks from API
- Display landmarks on Google Map with markers
- Marker color changes based on score
- Visit landmark using current GPS location
- Show visit distance returned from server
- Landmark list with image, title, and score
- Sorting landmarks (high to low, low to high, title)
- Filtering landmarks by minimum score
- Activity screen showing visit history
- Add new landmark with image and GPS location
- Soft delete and restore landmarks
- Offline support with cached data and queued visits

API Usage:
The app uses the provided REST API:
- GET: Fetch landmarks
- POST: Visit landmark with user location
- POST: Create landmark with image upload
- POST: Delete and restore landmark

All API requests include a unique student key.

Offline Strategy:
- Landmarks are cached locally using SQLite database
- When offline, cached landmarks are shown
- Visit requests are stored locally with "pending" status
- When internet is available, queued visits are synced automatically
- Connectivity is monitored using connectivity_plus

Architecture Used:
- Repository Pattern (LandmarkRepository)
- Separation of concerns:
  - API Service (network calls)
  - Local Database (offline storage)
  - UI (Flutter screens and widgets)

Challenges Faced:
- Handling offline and online synchronization
- Managing image upload using multipart API
- GPS permission handling and location fetching
- Map integration and marker updates
- Error handling for API failures
