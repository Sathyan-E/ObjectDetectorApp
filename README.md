# ObjectDetectorApp
- This app will help you to detect the objects in a picture and highlight the object by adding bounding box around the object with its name.
# How it works:
- Once image source is passed to the app, it will run the Tensorflowlite model on the image and infer the object details.
# External Dependency
- Tensorflowlite
# How to run?
## Simulator
- Just clone the repository & navigate to project directory
- Do a `pod install` 
- Open the .xcworkspace file after successful pod installation
- Build the project on Xcode
- Select a simulator and run it.
## Physical Device
- This is app's bundle id `com.sathyan.ai.ObjectDetector`
- Create necessary bundle indentifir, profile, certificate and add your device details in certificate
- Import those files your local machine & sync with Xcode
- Connect your device with the machine & run the project from Xcode
