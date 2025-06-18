# Backend Architecture - Notion Assistant

This document details the architecture of the Notion Assistant backend, including its components, data flows, and design patterns.

## Overview

The Notion Assistant backend is built with FastAPI, providing a RESTful API that manages communication between the user interface, PostgreSQL database, and external integrations.

```mermaid
graph TB
    subgraph "Backend"
        API[FastAPI<br/>:8080]
        MW[Middleware]
        RT[Routes]
        SV[Services]
    end
    
    subgraph "Data Layer"
        PG[(PostgreSQL<br/>Database)]
        CACHE[Redis Cache<br/>*Future*]
    end
    
    subgraph "External Integrations"
        subgraph "AI Providers"
            OAI[OpenAI API]
            ANT[Anthropic API]
            DS[DeepSeek API]
        end
        NOTION[Notion API]
    end
    
    API --> MW
    MW --> RT
    RT --> SV
    SV --> PG
    SV --> OAI
    SV --> ANT
    SV --> DS
    SV --> NOTION
    
    style PG fill:#fff3e0
    style OAI fill:#e8f5e9
    style ANT fill:#e8f5e9
    style DS fill:#e8f5e9
    style NOTION fill:#fce4ec
```

## Key Components

### 1. API Layer
- RESTful endpoints for frontend communication
- Request/response validation
- Authentication handling

### 2. Service Layer
- Business logic implementation
- AI content generation
- Notion integration
- User management

### 3. Data Layer
- PostgreSQL database
- Repository pattern for data access
- Future Redis caching

### 4. Integration Layer
- OpenAI/Anthropic/DeepSeek APIs
- Notion API
- Authentication providers

## Authentication Flow

```mermaid
sequenceDiagram
    Frontend->>Backend: POST /auth/login (credentials)
    Backend->>Database: Validate credentials
    Database-->>Backend: User data
    Backend->>Backend: Generate JWT
    Backend-->>Frontend: Return token
    Frontend->>Backend: Subsequent requests (with JWT)
    Backend->>Backend: Verify JWT
    Backend-->>Frontend: Authorized response
```

## Content Generation Flow

```mermaid
flowchart TD
    A[User Prompt] --> B[AI Processing]
    B --> C{Save to Notion?}
    C -->|Yes| D[Create Notion Page]
    C -->|No| E[Return Content]
    D --> F[Return Content + URL]
```

## Database Schema

```mermaid
erDiagram
    USERS ||--o{ CONTENT_HISTORY : creates
    USERS {
        uuid id PK
        string email
        string username
        string password_hash
        timestamp created_at
    }
    CONTENT_HISTORY {
        uuid id PK
        uuid user_id FK
        text prompt
        text generated_content
        string provider
        string notion_url
    }
```

## Error Handling

The backend implements consistent error responses:

```json
{
    "detail": "Error message",
    "status": 400,
    "code": "INVALID_INPUT"
}
```

## Security Measures

1. JWT authentication
2. Password hashing (bcrypt)
3. Input validation
4. Rate limiting
5. CORS restrictions

## Future Improvements

1. Implement Redis caching
2. Add monitoring/metrics
3. Support additional AI providers
4. Expand Notion integration features