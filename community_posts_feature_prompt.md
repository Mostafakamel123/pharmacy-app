# Community Posts Feature Prompt (Flutter Clean Architecture)

You are a senior Flutter engineer.

I have a Flutter application that follows **Clean Architecture**, **SOLID principles**, **Repository Pattern**, **Dio**, and **Cubit/BLoC** for state management.

I need you to implement a complete **Community Posts Feature** integrated with my backend APIs.

## Requirements

### Feature Overview

Users can:
- Create a post
- Upload an image with the post
- View all posts
- View their own posts
- Edit their own posts
- Delete their own posts

Pharmacies can:
- View all posts
- Reply to user posts

### Important Business Rule

Only users with the **Pharmacy** role are allowed to add replies to posts.

Normal users can only create, edit, delete, and view posts.

---

## API Base URL

```text
http://elaaj.runasp.net/api
```

---

## Create Post

### Endpoint

```http
POST /Posts
```

### Content-Type

```text
multipart/form-data
```

### Fields

```text
Content
File
```

### Example Success Response

```json
{
  "postId": 7,
  "message": "تم نشر استفسارك بنجاح."
}
```

---

## Get All Posts

### Endpoint

```http
GET /Posts?pageNumber=1&pageSize=10
```

### Response

```json
{
  "items": [
    {
      "id": 6,
      "userId": "string",
      "content": "المصارة",
      "imageUrl": "/images/generalposts/image.jpg",
      "createdAt": "2026-06-01T09:31:35",
      "replies": [
        {
          "id": 4,
          "pharmacyName": "",
          "message": "reply text",
          "createdAt": "2026-06-01T09:51:44"
        }
      ]
    }
  ],
  "totalCount": 6,
  "pageNumber": 1,
  "pageSize": 10,
  "totalPages": 1
}
```

---

## Get My Posts

### Endpoint

```http
GET /Posts/my-posts?pageNumber=1&pageSize=10
```

Response structure is identical to Get All Posts.

---

## Update Post

### Endpoint

```http
PUT /Posts/{postId}
```

### Content-Type

```text
multipart/form-data
```

### Fields

```text
Content
File
```

### Example Response

```json
{
  "message": "تم تعديل استفسارك بنجاح."
}
```

---

## Delete Post

### Endpoint

```http
DELETE /Posts/{postId}
```

### Example Response

```json
{
  "message": "تم حذف الاستفسار بنجاح."
}
```

---

## Authentication

All requests require:

```http
Authorization: Bearer TOKEN
```

Use my existing token management implementation.

---

## Image Handling

The API returns image paths like:

```text
/images/generalposts/example.jpeg
```

Create helper:

```dart
String buildImageUrl(String path) {
  return "http://elaaj.runasp.net$path";
}
```

---

# Architecture Requirements

## Domain Layer

### Entities

```dart
class PostEntity {
  final int id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final List<PostReplyEntity> replies;
}
```

```dart
class PostReplyEntity {
  final int id;
  final String pharmacyName;
  final String message;
  final DateTime createdAt;
}
```

### Repository Contract

```dart
Future<void> createPost(String content, File? image);

Future<void> updatePost(
  int postId,
  String content,
  File? image,
);

Future<void> deletePost(int postId);

Future<PaginatedPostsEntity> getPosts(
  int page,
  int pageSize,
);

Future<PaginatedPostsEntity> getMyPosts(
  int page,
  int pageSize,
);
```

### Use Cases

- CreatePostUseCase
- GetPostsUseCase
- GetMyPostsUseCase
- UpdatePostUseCase
- DeletePostUseCase

---

## Data Layer

Create:

- PostModel
- PostReplyModel
- PaginatedPostsModel
- PostRemoteDataSource
- PostRepositoryImpl

Use Dio.

Handle multipart upload correctly using FormData.

---

## Presentation Layer

### PostsCubit

States:

- PostsInitial
- PostsLoading
- PostsLoaded
- PostsError
- PostsPaginationLoading

Support infinite scrolling.

### MyPostsCubit

States:

- MyPostsInitial
- MyPostsLoading
- MyPostsLoaded
- MyPostsError

### CreatePostCubit

States:

- CreatePostInitial
- CreatePostLoading
- CreatePostSuccess
- CreatePostFailure

### UpdatePostCubit

States:

- UpdatePostInitial
- UpdatePostLoading
- UpdatePostSuccess
- UpdatePostFailure

### DeletePostCubit

States:

- DeletePostInitial
- DeletePostLoading
- DeletePostSuccess
- DeletePostFailure

---

# UI Requirements

## Community Screen

Features:

- Infinite scrolling
- Pull to refresh
- Display image if available
- Display content
- Display creation date
- Display replies count

Post card:

- Image
- Content
- Date
- Replies

## My Posts Screen

Display current user's posts only.

Allow:

- Edit
- Delete

Only for owner posts.

## Create Post Screen

Fields:

- Content TextField
- Image Picker
- Submit Button

Validation:

- Content required

## Edit Post Screen

- Pre-fill existing data
- Allow image replacement

---

# Pharmacy Replies

Display replies under each post.

Future-proof UI for replies.

Rule:

If current user role == Pharmacy:

- Show Reply Button

Else:

- Hide Reply Button

Never allow non-pharmacy users to see reply action.

---

# Error Handling

Handle:

- Network errors
- Unauthorized errors
- Empty states
- Pagination failures

Provide proper UI states.

---

# Deliverables

Generate complete production-ready code:

- entities
- models
- repository contracts
- repository implementation
- remote datasource
- use cases
- cubits
- states
- dependency injection registration
- Dio requests
- screens
- widgets
- pagination implementation
- image picker integration

Follow Clean Architecture and SOLID strictly.
