# CreatorOS - AI-Powered Omnichannel Content Management Platform

![CreatorOS Banner](https://img.shields.io/badge/Status-Active-brightgreen) ![Platform](https://img.shields.io/badge/Platform-Flutter%20%7C%20Node.js-blue) ![License](https://img.shields.io/badge/License-MIT-green)

CreatorOS is an all-in-one, enterprise-grade content management system designed for digital creators, influencers, and marketing teams. By combining a **Flutter** frontend with a robust **Node.js/Express** multi-tenant backend, CreatorOS provides a centralized hub to generate, schedule, and analyze content across multiple social platforms (YouTube, LinkedIn, Meta/Instagram).

## 🚀 Project Overview

Managing content across diverse platforms is fragmented and time-consuming. CreatorOS solves this by integrating **Generative AI (Gemini, OpenAI, Groq)** directly into the creator's workflow. It enables secure omnichannel publishing, centralized analytics, and AI-assisted content strategy—all protected by a secure, multi-tenant database architecture.

## ✨ Key Features

- **Multi-Tenant Database Architecture**: Ensures total data isolation and security. Every creator has a unique user identity managed via JWT-based secure authentication and MongoDB object referencing.
- **Generative AI Integration**: Leverage advanced LLMs to brainstorm ideas, write video scripts, generate social media captions, and provide predictive analytics.
- **Omnichannel OAuth Publishing**: Connect and securely authenticate with **YouTube, LinkedIn, and Meta**. Schedule and publish text, images, and video content directly from a single dashboard.
- **Advanced Analytics Dashboard**: Cross-platform performance tracking. Visualize audience engagement, growth trends, and content metrics via interactive `fl_chart` graphs.
- **Media Management**: Secure media handling with AWS S3 integration, supporting robust upload, storage, and retrieval workflows.
- **Automated Scheduling**: Node-cron powered background jobs ensure your content goes live exactly when scheduled, without manual intervention.

## 🏗 System Architecture

CreatorOS is built on a scalable, modern web architecture:

*   **Frontend (Flutter)**: A cross-platform mobile and web application. Uses `Provider` for robust state management, `shared_preferences` for local caching, and custom REST API clients for backend communication.
*   **Backend (Node.js/Express)**: A RESTful API serving as the central nervous system. It handles external OAuth handshakes, AI service brokering, and CRUD operations.
*   **Database (MongoDB/Mongoose)**: Document-oriented storage enforcing strict schemas for Users, Posts, Analytics, and Auth Tokens.
*   **Storage (AWS S3)**: Cloud object storage for high-availability media delivery.

## 💻 Tech Stack

**Client-Side (Frontend):**
*   **Framework**: Flutter (Dart)
*   **State Management**: Provider
*   **Data Visualization**: FL Chart
*   **Authentication**: Google Sign-In, JWT

**Server-Side (Backend):**
*   **Runtime**: Node.js
*   **Framework**: Express.js
*   **Database**: MongoDB with Mongoose ORM
*   **AI SDKs**: `@google/generative-ai`, `openai`, `groq-sdk`
*   **Cloud Storage**: AWS S3 (`@aws-sdk/client-s3`)
*   **Task Scheduling**: `node-cron`
*   **Media Processing**: `fluent-ffmpeg`

## 🛠 Setup & Installation

### Prerequisites
- Node.js (v18+)
- Flutter SDK (v3.19+)
- MongoDB instance (local or Atlas)
- API Keys for Google (OAuth & Gemini), AWS, and relevant Social Platforms.

### Backend Setup
1. Navigate to the `backend` directory.
2. Install dependencies: `npm install`
3. Create a `.env` file based on `.env.example` and populate your API credentials, Database URI, and JWT Secret.
4. Start the development server: `npm run dev` (or `node app.js`)

### Frontend Setup
1. Navigate to the `frontend` directory.
2. Install dependencies: `flutter pub get`
3. Run the application: `flutter run` (Specify your target device: web, ios, or android)

## 🔐 Security & Authentication

Security is a first-class citizen in CreatorOS:
- **Stateless JWT Auth**: User sessions are managed via signed JSON Web Tokens, eliminating server-side session state and improving scalability.
- **CORS Allowlisting**: Strict Cross-Origin Resource Sharing policies to prevent unauthorized API access.
- **Secure Token Storage**: OAuth access and refresh tokens from social platforms are securely encrypted before being stored in the database.

## 🗺 Future Enhancements

While CreatorOS is production-ready for core workflows, the following features are on our immediate roadmap:
- **TikTok OAuth Integration**: Expanding omnichannel reach.
- **AI Video Generation**: Integrating text-to-video capabilities directly into the media pipeline.
- **Collaborative Workspaces**: Allowing teams (editors, managers, creators) to collaborate on a single tenant account with role-based access control (RBAC).

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
