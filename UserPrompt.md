# User Prompts

**1.** # iOS Gallery Cleaner — Requirements & Implementation Checklist

## 1. What needs to be built

A small iOS app in **Swift**, using **SwiftUI or UIKit**, that reads the device Photos library.

### Required Features

1. **Screenshots**
   - Show all screenshots from the user's gallery.

2. **Videos**
   - Show all videos from the user's gallery.

3. **Duplicate Photos**
   - Find exact copies of photos.
   - Display them as duplicate groups.

4. **Similar Photos**
   - Find photos that look nearly the same.
   - Display them as similar groups.

5. **Duplicate Videos**
   - Find exact copies of videos.
   - Display them as duplicate groups.

6. **Large Videos**
   - Find videos that consume the most storage.
   - Sort them from largest to smallest.

Each option should open its corresponding items/results.

The UI design is flexible, but the purpose of every option must be immediately understandable.

---

## 2. Things to be careful about

### Performance

The app must work smoothly with **thousands of photos and videos**.

- Do not perform expensive processing on the main thread.
- Keep the UI responsive while scanning.
- Use asynchronous/background processing.
- Show loading/progress states.
- Do not load every full-resolution image into memory.

### Image Loading

- Use thumbnails in grids/lists.
- Request appropriately sized images.
- Load images asynchronously.
- Avoid retaining thousands of large `UIImage` objects.
- Consider image caching.
- Only request full-resolution images when the user opens an image.

### Photos Permission

Handle:

- Permission granted
- Permission denied
- Limited access
- Restricted access
- Empty gallery

Never assume Photos permission has already been granted.

---

## 3. Duplicate vs Similar Photos

This distinction is extremely important.

### Duplicate

```text
A == B


read this markdown and the images that are shown as above i want to create an ios app so make app according to above requirement for an internship shortlising task

dont implement anything right just read it and then we will implement one by one everything

**2.** first what can we do is create the ui and then we can implement the implementation what do you say???

**3.** first what can we do is create the ui and then we can implement the implementation what do you say??? so just tell me when you are ready ill tell you what to make

**4.** alright for this app first create these three tabs similar to shown in the image

**5.** after going on every tab show a option like this is all tab this is photos tab

**6.** now do one thing make it structure in MVVM architecuture

**7.** the pill tab bar can it be made natively??

**8.** make the native picker once

**9.** option2 is better that already existes

**10.** can we also have a search button here?? make it like the image

only tak reference of the search button

**11.** can we also have a search button here?? make it like the image

only tak reference of the search button

**12.** its a screenshot of the photos app from iphone i want you to tell me is it possible the same tab bar using a native api of swiftui as in photos app this tab bar is made and it looks so good from the height and width

**13.** make it look like apples one tabbar

**14.** now see i want you to make the ui of all tab make something like this also try to implement everything so that this app can take permission of the device or the photos app

if we need access to the user's Photos library through Apple's PhotoKit (Photos) framework than do it also you can make the ui for both photos and videos tab ui as you want

**15.** now see there is thing i want you to pin these four categories only see like the image2 and also see image3 where after the four pinned categories all other categories gets smaller in height and width compared to top four categories that are pinned

**16.** see at the below of pinned 4 categories i dont want you to show these categories that are told to do in the task

here i want you to show categories like Download, Whatsapp, Telegram or photos taken from any other apps

**17.** right now you have hardcoded the app names it but i want a real implemetation like if the app is installed in the device and if any image is clicked from it then show that images here 

make it real

**18.** now make screens for showing in grids when tapped on any of the category

**19.** see how badly right now the images of a particular category are showing

take reference from image2 and image3

**20.** now the exists is when im tapping on any particular category and after navigating when im tapping on a particular image then then this black screen is showing i want you to fix this

**21.** now the exists is when im tapping on any particular category and after navigating when im tapping on a particular image then then this black screen is showing i want you to fix this make a proper preview for selected image

**22.** good job 

next work is on the same screen make the images swipable so that i can see the other image of the same category

**23.** now one thing i want to do is improve the animation when tapping on a particular image and it opens on full preview

**24.** now one thing i want to do is improve the animation when tapping on a particular image and it opens on full preview, implement very simple like photos app of the iphone

dont change anything related to ui dont change postion of buttons and all only make the animation better

**25.** no the animation is still not good make it simple more

**26.** do one thing remove these texts from tab only keep the symbols and make the width of the tab bar bit small

**27.** now implement the search bar for this app

**28.** now implement the search bar for this app make the tabs in center as it is right now 

also dont change the theme or color of the buttons or tabs anything

**29.** now do one thing for images and videos dont show the categories only show all the images and videos of device here 

later we will implement the similar images and duplicate images or videos right now only impelement the above task given

**30.** now implement filter button for  photos 

for photos tab implement in the filter:
1) duplicate photos and similar photos  

also first tell me how are you going to implement the duplicate photos and similar photos 

first tell me how are you going to implement and after telling how you are going to implement and later ill tell you start implementing

**31.** 1. Duplicate Photos
Goal: Find exact copies of photos.
Approach
Use a hash/checksum of the image data.
Photo A → Hash
Photo B → Hash
Photo C → Hash

Same Hash → Duplicate
Different Hash → Not Duplicate
Logic
- Generate a hash for each photo.
- Group photos with the same hash.
- Each group represents exact duplicates.
- Keep one copy and allow the user to delete the remaining copies.



Similar Photos
Goal: Find photos that look visually similar but are not necessarily identical.
Approach
Use Apple's Vision framework for image feature analysis and compare the extracted visual features.
Examples:
- Same scene with slightly different shots
- Burst-style photos
- Same person/subject with different framing
- Edited or cropped versions


Logic
- Extract visual features from each photo.
- Compare the features between photos.
- Calculate a similarity score.
- If the score is above a chosen threshold, place the photos in the same similar-photo group.

i just want you to confirm is it the same thing you told above 

if not tell me this is correct or above was correct

**32.** lets implement it now first complete for photos

**33.** use the filter button as shown in the image1 also remove the sf symbols used in filter buttons used in the filter context menu

**34.** are you sure you are the filters for duplicate and similar photos

**35.** see again i think duplicate filter or option is not working properly i want you to on it again and see if it's implemented correctly or not

as i duplicated a photo from photos app still in our Tidy Media app the both duplicate photos were not shown but in all photos filter the both duplicated images are showing

**36.** so do one thing when applying any fitler at top as you can see the second image the duplicate photos and select copies text is shown remove that part i dont want it remove the text with that entire section acting as a button

**37.** now there is one taks i want you to see 

these top categories at albums tab should be visible at top only when there is any media in it 

for example there is no favorites images therefore dont show it's category show it only when there is favorite images

**38.** here when previwing any image show a heart button to favorite it and remove the share button that is on left of delete button and make the heart button in place of it

**39.** you havent removed the share button remove this only keep hear and delete button at top right

**40.** now i want you to fix one issue that is the images are not getting loaded on

**41.** now i want you to fix one issue that is the images are not getting loaded on the albums tab 
after opening the app on the albums tab the images are not showing but once going on images tab or the videos tab and then again coming back on albums tab the images are getting loaded i want you to find the issue and fix it

**42.** now i want you to fix one issue that is the images are not getting loaded on the albums tab 
after opening the app on the albums tab the images are not showing but once going on images tab or the videos tab and then again coming back on albums tab the images are getting loaded i want you to find the issue and fix it

dont change anything in ui just implement the image loading

**43.** good job the images are loading correctly

but the first image of every collection is looking blurred why is it find the issue and fix it

**44.** now there is another issue i want you to fix that is when i tap on particular image it doesnt opens instead of another image opens 

the issue i can assume is that in a grid each grid doesnt have same size it is depending on the size of image 

so i want you to find the issue and fix it

**45.** now there is another issue i want you to fix that is when i tap on particular image it doesnt opens instead of another image opens 

the issue i can assume is that in a grid each grid doesnt have same size it is depending on the size of image 

so i want you to find the issue and fix it

dont change ui or anything else just work upon above given task

**46.** next issue i want you to fix is when im trying to preview any image there is a strange thing happening 

when i tap on the image to preview a blink type animation or something is happening i want you to fix it

**47.** now there is one thing whenever im going or tapping on a collection to see all images in grid of collections right now there is sheet type behaviour 
i want it as a navigation orr zoom in type navigation behaviour onto another screen

**48.** in similar and duplicate photos how is the app able to tell best and keep label on what basis

**49.** for keep and best label use it at bottom right without sf symbol it will make it look more clean

**50.** see i want you to do something else for writting Grouop1, Grouop2 , Grouop3 etc. or Similar1, Similar2 , Similar3 etc as it's making the ui little bit bigger and doesnt looks clean do something so that this screen becomes clean

**51.** good look there few things i want you do for the similar and duplicate photos groups so in a group if there are more than 3 images then all the images will not be seen, all the images will be shown when we will go inside or navigate to the group the we will be able to see all the images of a group in a grid 

so keep limit to show 3 it means if the image is one or two or three in a group then it can be shown outside but if it's more than 3 then the user has to navigate to the group

**52.** now if you can see our tab is inside a black rectangle i want you to fix this remove this black rectangle around our tabs

**53.** remove this part from the similar and duplicate detail screen

**54.** now when previwing a video why im not able to play it make it happen so that i can play the videos

**55.** look how is video is playing make it nice proper full view

**56.** right now the issue is when im trying to make play a video the label of date and time is overlapping with the timerplay of the video fix this

**57.** make sure the label of date and time are also showing for images as for now i can only see it for the videos

**58.** now add a filter button for Videos tab for large videos and duplicate videos

**59.** just remove the clean up part ui at the top from videos section

**60.** now at the bottom of albums make a recently deleted button and when tapping on it show the recently deleted and also give option to recover

**61.** make sure recently deleted is working 

as im deleting anything it's not showing there

**62.** make simple recover and delete button with corner radius like modern buttons  in the recently deleted

**63.** make these buttons delete and recover simple without any color as shown in the second image

**64.** remove the text how many days left before getting deleted permanently

**65.** can you tell and fix why the image is looking blurred but after previwing it looks clean in the recently deleted view

**66.** now lets remove the unecesaary buttons remove three dots button on top left from the albums tab

**67.** now after tapping on categories these buttons in image2,3 and 4 remove these button they have no use in our app

**68.** now remove three dots vertical button from photos an videos tab from top left button

**69.** at the albums tab at the top pinned first category called Camera instead of Camera use Photo text

**70.** now at the albums tab there is sort navigationTitle Albums make it pin at top when scrolling

**71.** now see when the image are sorted for duplicate or the similar images dont use these completion bar or loading bar 

instead show it quickly just like you are doing with filter of duplicate videos

**72.** can you tell me whats the background color of the app

**73.** see i dont wnat our apps to be only black themed it should be able to adapt both light and black or dark color when from apple's settings we swtich dark or light

**74.** this is our app icon and color codes are shared above i want you apply these to our app so that our app starts to look actually a good in color design rather than simple app

**75.** this is the icon of our app and the primary blue make it as the accent color of the app 

so apply it

**76.** i want you to remove these grant access part as apple itself give a menu to ask for permission like allow all access or media access and all so there is no need of this menu

once the apple default menu open sync the data from photos app

**77.** now make simple few onboarding screens so that once the user downlaods the app for the first time he can see whats there for him

**78.** make the texts on eac onboarding screen short and small and accurate as user dont have much time to read it

**79.** can put these in points the auto picks best photo etc text 

because like in this view it's looking weird

**80.** dont use continue button for first two onboarding screen direclty show Get started button on third onboarding screen

**81.** Bring order to your media

now use this as the tag line for launch screen of the app with app icon and name of the app

**82.** see read these pages how to create a good read me file 

also i want you to go on internet and search for the how to make read me file for ios applications and create a good read me file for our app

**83.** why have you used the div center and all in read me file you know that it's a ios app

**84.** Tidy Media
Bring order to your media.

Tidy Media is a native iOS gallery cleaner and media organizer designed to help users find and manage unwanted or redundant photos and videos.
 
✨ Features
Tidy Media focuses on six core media-management categories:
📸 Screenshots
Find screenshots stored in the user's Photos library in one dedicated place.
🎥 Videos
Browse the videos available in the Photos library.
🔄 Duplicate Photos
Find exact duplicate photos and group them together for easier review and cleanup.
🖼️ Similar Photos
Identify photos that are visually similar, such as multiple shots of the same scene or subject.
🎬 Duplicate Videos
Find exact duplicate video assets and group them together for review.
📦 Large Videos
Sort videos by file size so users can quickly identify videos consuming the most storage.
🎯 Goal
Tidy Media is not a replacement for Apple's Photos app.
It works with the user's existing Photos library and provides a focused interface for finding media that may be duplicated, unnecessary, or taking significant storage space.
Apple Photos Library
        ↓
     PhotoKit
        ↓
    Tidy Media
        ↓
 ┌─────────────────┐
 │ Screenshots     │
 │ Videos          │
 │ Duplicate Photos│
 │ Similar Photos  │
 │ Duplicate Videos│
 │ Large Videos    │
 └─────────────────┘
        ↓
   Review / Manage
🛠️ Tech Stack
Technology	Purpose
Swift	Core programming language
SwiftUI	User interface
PhotoKit (Photos)	Access and manage the user's Photos library
Vision	Visual analysis for identifying similar photos
AVFoundation	Video-related processing and previews
Swift Concurrency	Background processing and responsive UI
PHCachingImageManager	Efficient thumbnail loading and caching


Tidy Media is built using Apple's native frameworks and does not require a backend or cloud server for its core functionality.
🏗️ Architecture
Tidy Media follows an MVVM-oriented structure with dedicated services for Photos-library operations and media processing.
┌──────────────────────────────────────────┐
│                SwiftUI Views             │
│       Home / Category / Media Screens    │
└─────────────────────▲────────────────────┘
                      │
                 State / Bindings
                      │
┌─────────────────────┴────────────────────┐
│               ViewModels                 │
│        UI State & Business Logic         │
└─────────────────────▲────────────────────┘
                      │
┌─────────────────────┴────────────────────┐
│                Services                  │
│ Photo Library / Media Analysis / Video   │
└─────────────────────▲────────────────────┘
                      │
┌─────────────────────┴────────────────────┐
│           Apple System Frameworks        │
│     PhotoKit / Vision / AVFoundation     │
└──────────────────────────────────────────┘
Performance
The app is designed to remain responsive while working with large photo libraries.
Key considerations include:
- Background processing for expensive operations.
- Lazy loading of media grids.
- Thumbnail-based rendering instead of loading full-resolution images unnecessarily.
- PHCachingImageManager for efficient image caching.
- Swift Concurrency for non-blocking work.
- Incremental processing instead of loading thousands of full-resolution assets into memory at once.
🔐 Photos Permission
Tidy Media uses Apple's PhotoKit framework to access the user's existing Photos library.
The app requests Photos access so it can:
- Read photos and videos.
- Analyze media.
- Identify duplicates and similar photos.
- Sort videos by size.
- Delete selected assets when the user explicitly chooses to remove them.
The app should handle both full and limited Photos access appropriately.
If the user grants limited access, Tidy Media only works with the assets made available by the user.
🔒 Privacy
Privacy is a core part of the app design.
- Photos and videos are processed on the device.
- No media needs to be uploaded to a cloud server.
- No backend is required for gallery analysis.
- The app uses Apple's native Photos permission system.
- Deletion is performed through PhotoKit after explicit user action.
Tidy Media does not need to copy the user's entire Photos library into a separate cloud database.
🧠 Duplicate vs Similar Photos
Tidy Media treats duplicate and similar photos differently.
Duplicate Photos
Duplicate detection looks for exact copies.
Photo A → Hash A
Photo B → Hash A
Photo C → Hash B

A = B → Duplicate
A ≠ C → Not Duplicate
Similar Photos
Similar-photo detection focuses on visual similarity rather than identical file data.
Examples include:
- Multiple shots of the same scene.
- Similar photos taken moments apart.
- Different images of the same subject.
- Visually similar versions of an image.
Vision-based image feature analysis can be used to compare the visual characteristics of photos.
📱 User Flow
Launch App
    ↓
Onboarding
    ↓
Photos Permission
    ↓
Tidy Media Home
    ↓
Select Category
    ↓
Scan / Load Media
    ↓
Review Results
    ↓
Select Media
    ↓
Confirm Action
    ↓
Manage / Delete Selected Assets
📂 Project Structure
The exact structure may vary depending on the implementation.
Tidy-Media/
│
├── Tidy Media/
│   ├── Tidy_MediaApp.swift
│   ├── ContentView.swift
│   │
│   ├── Models/
│   ├── ViewModels/
│   │
│   ├── Services/
│   │   ├── PhotoLibraryService.swift
│   │   └── MediaAnalysisService.swift
│   │
│   ├── Views/
│   │   ├── OnboardingView.swift
│   │   ├── AlbumsGridView.swift
│   │   ├── AlbumDetailView.swift
│   │   ├── MediaGridView.swift
│   │   └── Components/
│   │
│   └── Assets.xcassets/
│
├── assets/
├── Tidy Media.xcodeproj
└── README.md
Update the structure above if your actual repository uses different filenames.

🚀 Getting Started
Requirements
- macOS
- Xcode
- iOS 17.0+
- A physical iPhone is recommended for testing the Photos library and deletion flow.
Installation
git clone <YOUR_REPOSITORY_URL>
cd Tidy-Media
Open the Xcode project:
open "Tidy Media.xcodeproj"
Select the Tidy Media scheme and run it on an iOS Simulator or connected iPhone.
Photos Permission
On first launch, allow Photos access when prompted.
For complete gallery testing, use Full Access.
🧪 Testing
The app should be tested with:
- Small photo libraries.
- Large photo libraries containing thousands of assets.
- Many screenshots.
- Multiple duplicate photo groups.
- Multiple similar-photo groups.
- Large video files.
- Duplicate videos.
- Limited Photos access.
- Full Photos access.
- Deletion and cancellation flows.
Performance should be monitored to ensure scanning and media loading do not freeze the UI.
🎨 Design
Tidy Media follows a native iOS visual approach using SwiftUI.
The design focuses on:
- Simple navigation.
- Clear category-based organization.
- Native iOS components.
- Smooth scrolling.
- Clear selection states.
- Lightweight onboarding.
- Light and Dark Mode support.
- Consistent brand accent color.
Brand Color
Primary Accent: #2879E7
📋 Assignment Scope
The application was developed as an iOS Gallery Cleaner task with the following required categories:
- Screenshots
- Videos
- Duplicate Photos
- Similar Photos
- Duplicate Videos
- Large Videos
The primary focus is efficient media loading, responsive UI, accurate categorization, and safe media management.

make the read me according to this

**85.** now i just want you to create a md file for whatever prompt i have given so far to create this application

**86.** see there is one task i want you to do that is i want you to make a md file called UserPrompt and you have to list all the prompts i have give you in the chat i want you to list that all in a md file with numbering so do it as fast as you can 

removember only list the propmpts i have given you nothing else
