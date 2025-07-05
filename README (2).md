# 🏛️ Municipality App

A Flutter application for community problem reporting, where users can post issues they encounter in their area (e.g., potholes, garbage, streetlights), and the admin can manage those reports by marking them as **Pending**, **Completed**, or deleting them.

This app empowers municipalities to better engage with citizens, improve transparency, and resolve issues faster.

---

## ✨ Features

✅ Users can:
- Register and log in securely.
- Post problems with title, description, and optional images.
- Set and update profile pictures.
- View their submitted problems in their profile.

✅ Admin can:
- View all reported problems in a dashboard.
- Mark problems as **Pending** or **Completed**.
- Delete inappropriate or resolved problems.
- View and manage registered users.
- See user details like profile image, username, and email.

✅ Notifications:
- When the admin updates a problem’s status, users receive a notification.

✅ Data:
- Uses **Firebase Firestore** for real-time database.
- Uses **Cloudinary** for image uploads.

### Prerequisites

- Flutter SDK installed (https://flutter.dev/docs/get-started/install)
- Firebase project set up with Authentication and Firestore.
- Cloudinary account for image uploads.
