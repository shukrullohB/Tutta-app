# Tutta – Flutter & Backend Integration Rules

## Goal

Make integration between Flutter and Backend simple, clean, and predictable.

## Rules

### 1. Single API base URL
Flutter should use one central API base URL.

Example:
- development: http://localhost:5000
- production: https://api.tutta.uz

### 2. All endpoints must be documented
Before backend creates endpoint, it should exist in `api-plan.md`.

### 3. Consistent response format
Every backend response must follow the standard structure:
- success
- message
- data
- error

### 4. IDs must be stable
All entities should use consistent IDs:
- user id
- listing id
- booking id
- chat id

### 5. Date format
All dates should be returned in ISO format.

Example:
- 2026-03-16T10:30:00Z

### 6. Price format
All prices should be returned as numbers, not strings.

Correct:
- 120000

Wrong:
- "120000 so'm"

### 7. Status fields must be controlled
Statuses should use fixed values only.

Example:
- booking: pending, confirmed, cancelled, completed

### 8. Flutter should not depend on raw backend naming confusion
Backend field names should be simple and predictable.

Use:
- fullName
- phone
- dailyPrice
- weeklyPrice

Avoid mixed styles.

### 9. Validation errors should be readable
If request fails, backend should clearly explain which field failed.

### 10. One source of truth
Backend handles:
- business logic
- pricing logic
- booking validation
- payment validation

Flutter handles:
- UI
- state
- user interaction
- displaying backend data
