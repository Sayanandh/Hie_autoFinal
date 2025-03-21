# API Documentation

## Endpoints

### 1. `/users/register`

#### Description
This endpoint registers a new user and sends an OTP to their email for verification.

#### Method
`POST`

#### Input
The request body should be in JSON format and include the following fields:

- `fullname`: An object containing the user's first name and last name.
  - `firstname`: The user's first name (string, required).
  - `lastname`: The user's last name (string, required).
- `email`: The user's email address (string, required).
- `password`: The user's password (string, required).

#### Example Request
```json
{
  "fullname": {
    "firstname": "John",
    "lastname": "Doe"
  },
  "email": "john.doe@example.com",
  "password": "securepassword"
}
```

#### Output
A JSON response with a message indicating that the OTP has been sent to the user's email.

#### Example Response
```json
{
  "message": "OTP sent to your email."
}
```

---

### 2. `/users/validate-otp`

#### Description
This endpoint validates the OTP sent to the user's email and completes the registration process.

#### Method
`POST`

#### Input
The request body should be in JSON format and include the following fields:

- `email`: The user's email address (string, required).
- `otp`: The OTP sent to the user's email (string, required).

#### Example Request
```json
{
  "email": "john.doe@example.com",
  "otp": "123456"
}
```

#### Output
If the OTP is valid, the response includes the user's details and a JWT token.

#### Example Response
```json
{
  "fullname": {
    "firstname": "John",
    "lastname": "Doe"
  },
  "email": "john.doe@example.com",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "_id": "60d0fe4f5311236168a109ca",
  "__v": 0
}
```

---

### 3. `/users/login`

#### Description
This endpoint is used to authenticate a user and generate a JWT token.

#### Method
`POST`

#### Input
The request body should be in JSON format and include the following fields:

- `email`: The user's email address (string, required).
- `password`: The user's password (string, required).

#### Example Request
```json
{
  "email": "john.doe@example.com",
  "password": "securepassword"
}
```

#### Output
The response will be in JSON format and include the user's details and a JWT token if the credentials are valid.

#### Example Response
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "record": {
    "firstname": "John",
    "lastname": "Doe",
    "email": "john.doe@example.com",
    "_id": "60d0fe4f5311236168a109ca",
    "__v": 0
  }
}
```

---

### 4. `/users/profile`

#### Description
This endpoint is used to retrieve the authenticated user's profile information.

#### Method
`GET`

#### Input
The request should include the JWT token in the Authorization header or as a cookie.

#### Example Request
```
GET /users/profile HTTP/1.1
Host: localhost:4000
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Output
The response will be in JSON format and include the authenticated user's profile information.

#### Example Response
```json
{
  "user": {
    "_id": "60d0fe4f5311236168a109ca",
    "firstname": "John",
    "lastname": "Doe",
    "email": "john.doe@example.com",
    "__v": 0
  }
}
```

---

### 5. `/users/logout`

#### Description
This endpoint is used to log out the authenticated user by clearing the JWT token and blacklisting it.

#### Method
`GET`

#### Input
The request should include the JWT token in the Authorization header or as a cookie.

#### Example Request
```
GET /users/logout HTTP/1.1
Host: localhost:4000
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Output
The response will be in JSON format and include a message indicating that the user has been logged out successfully.

#### Example Response
```json
{
  "message": "Logged out successfully"
}
```

---

### 6. `/captains/register`

#### Description
This endpoint is used to register a new captain. It sends an OTP to the captain's email for verification.

#### Method
`POST`

#### Input
The request body should be in JSON format and include the following fields:

- `fullname`: An object containing the user's first name and last name.
  - `firstname`: The user's first name (string, required).
  - `lastname`: The user's last name (string, required).
- `email`: The user's email address (string, required).
- `password`: The user's password (string, required).
- `vehicle`: An object containing the vehicle details.
  - `color`: The color of the vehicle (string, required).
  - `plate`: The vehicle's plate number (string, required).
  - `capacity`: The capacity of the vehicle (number, required).
  - `vehicleType`: The type of the vehicle (string, required, must be either "Three Wheeler" or "Four Wheeler").
- `verification`: An object containing the verification details.
  - `LicenseNumber`: The license number (string, required, must be at least 14 characters long).
  - `VehicleRegistrationNumber`: The vehicle registration number (string, required, must be at least 4 characters long).
  - `InsuranceNumber`: The insurance number (string, required, must be at least 5 characters long).
  - `CommertialRegistrationNumber`: The commercial registration number (string, required, must be at least 4 characters long).

#### Example Request
```json
{
  "fullname": {
    "firstname": "John",
    "lastname": "Doe"
  },
  "email": "john.doe@example.com",
  "password": "securepassword",
  "vehicle": {
    "color": "Red",
    "plate": "ABC123",
    "capacity": 4,
    "vehicleType": "Four Wheeler"
  },
  "verification": {
    "LicenseNumber": "DL12345678901234",
    "VehicleRegistrationNumber": "VRN1234",
    "InsuranceNumber": "INS12345",
    "CommertialRegistrationNumber": "CRN1234"
  }
}
```

#### Output
A JSON response with a message indicating that the OTP has been sent to the captain's email.

#### Example Response
```json
{
  "message": "OTP sent to your email."
}
```

---

### 7. `/captains/validate-otp`

#### Description
This endpoint validates the OTP sent to the captain's email and completes the registration process.

#### Method
`POST`

#### Input
The request body should be in JSON format and include the following fields:

- `email`: The captain's email address (string, required).
- `otp`: The OTP sent to the captain's email (string, required).

#### Example Request
```json
{
  "email": "john.doe@example.com",
  "otp": "123456"
}
```

#### Output
If the OTP is valid, the response includes the captain's details and a JWT token.

#### Example Response
```json
{
  "result": {
    "driver": {
      "fullname": {
        "firstname": "John",
        "lastname": "George"
      },
      "email": "johngeorge202@gmail.com",
      "password": "$2b$10$sZn1BNzhDcNDnDQ0udnC6eOmm8BJ977GdLHurPri2jsU63BkcmDA.",
      "status": "inactive",
      "vehicle": {
        "color": "Red",
        "plate": "ABC123",
        "capacity": 4,
        "vehicleType": "Four Wheeler"
      },
      "verification": {
        "LicenseNumber": "DL12345678901234",
        "VehicleRegistrationNumber": "VRN1234",
        "InsuranceNumber": "INS12345",
        "CommertialRegistrationNumber": "CRN1234"
      },
      "rating": 0,
      "IsUnionMember": false,
      "_id": "6772f1c7cdd9529d794336d8",
      "__v": 0
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NzcyZjFjN2NkZDk1MjlkNzk0MzM2ZDgiLCJpYXQiOjE3MzU1ODYyNDcsImV4cCI6MTczNTY3MjY0N30.AnvKdL1IIICfTZf9HZm87Gnn_JC2a0IUoaFwZ70pmcM"
  }
}
```

---
#### 8. `/captains/login`
**Description:** Authenticates a captain and generates a JWT token.

**Method:** `POST`

**Input:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "token": "JWT token",
  "record": {
    "fullname": {
      "firstname": "string",
      "lastname": "string"
    },
    "vehicle": {
      "color": "string",
      "plate": "string",
      "capacity": "number",
      "vehicleType": "string"
    },
    "verification": {
      "LicenseNumber": "string",
      "VehicleRegistrationNumber": "string",
      "InsuranceNumber": "string",
      "CommertialRegistrationNumber": "string"
    },
    "_id": "string",
    "email": "string",
    "status": "inactive",
    "rating": 0
  }
}
```

---

#### 9. `/captains/profile`
**Description:** Retrieves the authenticated captain's profile.

**Method:** `GET`

**Input:** Include JWT token in the Authorization header.

**Response:**
```json
{
  "captain": {
    "_id": "string",
    "fullname": {
      "firstname": "string",
      "lastname": "string"
    },
    "email": "string",
    "vehicle": {
      "color": "string",
      "plate": "string",
      "capacity": "number",
      "vehicleType": "string"
    },
    "verification": {
      "LicenseNumber": "string",
      "VehicleRegistrationNumber": "string",
      "InsuranceNumber": "string",
      "CommertialRegistrationNumber": "string"
    },
    "rating": 0
  }
}
```

---

### 10. `/captains/logout`
**Description:** Logs out the authenticated captain.

**Method:** `GET`

**Input:** Include JWT token in the Authorization header.

**Response:**
```json
{
  "message": "Logged out successfully."
}
```

---
### 11.`/maps/get-coordinate`

#### Description
This endpoint is used to get the coordinates (latitude and longitude) for a given address.

#### Method
`GET`

#### Input
The request should include the address as a query parameter.

#### Example Request
- GET http://localhost:4000/maps//get-coordinate?address=alappuzha
- Host: localhost:4000
- Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

#### Output
The response will be in JSON format and include the latitude and longitude of the given address.

#### Example Response
```json
{
  "lat": 38.8976763,
  "lng": -77.0365298
}
```

---

### 12.`/maps/get-distance-time`
### Description
This endpoint is used to get the distance and time between two locations.

#### Method
`GET`

#### Input
The request should include the origin and destination as query parameters.

#### Example Request
- GET http://localhost:4000/maps/get-distance-time?origin=aluva&destination=angamaly
- Host: localhost:4000
- Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

#### Output
The response will be in JSON format and include the distance (in meters) and duration (in seconds) between the origin and destination.

#### Example Response
```json
{
    "distance": 14007.377,
    "duration": 1458.789
}
```

---
### 13.`/maps/get-suggestions`
#### Description
This endpoint is used to get location suggestions based on a query string.

#### Method
`GET`

#### Input
The request should include the query string as a query parameter.

#### Example Request
- GET http://localhost:4000/maps/get-suggestions?query=Appolo Adlux karuku
- Host: localhost:4000
- Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

#### Output
The response will be in JSON format and include an array of location suggestions.

#### Example Responce
```json
{
    "suggestions": [
        "Karukutty, Aluva, Ernakulam, Kerala, India",
        "Karukumani Kalam Road, 678104, Koduvayur, Chittur, Palakkad, Kerala, India",
        "Karukutty Road, 683576, Karukutty, Aluva, Ernakulam, Kerala, India",
        "Kaluku, Gangapur, Ganjam, Odisha, India",
        "Karaku, Chainpur, Gumla, Jharkhand, India"
    ]
}
```

### 14. `/autostands/create`

**Description:**  
This endpoint creates a new auto stand with a queue system.

**Method:**  
`POST`

**Input:**  
The request body should be in JSON format and include the following fields:

- **standname**: The name of the auto stand (string, required).  
- **location**: An object containing location details.  
  - **latitude**: The latitude of the location (number, required).  
  - **longitude**: The longitude of the location (number, required).  

**Example Request:**  
```json
{
  "standname": "City Center Auto Stand",
  "location": {
    "latitude": 9.9312,
    "longitude": 76.2673
  }
}
```

**Response:**  
A JSON response with the details of the newly created auto stand.

**Example Response:**  
```json
{
  "message": "AutoStand created successfully",
  "autoStand": {
    "_id": "64b6f3f9c88d423b5c3f1a72",
    "standname": "City Center Auto Stand",
    "location": {
      "ltd": 9.9312,
      "lng": 76.2673
    },
    "creatorID": "64b6e3e6c88d423b5c3f1a67",
    "members": [
      "64b6e3e6c88d423b5c3f1a67"
    ],
    "queueID": "64b6f3fac88d423b5c3f1a73",
    "__v": 0
  }
}
```

---

### 15. `/autostands/update/:id`

**Description:**  
This endpoint updates an existing auto stand's details, such as name or location.

**Method:**  
`PUT`

**Parameters:**  
- **id**: The ID of the auto stand to update (string, required).  

**Input:**  
The request body should be in JSON format and can include the following fields:  

- **standname**: The new name of the auto stand (string, optional).  
- **location**: An object containing new location details (optional).  
  - **latitude**: The updated latitude of the location (number, required if location is provided).  
  - **longitude**: The updated longitude of the location (number, required if location is provided).  

**Example Request:**  
```json
{
  "standname": "Updated Auto Stand Name",
  "location": {
    "latitude": 10.1234,
    "longitude": 77.5678
  }
}
```

**Response:**  
A JSON response with the updated details of the auto stand.

**Example Response:**  
```json
{
  "message": "AutoStand updated successfully",
  "autoStand": {
    "_id": "64b6f3f9c88d423b5c3f1a72",
    "standname": "Updated Auto Stand Name",
    "location": {
      "ltd": 10.1234,
      "lng": 77.5678
    },
    "creatorID": "64b6e3e6c88d423b5c3f1a67",
    "members": [
      "64b6e3e6c88d423b5c3f1a67"
    ],
    "queueID": "64b6f3fac88d423b5c3f1a73",
    "__v": 0
  }
}
```

---

### 16. `/autostands/delete/:id`

**Description:**  
This endpoint deletes an auto stand and its associated queue.

**Method:**  
`DELETE`

**Parameters:**  
- **id**: The ID of the auto stand to delete (string, required).  

**Response:**  
A JSON response confirming the deletion of the auto stand and its queue.

**Example Response:**  
```json
{
  "message": "AutoStand deleted successfully"
}
```


---
### 17. POST /autostands/add-member

### **Description**
This route allows adding a captain as a member of an AutoStand by sending a request to the union members. The request will be notified to union members via email and Socket.IO. If a union member is offline, the notification is saved for later.

### **Input (Request Body)**

```json
{
  "standId": "string (required) - ID of the AutoStand",
  "joiningCaptainId": "string (required) - ID of the captain requesting to join"
}
```

### **Output (Response)**

#### **Success Response (200)**

```json
{
  "message": "Request sent to union members"
}
```

#### **Error Response (400)**

```json
{
  "message": "An error occurred while processing the request"
}
```

Possible error messages:
- `AutoStand not found`: If the provided `standId` does not exist.
- `Joining captain not found`: If the provided `joiningCaptainId` does not exist.
- `Captain is already a member of this AutoStand`: If the captain is already part of the AutoStand.
- `Captain is already a member of another AutoStand`: If the captain is part of another AutoStand.

### **Socket Events**

- **Event Name**: `request_notification`
- **Payload**:
  ```json
  {
    "standId": "string",
    "joiningCaptainId": "string",
    "message": "string"
  }
  ```
- **Recipients**: Union members who have a connected `socketId`.

The event is triggered when a captain requests to join an AutoStand. The event sends a notification to online union members and saves offline notifications for union members who are not online.

#### **Example of Socket Emission**

```json
{
  "standId": "1234567890abcdef",
  "joiningCaptainId": "0987654321fedcba",
  "message": "John Doe wants to join AutoStand CoolStand, vehicle number is ABC1234"
}
```

---

### 18. POST /autostands/respond-to-request

### **Description**
This route allows union members to respond to a captain's request to join an AutoStand by either accepting or rejecting the request.

### **Input (Request Body)**

```json
{
  "standId": "string (required) - ID of the AutoStand",
  "joiningCaptainId": "string (required) - ID of the captain requesting to join",
  "response": "string (required) - Response to the request ('accept' or 'reject')"
}
```

### **Output (Response)**

#### **Success Response (200)**

```json
{
  "message": "Request accepted/rejected"
}
```

#### **Error Response (400)**

```json
{
  "message": "An error occurred while responding to the request"
}
```

Possible error messages:
- `AutoStand not found`: If the provided `standId` does not exist.
- `Joining captain not found`: If the provided `joiningCaptainId` does not exist.
- `Captain is already a member of this AutoStand`: If the captain is already part of the AutoStand.
- `Pending request not found`: If no pending request is found for the captain and AutoStand.
- `Invalid response`: If the response is not 'accept' or 'reject'.


### 19./autostands/search

#### Auto Stand Search Endpoint

This document describes the `POST /search` route for searching and sorting auto stands based on a name query and captain's current location.

---

## Endpoint

### URL
`POST /search`

### Description
This endpoint allows captains to search for auto stands by name and sort the results based on proximity to their current location.

---

## Request

### Headers
- **Authorization**: Bearer token for authentication is required.

### Body
The request body must be a JSON object with the following fields:

| Field        | Type   | Required | Description                                     |
|--------------|--------|----------|-------------------------------------------------|
| `name`       | String | Yes      | The name of the auto stand to search for.       |
| `captainLat` | Number | Yes      | The latitude of the captain's current location. |
| `captainLng` | Number | Yes      | The longitude of the captain's current location.|

#### Example
```json
{
  "name": "Stand A",
  "captainLat": 12.971598,
  "captainLng": 77.594566
}
```

---

## Response

### Success Response
- **Status Code**: `200 OK`
- **Body**: Array of matching auto stands sorted by distance from the captain's location.

#### Example
```json
[
  {
    "_id": "63fbc28c5f1c2e3f2b7e1243",
    "standname": "Stand A",
    "location": { "ltd": 12.972, "lng": 77.595 },
    "creatorID": "63fbc28c5f1c2e3f2b7e1242",
    "createdAt": "2023-12-01T10:00:00Z",
    "members": [],
    "queueID": "63fbc28c5f1c2e3f2b7e1244",
    "distance": 0.2
  },
  {
    "_id": "63fbc28c5f1c2e3f2b7e1245",
    "standname": "Stand B",
    "location": { "ltd": 12.973, "lng": 77.596 },
    "creatorID": "63fbc28c5f1c2e3f2b7e1246",
    "createdAt": "2023-12-01T10:05:00Z",
    "members": [],
    "queueID": "63fbc28c5f1c2e3f2b7e1247",
    "distance": 0.4
  }
]
```

### Error Responses

#### Missing Parameters
- **Status Code**: `400 Bad Request`
- **Body**:
```json
{
  "message": "Valid stand name is required."
}
```

#### Invalid Location Values
- **Status Code**: `400 Bad Request`
- **Body**:
```json
{
  "message": "Valid latitude and longitude values are required."
}
```

#### No Matching Results
- **Status Code**: `404 Not Found`
- **Body**:
```json
{
  "message": "No auto stands found matching the search criteria."
}
```

#### Server Error
- **Status Code**: `500 Internal Server Error`
- **Body**:
```json
{
  "message": "An error occurred while searching for auto stands."
}
```

---

## Notes

- The search for auto stand names is case-insensitive.
- The response includes a calculated `distance` field, representing the distance (in kilometers) from the captain's location to each auto stand.
- Only auto stands with valid location data (`ltd` and `lng`) are included in the results.

---

### **20. DELETE /autostands/:id/remove-member**

### **Description**
This route allows removing a captain (driver) from an AutoStand's membership and its associated queue. Additionally, it updates the captain's `currentStandId` field to null.

### **Input (Request Parameters and Body)**

#### **Path Parameter**
```json
{
  "id": "string (required) - ID of the AutoStand"
}
```

#### **Request Body**
```json
{
  "driverID": "string (required) - ID of the captain to be removed"
}
```

### **Output (Response)**

#### **Success Response (200)**
```json
{
  "message": "Driver removed from AutoStand and queue successfully",
  "autoStand": "object - Updated AutoStand details",
  "updatedCaptain": "object - Updated captain details"
}
```

#### **Error Response (400)**
```json
{
  "message": "Invalid AutoStand ID"
}
```
- **`AutoStand not found`**: If the AutoStand with the provided `id` does not exist.
- **`Driver is not a member of this AutoStand`**: If the `driverID` is not part of the AutoStand.

#### **Error Response (404)**
```json
{
  "message": "Driver not found"
}
```

#### **Error Response (500)**
```json
{
  "message": "An error occurred while removing the member"
}
```

---

### **21. GET /autostands/:id/members**

### **Description**
This route retrieves a list of all captains (drivers) who are members of the specified AutoStand, including their basic details such as name, email, status, and vehicle information.

### **Input (Request Parameters)**

#### **Path Parameter**
```json
{
  "id": "string (required) - ID of the AutoStand"
}
```

### **Output (Response)**

#### **Success Response (200)**
```json
{
  "message": "AutoStand members retrieved successfully",
  "members": [
    {
      "driverID": "string - ID of the captain",
      "fullname": "string - Full name of the captain",
      "email": "string - Email of the captain",
      "status": "string - Current status of the captain",
      "vehiclePlate": "string - Vehicle plate number",
      "isUnionMember": "boolean - Indicates if the captain is a union member"
    }
  ]
}
```

#### **Error Response (400)**
```json
{
  "message": "Invalid AutoStand ID"
}
```

#### **Error Response (404)**
```json
{
  "message": "AutoStand not found"
}
```

#### **Error Response (500)**
```json
{
  "message": "An error occurred while fetching the members"
}
```

---

### **22. PUT toggle/toggle-queue/:autostandId**

### **Description**
This route allows a driver to toggle their status in the queue of a specific AutoStand. Drivers can either join or leave the queue, provided they meet the proximity requirement to the AutoStand. If the driver is farther than 50 meters from the AutoStand, they are automatically removed from the queue.

---

### **Input (Request Parameters and Body)**

#### **Path Parameter**
```json
{
  "autostandId": "string (required) - ID of the AutoStand"
}
```

#### **Request Body**
```json
{
  "driverID": "string (required) - ID of the driver toggling their queue status",
  "toggleStatus": "boolean (required) - `true` to add the driver to the queue, `false` to remove",
  "currentLocation": {
    "lat": "number (required) - Driver's current latitude",
    "lng": "number (required) - Driver's current longitude"
  }
}
```

---

### **Output (Response)**

#### **Success Response (200)**
```json
{
  "message": "Queue updated successfully",
  "queue": "object - Updated queue details"
}
```

#### **Error Responses**

**400: Bad Request**
```json
{
  "message": "Current location is required"
}
```
- **`Autostand not found`**: If the provided AutoStand ID is invalid or not found.
- **`Driver is not a member of this AutoStand`**: If the driver is not registered as a member of the specified AutoStand.
- **`No queue has been created for this autostand yet`**: If the AutoStand does not have an associated queue.
- **`Driver not found in the queue`**: When trying to remove a driver not in the queue.

**400: Driver Too Far**
```json
{
  "message": "Driver is too far away from the AutoStand and has been removed from the queue."
}
```
- This occurs if the driver's distance from the AutoStand exceeds 50 meters.

**500: Internal Server Error**
```json
{
  "message": "Error updating queue"
}
```


---


### 23. /rides/get-price

This document provides details about the `/rides/get-price` endpoint, which calculates the distance, duration, and price for a ride between a pickup and dropoff location.

#### Endpoint
`/rides/get-price`

## Method
`POST`

## Request Body
The request should be sent as JSON with the following structure:

```json
{
    "pickup": "74.022,40.002",
    "dropoff": "74.010,40.001"
}
```

### Parameters
- `pickup` (string): Coordinates of the pickup location in the format `longitude,latitude`.
- `dropoff` (string): Coordinates of the dropoff location in the format `longitude,latitude`.

## Authentication
This endpoint requires a token for user verification. The token should be included in the `Authorization` header in the following format:

```
Authorization: Bearer <token>
```

## Response
The response is returned in JSON format with the following structure:

```json
{
    "success": true,
    "message": "Route calculated successfully",
    "data": {
        "distance": "3.60 km",
        "duration": "24.02 minutes",
        "price": "108",
        "rawData": {
            "distance": 3603.557,
            "duration": 1441.423
        }
    }
}
```

### Response Fields
- `success` (boolean): Indicates whether the request was successful.
- `message` (string): A message describing the result.
- `data` (object): Contains the details of the calculated route:
  - `distance` (string): The distance between the pickup and dropoff points, formatted in kilometers.
  - `duration` (string): The estimated travel time, formatted in minutes.
  - `price` (string): The calculated price for the ride.
  - `rawData` (object): Raw calculation data:
    - `distance` (number): The raw distance in meters.
    - `duration` (number): The raw duration in seconds.

## Error Handling
The API provides meaningful error messages in case of failures. Common error responses include:

### Missing or Invalid Input
```json
{
    "success": false,
    "message": "Both pickup and dropoff coordinates are required"
}
```

```json
{
    "success": false,
    "message": "Invalid coordinate format. Use \"longitude,latitude\""
}
```

### No Route Found
```json
{
    "success": false,
    "message": "No route found between the locations"
}
```

### Mapbox API Errors
If there is an issue with the Mapbox API, the response will include the status code and error details:

```json
{
    "success": false,
    "message": "Mapbox API error: Not Found",
    "error": "<error details>"
}
```

### Example Request
```bash
curl -X POST http://localhost:4000/rides/get-price \
-H "Content-Type: application/json" \
-H "Authorization: Bearer <your-token>" \
-d '{
    "pickup": "74.022,40.002",
    "dropoff": "74.010,40.001"
}'
```

## Example Response
```json
{
    "success": true,
    "message": "Route calculated successfully",
    "data": {
        "distance": "3.60 km",
        "duration": "24.02 minutes",
        "price": "108",
        "rawData": {
            "distance": 3603.557,
            "duration": 1441.423
        }
    }
}
```

## Notes
- **Price Calculation**: The price is calculated as `30 per km`, with a minimum charge of `30` for distances under `1 km`. Distances are rounded up to the nearest whole number for pricing.
- **Input Validation**: The API checks for valid `longitude,latitude` formats and returns appropriate error messages for invalid inputs.
- **Authentication**: Ensure to include a valid token in the `Authorization` header to access the endpoint.
- **Dependencies**: This API uses the Mapbox Directions API for route calculations. Make sure the `MAPBOX_API_KEY` environment variable is correctly configured.


---

### **24. POST /rides/request-ride**

#### **Description**
This route allows an authenticated user to request a ride by providing the pickup and dropoff locations along with the ride price. The server will attempt to find a nearby AutoStand and allocate a ride with an available captain. If a captain accepts the ride request, the ride is saved in the database, and both the user and captain are notified via socket events. If no captains are available, the user is notified accordingly.

---

#### **Input (Request Body)**
```json
{
  "pickup": {
    "ltd": "number (required) - Pickup latitude",
    "lng": "number (required) - Pickup longitude"
  },
  "dropoff": {
    "ltd": "number (required) - Dropoff latitude",
    "lng": "number (required) - Dropoff longitude"
  },
  "price": "number (required) - Ride price"
}
```
- **Note:**  
  - The authenticated user details are derived from the `userAuth` middleware.
  - The pickup and dropoff locations must include both latitude (`ltd`) and longitude (`lng`).

---

#### **Output (Response)**

**Success (200)**
```json
{
  "success": true,
  "message": "Ride requested successfully",
  "data": {
    "rideId": "string - Generated ride ID",
    "captain": {
      "_id": "string - Captain ID",
      "socketId": "string - Captain socket ID"
      // additional captain details if needed
    }
  }
}
```

If no captains are available, the response may include debug information:
```json
{
  "success": true,
  "message": "Ride requested successfully",
  "data": {
    "message": "No captains available",
    "debugData": {
      "autostandsFetched": [ /* array of AutoStand details */ ],
      "captainsChecked": [ /* array of captain status, IDs, and socket IDs */ ]
    }
  }
}
```

**Error Responses**
- **400 Bad Request**  
  - Missing required fields (pickup, dropoff, price)
- **401 Unauthorized**  
  - If the user is not authenticated
- **500 Internal Server Error**  
  - An error occurred while processing the ride request

---

### **25. POST /rides/verify-otp**

#### **Description**
This route verifies the One-Time Password (OTP) provided by a captain (or user, if applicable) to initiate the ride. Upon successful verification, the ride is officially started.

---

#### **Input (Request Body)**
```json
{
  "rideId": "string (required) - ID of the ride",
  "otp": "string (required) - One-Time Password for ride verification",
  "location": {
    "ltd": "number (required) - Current latitude",
    "lng": "number (required) - Current longitude"
  }
}
```

---

#### **Output (Response)**

**Success (200)**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "data": {
    // any ride verification details you choose to return
  }
}
```

**Error Responses**
- **400 Bad Request**  
  - Missing fields such as `rideId`, `otp`, or location data
- **500 Internal Server Error**  
  - An error occurred during OTP verification

---

### **26. POST /rides/ride-completed**

#### **Description**
This route is triggered by the captain to mark a ride as completed. When the ride is completed and payment is received, the ride status is updated in the database, and real-time location sharing is terminated for both the user and the captain.

---

#### **Input (Request Body)**
```json
{
  "rideId": "string (required) - ID of the ride",
  "status": "string (required) - Must be 'completed'",
  "location": {
    "ltd": "number (required) - Current latitude",
    "lng": "number (required) - Current longitude"
  }
}
```

---

#### **Output (Response)**

**Success (200)**
```json
{
  "success": true,
  "message": "Ride completed successfully",
  "data": {
    // details of the completed ride (ride ID, timestamps, etc.)
  }
}
```

**Error Responses**
- **400 Bad Request**  
  - Missing required fields (rideId, status, location) or invalid status (if not "completed")
- **404 Not Found**  
  - Ride not found or associated user/captain not found
- **500 Internal Server Error**  
  - An error occurred while completing the ride

---

### **27. GET /rides/get-ride-history-for-user**

#### **Description**
This route retrieves the ride history for an authenticated user. The rides are sorted in descending order based on the creation date.

---

#### **Input**
- No request body is required. The user ID is determined via the authentication middleware (`userAuth`).

---

#### **Output (Response)**

**Success (200)**
```json
{
  "success": true,
  "message": "User rides fetched successfully",
  "data": [
    {
      "rideID": "string",
      "userId": "string",
      "captainID": "string",
      "Rate": "number",
      "Status": "string",
      // additional ride details...
      "createdAt": "timestamp"
    }
    // ... additional rides
  ]
}
```

**Error Responses**
- **404 Not Found**  
  - If no rides are found
- **500 Internal Server Error**  
  - An error occurred while fetching ride history

---

### **28. GET /rides/get-ride-history-for-captain**

#### **Description**
This route retrieves the ride history for an authenticated captain. The rides are sorted in descending order based on the creation date.

---

#### **Input**
- No request body is required. The captain ID is determined via the authentication middleware (`captainAuth`).

---

#### **Output (Response)**

**Success (200)**
```json
{
  "success": true,
  "message": "Captain rides fetched successfully",
  "data": [
    {
      "rideID": "string",
      "userId": "string",
      "captainID": "string",
      "Rate": "number",
      "Status": "string",
      // additional ride details...
      "createdAt": "timestamp"
    }
    // ... additional rides
  ]
}
```

**Error Responses**
- **404 Not Found**  
  - If no rides are found
- **500 Internal Server Error**  
  - An error occurred while fetching ride history

---

### **Additional Notes**
- **Authentication:**  
  - The `/request-ride` and `/get-ride-history-for-user` routes require the user to be authenticated (via `userAuth`).
  - The `/verify-otp`, `/ride-completed`, and `/get-ride-history-for-captain` routes require the captain to be authenticated (via `captainAuth`).

- **Socket Integration:**  
  - The ride request flow uses Socket.io events for real-time communication (e.g., `ride_request`, `ride_response`, `ride_accepted`, `otp_generated`, `start_location_sharing`, `location_update`).
  - Ensure your client applications (user and captain) are correctly configured to listen for and emit these socket events.

- **Validation:**  
  - Each route uses `express-validator` to validate incoming request data. Make sure your requests include all required fields.

---





# **Socket Events**

- **Event Name**: `response_notification`
- **Payload**:
  ```json
  {
    "standId": "string",
    "joiningCaptainId": "string",
    "response": "string"
  }
  ```
- **Recipients**: The captain who made the request.

The event is triggered when a union member responds to a captain's request. It sends a notification to the requesting captain, informing them whether their request was accepted or rejected.

#### **Example of Socket Emission**

```json
{
  "standId": "1234567890abcdef",
  "joiningCaptainId": "0987654321fedcba",
  "response": "accepted"
}
```

---

## 3. Socket Events



### Overview
This document outlines the socket event names used in the ride-hailing system for both captains and users.

## Events Table

| Event Name                      | Side     | Description |
|---------------------------------|----------|-------------|
| `connect`                       | Both     | Triggered when the socket connects to the server. |
| `disconnect`                    | Both     | Triggered when the socket disconnects from the server. |
| `connect_error`                 | Both     | Handles connection errors. |
| `error`                         | Both     | Handles general socket errors. |
| `register`                      | Both     | Registers the captain or user with the server. |
| `ride_request`                  | Captain  | Notifies the captain for a new ride request. |
| `ride_response`                 | Captain  | Sends the captain's response to a ride request. |
| `ride_accepted`                 | User     | Notifies the user that a ride has been accepted. |
| `ride_not_found`                 | Captain  | Informs the captain that the requested ride was not found. |
| `ride_error`                     | Captain  | Handles errors related to rides. |
| `start_location_sharing`         | Captain  | Signals the captain to start sharing their location. |
| `terminate_location_sharing`     | Both     | Stops the location-sharing process. |
| `location_update_captain_*rideId*` | Captain  | Sends the captain's live location updates. |
| `location_update_user_*rideId*`   | User     | Sends the user's live location updates. |
| `location_update`                | Both     | Captains receive user locations; users receive captain locations. |
| `ride_location_update`           | User     | Notifies the user of ride location updates. |
| `otp_generated`                  | User     | Sends the generated OTP for ride confirmation. |
| `notifications`                  | Both     | Sends general notifications to users and captains. |
| `request_notification`           | User     | Sends ride request notifications. |
| `response_notification`          | User     | Sends ride response notifications. |

## Notes
- Event names with `*rideId*` in their structure dynamically include the ride's unique identifier.
- Ensure event handlers properly manage and update state upon receiving these events.
- All location updates occur at 5-second intervals for both users and captains.


The system uses Socket.IO to notify union members and the requesting captain in real-time. There are two main socket events used:

#### **Event: request_notification**

- **Triggered**: When a captain requests to join an AutoStand.
- **Emitted To**: Union members who are online (have a valid `socketId`).
- **Payload**: Contains the stand ID, joining captain ID, and a message about the request.
- **Description**: This event informs union members about the joining captain's request. Offline union members will receive the notification when they come online.

#### **Event: response_notification**

- **Triggered**: When a union member responds to a captain's request.
- **Emitted To**: The joining captain.
- **Payload**: Contains the stand ID, joining captain ID, and the response (either "accept" or "reject").
- **Description**: This event notifies the joining captain of the decision regarding their request in real-time.


#### **Event: ride_request**

- **Triggered**: When a user requests a ride and the server selects an available captain.
- **Emitted To**: A specific captain who is active and connected via a valid socket.
- **Payload**: Contains a unique ride ID, user details (ID and full name), pickup location (latitude and longitude), dropoff location (latitude and longitude), and the ride price.
- **Description**: Notifies an available captain about a new ride request so that they can decide whether to accept the ride.

---

#### **Event: ride_response**

- **Triggered**: When a captain responds to a ride request.
- **Emitted To**: The server (via the captain’s socket).
- **Payload**: Contains the unique ride ID, the captain's ID, and a boolean indicating if the ride was accepted.
- **Description**: Conveys the captain’s decision on whether to accept or reject the ride request.

---

#### **Event: ride_accepted**

- **Triggered**: After the server receives an acceptance response from a captain.
- **Emitted To**: The user who requested the ride.
- **Payload**: Contains the unique ride ID and details of the assigned captain (such as their ID and socket ID).
- **Description**: Informs the user that a captain has accepted their ride request and provides details about the assigned captain.

---

#### **Event: otp_generated**

- **Triggered**: Immediately after a ride is accepted.
- **Emitted To**: The user.
- **Payload**: Contains the generated one-time password (OTP) for ride verification.
- **Description**: Delivers the OTP to the user to verify the ride when the captain arrives.

---

#### **Event: start_location_sharing**

- **Triggered**: When a ride has been accepted and is ready to commence.
- **Emitted To**: The captain.
- **Payload**: Contains the unique ride ID and basic user details (ID and full name).
- **Description**: Instructs the captain to begin sharing their real-time location with the user.

---

#### **Event: location_update_user_{rideId}**

- **Triggered**: At regular intervals (e.g., every few seconds) when the user is sharing their location.
- **Emitted To**: The server, which then forwards the update.
- **Payload**: Contains the unique ride ID and the updated user location (latitude and longitude).
- **Description**: Sends the user’s current location for real-time tracking by the captain.

---

#### **Event: location_update_captain_{rideId}**

- **Triggered**: At regular intervals when the captain is sharing their location.
- **Emitted To**: The server, which then forwards the update.
- **Payload**: Contains the unique ride ID and the updated captain location (latitude and longitude).
- **Description**: Sends the captain’s current location for real-time tracking by the user.

---

#### **Event: location_update**

- **Triggered**: When the server forwards location updates between the user and the captain.
- **Emitted To**: The recipient of the location update (either the user or the captain).
- **Payload**: Contains either the user’s location (latitude and longitude) or the captain’s location (latitude and longitude), depending on the direction of the update.
- **Description**: Provides real-time location information to facilitate mutual tracking during the ride.

---

#### **Event: ride_not_found**

- **Triggered**: When no captain accepts the ride request within the allowed time.
- **Emitted To**: The user who initiated the ride request.
- **Payload**: Contains a message indicating that no captains are available.
- **Description**: Notifies the user that the ride request could not be fulfilled due to a lack of available captains.

---

#### **Event: ride_error**

- **Triggered**: When an error occurs during the ride request process.
- **Emitted To**: The user who initiated the ride request.
- **Payload**: Contains a message describing the error encountered.
- **Description**: Informs the user that an error occurred while processing their ride request.


---


## Additional Notes

1. **Offline Notifications**: Union members who are offline when the request is sent will have the notification saved in their `offlineNotifications` array and will receive it when they come online.
2. **Email Notifications**: Union members are also notified via email about the captain's request, with details about the captain and their vehicle.
3. **Socket Connection**: Ensure that union members' `socketId` is updated in the database for real-time communication.

---



## Error Handling

### 1. Validation Errors
If input validation fails, the response includes validation error details.

#### Example Response
```json
{
  "errors": [
    {
      "type": "field",
      "msg": "Invalid email",
      "path": "email",
      "location": "body"
    },
    {
      "type": "field",
      "msg": "Password must be at least 5 characters long",
      "path": "password",
      "location": "body"
    },
    {
      "type": "field",
      "msg": "First name must be at least 3 characters long",
      "path": "fullname.firstname",
      "location": "body"
    },
    {
      "type": "field",
      "msg": "Last name must be at least 1 character long",
      "path": "fullname.lastname",
      "location": "body"
    }
  ]
}
```

### 2. Invalid OTP
If the OTP is invalid or has expired, the response will include an error message.

#### Example Response
```json
{
  "message": "Invalid OTP"
}
```

---

### Notes

- Ensure that the email and password are valid.
- OTPs are valid for 10 minutes from the time they are sent.
- The JWT token returned after successful OTP validation can be used for authenticated requests.
