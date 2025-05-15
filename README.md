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

## HealthKit Integration
The app leverages Apple HealthKit to:
- Access and process user sleep data (duration, stages, quality)
- Calculate sleep scores based on sleep patterns
- Track sleep consistency and improvement over time
- Update user streak based on sleep duration and quality

## HealthKitTestApp
This companion application generates and writes simulated sleep data to HealthKit for testing purposes:
- Creates randomized sleep data for the past 10 days
- Simulates various sleep stages (Core, Deep, REM, Awake)
- Generates realistic sleep durations between 3-10 hours
- Useful for development and testing without requiring real user sleep data

### How to use HealthKitTestApp:
1. Build and run the HealthKitTestApp on your device/simulator
2. Grant HealthKit permissions when prompted
3. The app will automatically generate and write test sleep data
4. Switch to the main Dreamio app to see this test data visualized and analyzed

## Sleep Scoring Algorithm
Dreamio uses a sophisticated algorithm to calculate sleep quality scores:
- **Duration Score (40%)**: Based on total sleep time, with 8 hours being optimal
- **Consistency Score (30%)**: Measures regular bedtime habits
- **Quality Score (30%)**: Evaluates proportion of deep and REM sleep stages

## Privacy
Dreamio uses HealthKit to access sleep data and provides insights while respecting user privacy. All data processing happens locally on the device unless explicitly shared through Firebase services.
