# Frontend Map - Notion Assistant

This document presents the structure and organization of the frontend for the Notion Assistant application.

## Overview

The application's frontend was developed using modern technologies to create an intuitive and responsive interface for interacting with the Notion assistant.

## Directory Structure

```
frontend/
├── public/
│   ├── assets/
│   │   └── images/
│   └── index.html
├── src/
│   ├── components/
│   │   ├── common/
│   │   ├── layout/
│   │   └── pages/
│   ├── hooks/
│   ├── services/
│   ├── store/
│   ├── styles/
│   ├── utils/
│   ├── App.js
│   └── index.js
└── package.json
```

## Main Components

### Login/Registration Page

![Login Page](../../assets/login-page.png)

The login/registration page allows users to:
- Log in with existing credentials
- Register on the platform
- Learn about the 

### Main Interface

The assistant's main interface includes:
- Chat area for interacting with the assistant
- Side panel for managing Notion documents
- Toolbar with configuration options

## Navigation Flow

The diagram below demonstrates the main user navigation flow:

```
Login/Registration → Dashboard → Chat with Assistant → Settings
```

## Technologies Used

- Framework: [Specify framework]
- State Management: [Specify library]
- Styling: [Specify CSS approach]
- HTTP Requests: [Specify library]

## Backend Integration

The frontend communicates with the backend via a REST API, using endpoints documented in the [Backend Architecture](../02-arquitetura/02-backend.md) section.

## Next Steps

See the planned developments for the frontend in the [Roadmap](../03-contribuicao/03-roadmap.md).