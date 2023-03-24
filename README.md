# visenze_productsearch_sdk

[![Pub](https://img.shields.io/pub/v/visenze_productsearch_sdk.svg)](https://pub.dev/packages/visenze_productsearch_sdk)
[![Platform](https://img.shields.io/badge/Platform-Android_iOS_Web-blue.svg?longCache=true&style=flat-square)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](/LICENSE)
[![Null Safety](https://img.shields.io/badge/-Null%20Safety-blue.svg)]()

## 1. Overview

[The ViSenze Discovery Suite](https://console.visenze.com/) provides your customers a better and more intuitive product search and discovery experience by helping them search, navigate and interact with products more easily. ViSenze latest Product Search & Recommendations API is included in this SDK. Please refer to online [docs](https://ref-docs.visenze.com/reference/introduction-to-search-and-recommendation-api) for more information.


## 2. Set up

Before you can start using the SDK, you will need to set up the SDK keys. Most of these keys can be found in your account's [dashboard](https://console.visenze.com/).

First, take a look at the table below to understand what each key represents:

| Key | Importance | Description |
|:---|:---|:---|
| app_key | Compulsory | All SDK functions depends on a valid app_key being set. The app key also limits the API features you can use. |
| placement_id | Compulsory | Your placement id. |
| timeout | Optional | Timeout for APIs in ms. Defaulted to 15000 |

To create a ProductSearch instance:

```dart
const psClient = await VisenzeProductSearch.create('APP_KEY', 'PLACEMENT_ID');
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

  var response = await psClient.productSearchByImage(params);
  ```

- Using image url:

  ```dart
  var params = {
    im_url: 'your-image-url'
  };

  var response = await psClient.productSearchByImage(params);
  ```

- Using image file:

  ```dart
  var body = {
    image: imageFile
  };

  var response = await psClient.productSearchByImage(params);
  ```

> The request parameters for this API can be found at [ViSenze Documentation Hub](https://ref-docs.visenze.com/reference/search-by-image-api-1).

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

## 4. Search results

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