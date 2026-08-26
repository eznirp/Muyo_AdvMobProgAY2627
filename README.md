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

 The Cart Model, Cart Service, and Cart Screen work together by separating data, API communication, and UI responsibilities. The Model represents cart data, the Service retrieves data from the API, and the Screen displays it through the same detail_screen.dart. The updated design pattern makes the code more organized and reusable. The getById endpoint retrieves a specific cart using its ID, converts the response into a Cart Model, and passes the data to detail_screen.dart for display
