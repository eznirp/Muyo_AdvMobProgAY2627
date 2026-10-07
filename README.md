# Prinze Lynard F. Muyo, MIT
## INF233
## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics. Covering the web to mobile transactions

## Lab Activity Instance

## Lab Activity: Discussion

setState is simpler for small, local state, while Provider is better 
for managing shared and more complex application state
 
 ## Lab Activity 2: Discussion

 The Product model handles JSON data, ProductService fetches and decodes it, and ProductScreen displays it using FutureBuilder. The app uses separation of responsibilities and Provider/ChangeNotifier for shared theme state.

 ## Lab Activity 3: Discussion

 The Cart Model, Cart Service, and Cart Screen work together by separating data, API communication, and UI responsibilities. The authentication enhancement follows the same pattern: User represents the API response, UserService handles login and SharedPreferences persistence, and SplashScreen, LoginScreen, and ProfileScreen handle the user flow. On launch, the splash screen checks the saved token and routes either to the shop or login screen. After a successful login, the saved User model is rendered in the profile tab, and logging out clears both the user data and token. This keeps API communication, persistence, and presentation separate and reusable.

## Lab Activity 4: Discussion

The app separates responsibilities using models, services, and screens. The User model represents API data, while UserService handles login and saves user information using SharedPreferences. The splash screen checks whether the user is logged in, the login screen authenticates the user, and the profile screen displays the saved user data.
The cart uses CartService to retrieve data from DummyJSON using the user ID. FutureBuilder handles loading and error states, while setState, Provider, and ChangeNotifier manage local and shared application state.

## Lab Activity 5: Discussion

The app uses one UserService for two login methods: username login through DummyJSON, which is for demos and saves profile data locally, and email/password login through Firebase, which manages authentication and stores profiles in Firestore. This lets the lab demonstrate both REST API authentication and Firebase’s cloud storage, token management, and security rules.

## Lab Activity 6: Discussion

Firestore stores each Firebase user’s full profile in users/{uid} and limited chat details in public_profiles/{uid}. When two users chat, their sorted UIDs form a shared chat_rooms document, with messages stored in its messages subcollection. The app excludes the signed-in user from the chat list and blocks self-chat.