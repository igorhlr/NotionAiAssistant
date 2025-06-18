# Complete Application Map - Notion Assistant

This document provides a holistic overview of the entire architecture and data flow of the Notion Assistant application.

## Architecture Diagram

The application architecture consists of the following main components:

```
                   ┌─────────────┐
                   │    Client   │
                   │   (Browser) │
                   └──────┬──────┘
                          │
                          ▼
┌──────────────────────────────────────────┐
│                 Traefik                  │
│      (Reverse Proxy / Load Balancer)     │
└─────────┬─────────────────────┬──────────┘
          │                     │
          ▼                     ▼
┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   PostgreSQL    │
│  (Backend API)  │◄───►│  (Database)    │
└─────────┬───────┘    └─────────────────┘
          │
          ▼
┌─────────────────┐
│  Notion API     │
│  (Integration)  │
└─────────────────┘
```

## System Components

### 1. Frontend (Client)

Web interface that allows users to:
- Authenticate into the system
- Interact with the assistant
- Manage integrations with Notion

### 2. Traefik (Reverse Proxy)

Manages:
- Traffic routing
- SSL certificates
- Load balancing

### 3. Backend (API)

Provides:
- Authentication endpoints
- Natural language processing
- Integration with external APIs
- Application business logic

### 4. Database (PostgreSQL)

Stores:
- User data
- Configurations
- Interaction history
- Integration tokens

### 5. Notion Integration

Enables:
- Reading and writing to Notion documents
- Data synchronization
- Access to Notion content

## Data Flow

1. The user accesses the application via the browser
2. Traefik routes the request to the application container
3. The application processes the request, querying the database when necessary
4. For interactions with Notion, the application uses the Notion API
5. Results are returned to the user through the web interface

## Docker Containers

The application runs in Docker containers:

| Container | Image | Function |
|-----------|--------|--------|
| notionaissistant_app | notionaissistant_app | Main application |
| notionaissistant_postgres | postgres:15-alpine | Database |
| traefik | production_traefik | Reverse proxy |

## Ports and Endpoints

- **Web Application**: Port 80/443 (HTTP/HTTPS)
- **Backend API**: [Endpoint details]
- **Database**: Port 5432 (PostgreSQL)

## Production Environment

The application is hosted on a VPS, with the domain [notionassistant.llmway.com.br](https://notionassistant.llmway.com.br).

For more details on specific components, refer to:
- [Frontend Documentation](./00-front.md)
- [Backend Architecture](../02-arquitetura/02-backend.md)
- [Database Configuration](../02-arquitetura/03-banco-dados.md)