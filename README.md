# visenze_productsearch_sdk

[![Pub](https://img.shields.io/pub/v/visenze_productsearch_sdk.svg)](https://pub.dev/packages/visenze_productsearch_sdk)
[![Platform](https://img.shields.io/badge/Platform-Android_iOS_Web-blue.svg?longCache=true&style=flat-square)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](/LICENSE)
[![Null Safety](https://img.shields.io/badge/-Null%20Safety-blue.svg)]()

## Table of Contents

- [visenze_productsearch_sdk](#visenze_productsearch_sdk)
  - [Table of Contents](#table-of-contents)
  - [1. Overview](#1-overview)
  - [2. Set up](#2-set-up)
  - [3. APIs](#3-apis)
    - [3.1 Search by image](#3.1-search-by-image)
    - [3.2 Recommendations](#3.2-recommendations)
  - [4. Advanced search](#4-advanced-search)
    - [4.1 Automatic object detection](#4.1-automatic-object-detection)
    - [4.2 Filters and text filters](#4.2-filters-and-text-filters)
    - [4.3 Facets](#4.3-facets)
    - [4.4 Attributes retrieval](#4.4-attributes-retrieval)
  - [5. Search results](#5-search-results)
  - [6. Event tracking](#6-event-tracking)
    - [6.1 Set up](#6.1-set-up)
    - [6.2 Send events](#6.2-send-events)
    - [6.3 Event parameters](#6.3-event-parameters)

## 1. Overview

[The ViSenze Discovery Suite](https://console.visenze.com/) provides your customers a better and more intuitive product search and discovery experience by helping them search, navigate and interact with products more easily. ViSenze latest Product Search & Recommendations API is included in this SDK. Please refer to online [docs](https://ref-docs.visenze.com/reference/introduction-to-search-and-recommendation-api) for more information.

## 2. Set up

### 2.1 Install

Run command

```
flutter get visenze_productsearch_sdk
```

### 2.2 Start

Before you can start using the SDK, you will need to set up the SDK keys. Most of these keys can be found in your account's [dashboard](https://console.visenze.com/).

First, take a look at the table below to understand what each key represents:

| Key          | Importance | Description                                                                                                   |
| :----------- | :--------- | :------------------------------------------------------------------------------------------------------------ |
| app_key      | Compulsory | All SDK functions depends on a valid app_key being set. The app key also limits the API features you can use. |
| placement_id | Compulsory | Your placement id.                                                                                            |
| timeout      | Optional   | Timeout for APIs in ms. Defaulted to 15000.                                                                   |
| uid          | Optional   | The customer user id. If not provided, this will be auto generated .                                          |

To create a ProductSearch instance:

```dart
const psClient = await VisenzeProductSearch.create('APP_KEY', 'PLACEMENT_ID');
```

```dart
const psClient = await VisenzeProductSearch.create('APP_KEY', 'PLACEMENT_ID', uid: 'CUSTOMER_UID', timeout: TIMEOUT_IN_MS);
```

## 3. APIs

### 3.1 Search by image

POST /product/search_by_image

Searching by Image can happen in three different ways - by url, id or File.

- Using image id:

  ```dart
  var params = {
    im_id: 'your-image-id'
  };

  var response = await psClient.productSearchByImage(null, params);
  ```

- Using image url:

  ```dart
  var params = {
    im_url: 'your-image-url'
  };

  var response = await psClient.productSearchByImage(null, params);
  ```

- Using image from gallery:

  ```dart
  var image = await psClient.uploadImage();
  if (image != null) {
    var response = await psClient.productSearchByImage(image, params);
  }
  ```

- Using image from camera capture:

  ```dart
  var image = await psClient.captureImage();
  if (image != null) {
    var response = await psClient.productSearchByImage(image, params);
  }
  ```

You can also pass your own image if it's in [XFile](https://pub.dev/packages/image_picker) format.

> Please provide `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` values if you are accessing gallery/camera for image search for iOS devices.

> The request parameters for search API can be found at [ViSenze Documentation Hub](https://ref-docs.visenze.com/reference/search-by-image-api-1).

#### 3.1.1 Resize settings

By default, we limit the size of the image user upload to 512x512 pixels to balance search latency and search accuracy.

If your image contains fine details such as textile patterns and textures, you can set a larger limit.

```dart
psClient.widthLimit = 1024;
psClient.heightLimit = 1024;
```

To make efficient use the of the memory and network bandwidth of mobile device, the maximum size is set at 1024 x 1024. Any image exceeds the limit will be resized to the limit.

### 3.2 Recommendationss

GET /product/recommendations/{product_id}

Search for visually similar products in the product database giving an indexed product’s unique identifier.

```dart
var productId = 'your-product-id';

// example paramters
var parameters = {
  limit: 20 // limit results returned to 20 results
};

var response = await psClient.productSearchById(productId, parameters);
```

> The request parameters for this API can be found at [ViSenze Documentation Hub](https://ref-docs.visenze.com/reference/visually-similar-api).

## 4. Advanced search

### 4.1 Automatic object detection

The Search API is able to detect the objects present in the query image and suggest the best matched product type to run the search on.

Use `detection` or `point` parameters to suggest the particular objects of interest in the query image. `box` and `point` parameters are not allowed to appear in the same request.

- Example

  ```dart
  var params = {
    im_url: 'your-image-url',
    detection: 'Top' // only detect objects in the image with product_type `Top`
    detection_limit: 5 // only detect up to a maximum of 5 objects in the image
  };

  var response = await psClient.productSearchByImage(null, params);
  ```

> For more details, please refer to the Automatic Object Detection document at [ViSenze Documentation Hub](https://ref-docs.visenze.com/reference/automatic-object-detection).

### 4.2 Filters and text filters

To filter search results based on product metadata, provide a map of metadata key-values in the filters or text_filters parameters.

| Param        | Filter query behaviour                                                                                      | Example                                                                                                                                                                                                                                                         |
| :----------- | :---------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| filters      | The filter queries are treated as exact match conditions. Applies to String, Integer and Float type fields. | `filters=brand:my_brand` means the brand (String) value of the search results must be strictly equal to “my_brand”. `filters=price:10,199` means the price (Integer) value of the search results must be strictly within the range between 10 to 199 inclusive. |
| text_filters | The filter queries are treated as partial match filters. Only applies to String type fields.                | `text_flters=brand:my_brand` means the brand value of the search results can be any values containing “my_brand”, such as “my_brand >> sub brand”.                                                                                                              |

- Example

```dart
var productId = 'your-product-id';

var parameters = {
  filters: ['brand:my_brand', 'price:50:200'] // filter all products from my_brand AND price between 50-200 currency unit
};

var response = await psClient.productSearchById(productId, parameters);
```

> For more filters syntax and rules, please refer to the filters section at [ViSenze Documentation Hub](https://ref-docs.visenze.com/reference/filters-and-text-filters)

### 4.3 Facets

Facets are values to filters on from results list. You can get the facets by sending a list of fields to enable faceting on.

- Example

```dart
var productId = 'your-product-id';

var parameters = {
  facets: 'gender, brand, price', // return possible filterable metadata fields for gender, brand, price,
  facets_limit: 10 // return 10 values for each facet
};

var response = await psClient.productSearchById(productId, parameters);
```

For more details, please refer to Facets section at [ViSenze Documentation Hub](https://ref-docs.visenze.com/reference/facets)

### 4.4 Attributes retrieval

To retrieve metadata from your API call, provide the list of product metadata keys to the `attrs_to_get` (field list) property.

- Example

```dart
var productId = 'your-product-id';

var parameters = {
  attrs_to_get: 'gender, price, brand' // return gender, price and brand metadata in the result
};

var response = await psClient.productSearchById(productId, parameters);
```

> Only indexed attributes can be retrieved

> Note that only the indexed attributes can be retrieved with this parameter. You may go the the Edit App page to review which attributes have been included in the app index.

## 5. Search results

This sdk use the [http](https://pub.dev/packages/http) library for making API request. The response is a http [Response](https://pub.dev/documentation/http/latest/http/Response-class.html).

The list of error codes can be found [here](https://ref-docs.visenze.com/reference/error-codes).
For response properties, please refer to the APIs docs.

```dart
var productId = 'your-product-id';
var response = await psClient.productSearchById(productId);

if (response.statusCode == 200) {
  Map<String, dynamic> successResp = jsonDecode(response.body);
  List<Map<String, dynamic>> results = successResp['result'];
  // handle results here
} else {
  // handle error here
}
```

## 6. Event tracking

To improve search performance and gain useful data insights, it is recommended to send user interactions (actions) with the visual search results.

Currently, we support the following event actions: `product_click`, `product_view`, `add_to_cart`, and `transaction`. However, the action parameter can be an arbitrary string if you want to send custom events.

Some events (for e.g. `product_click` or `product_view`) can require additional parameter like `pid` (product id).

### 6.1 Set up

We will initialize the event tracker with a tracking ID generated from your app key and placement ID for you.

### 6.2 Send events

#### 6.2.1 Single event

User action can be sent through an event handler. Register an event handler to the element in which the user will interact.

```dart
// send product click
psClient.sendEvent('product_click', {
  queryId: '<search reqid>',
  pid: '<your product id>',
  pos: 1, // product position in Search Results, start from 1
});

// send product impression
psClient.sendEvent('product_view', {
  queryId: '<search reqid>',
  pid: '<your product id>',
  pos: 1, // product position in Search Results, start from 1
});

// send Transaction event e.g order purchase of $300
psClient.sendEvent('transaction', {
  queryId: "<search reqid>",
  transId: "<your transaction ID>"
  value: 300
});

// send Add to Cart Event
psClient.sendEvent('add_to_cart', {
  queryId: '<search reqid>',
  pid: '<your product id>',
  pos: 1, // product position in Search Results, start from 1
});

// send custom event
psClient.sendEvent('favourite', {
  queryId: '<search reqid>',
  label: 'custom event label',
  cat: 'visual_search'
});

// handle success or error
try {
  psClient.sendEvent('product_click', {
    queryId: '<search reqid>',
    pid: '<your product id>',
    pos: 1, // product position in Search Results, start from 1
  });
  onRequestSuccess(); // handle success
} catch (errResponse) {
  onRequestError(errReponse); // handle error
}
```

#### 5.2.2 Batch events

Batch actions can be sent through a batch event handler.

A common use case for this batch event method is to group up all transaction by sending it in a batch. This SDK will automatically generate a transId to group transactions as an order.

```dart
psClient.sendEvents('transaction',
  [{
    queryId: '<search request ID>',
    pid: '<product ID - 1> ',
    value: 300,
  }, {
    queryId: '<search request ID>',
    pid: '<product ID - 2> ',
    value: 400
  }]
);
```

### 6.3 Event parameters

For list of all event parameter and their explanations, please refer to [this doc](https://ref-docs.visenze.com/reference/event-parameters)

Below we list down the most basic parameters and how to retrieve them.

#### 6.3.1 Search query Id

All events sent to Visenze Analytics server require the search query ID (the `reqid`) found in the search results response as part of the request parameter.

```dart
var productId = 'your-product-id';
var parameters = {
  ...
};
var response = await psClient.productSearchById(productId, parameters);
var responseBody = jsonDecode(response.body);
var queryId = responseBody['reqid']; // <- this is your search query Id
```

You can also directly get the query id of the last successful search request performed by your client.

```dart
var queryId = psClient.lastSuccessQueryId;
```

#### 6.3.2 Session Id

```dart
var sessionId = psClient.sessionId;
```

#### 6.3.3 User Id

```dart
var userId = psClient.userId;
```
