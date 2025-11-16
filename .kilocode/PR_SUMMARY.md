# User-Defined Thumbnail Feature

This PR implements the ability for users to define custom thumbnails for their photos.

## Changes Made:

1. Database migration to add `user_thumbnail` field
2. Updated Photo model with thumbnail handling
3. Added GraphQL mutation and types
4. Created thumbnail editor UI component
5. Added comprehensive tests

## How to Test:

1. Log in as a photo owner
2. Navigate to a photo page
3. Click "Edit Thumbnail" in Photo Management section
4. Drag and resize the square marquee to select desired thumbnail area
5. Click "Save Thumbnail" to apply changes

## Technical Details:

- User thumbnails take priority over intelligent thumbnails
- Thumbnails must remain square
- Derivatives are regenerated asynchronously after saving
- GraphQL type names simplified from `intelligent_or_square_*` to `thumbnail` and `medium`
