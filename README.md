# Dreamio

## Overview
Dreamio is an iOS sleep tracking and improvement app designed to help users achieve better sleep quality through various features including sleep tracking, personalized recommendations, relaxation techniques, and sound therapy.

## Features
- **Sleep Tracking**: Integration with Apple Health to monitor sleep patterns and provide insights
- **Sleep Score**: Calculation of sleep quality scores based on duration, consistency, and quality
- **Sleep Statistics**: Visual representation of sleep stages and patterns through graphs
- **Red Light Therapy**: Sleep-inducing red light for better sleep onset
- **Sound Therapy**: Collection of relaxing sounds and playlists to help with falling asleep
- **Breathing Exercises**: Guided breathing instructions for relaxation
- **Daily Tips**: Personalized recommendations for better sleep
- **Streak Tracking**: Monitor your consistency in maintaining good sleep habits

## Technical Architecture
- **Language**: Swift
- **Persistence**: Core Data for local storage
- **Authentication**: Firebase Authentication
- **Backend**: Firebase (Firestore, Analytics, Storage)
- **External Libraries**:
  - Charts (for sleep data visualization)
  - SwiftAlgorithms
  - GoogleSignIn

## Requirements
- iOS 15.0+
- Xcode 14.0+
- Swift 5.0+

## Setup and Installation
1. Clone the repository
2. Run `pod install` to install dependencies
3. Open `Dreamio.xcworkspace` in Xcode
4. Build and run the project

## Project Structure
- **HomeAndStats**: Sleep statistics and home screen functionality
- **RedLight**: Red light therapy implementation
- **BreathingInstructions**: Breathing exercise guides
- **FirebaseAndHealthkit**: Integration with Firebase and Apple HealthKit
- **Model**: Core Data models and management
- **bottomPlaybackView**: Audio playback interface

## Privacy
Dreamio uses HealthKit to access sleep data and provides insights while respecting user privacy. All data processing happens locally on the device unless explicitly shared through Firebase services.

## Team
Developed by Team 8

