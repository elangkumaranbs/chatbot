# Flutter Chatbot - Render Deployment

## 🌐 Deploying to Render

This Flutter chatbot can be deployed to Render as a static web application.

### Prerequisites
- GitHub repository with Flutter project
- Render account

### Deployment Steps

1. **Connect Repository**
   - Login to Render dashboard
   - Click "New +" → "Static Site"
   - Connect your GitHub repository

2. **Configure Build Settings**
   - **Build Command**: `./build.sh`
   - **Publish Directory**: `build/web`
   - **Auto-Deploy**: Yes

3. **Environment Settings**
   - **Environment**: Static Site
   - **Branch**: master
   - **Root Directory**: (leave empty)

### Build Process
The `build.sh` script will:
1. Install Flutter SDK
2. Enable web support
3. Install dependencies
4. Build for web production

### Live URL
Once deployed, your app will be available at:
`https://your-app-name.onrender.com`

## 🔧 Local Development

```bash
# Clone repository
git clone https://github.com/elangkumaranbs/chatbot.git
cd chatbot

# Install dependencies
flutter pub get

# Run web version
flutter run -d chrome
```

## 📱 Features
- AI-powered conversations
- Sidebar with chat history
- Image attachments
- Responsive design
- Material 3 UI
