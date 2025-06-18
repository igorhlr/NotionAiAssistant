# Setting Up the Environment - Notion Assistant

This guide details the steps required to set up the development environment for the Notion Assistant project.

## Prerequisites

Before starting, ensure you have the following installed:

- [Docker](https://www.docker.com/get-started) (version 20.10 or higher)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 2.0 or higher)
- [Node.js](https://nodejs.org/) (version 16 or higher)
- [npm](https://www.npmjs.com/) (version 8 or higher)
- [Git](https://git-scm.com/downloads)

## Step 1: Clone the Repository

```bash
git clone https://github.com/igorhlr/NotionAiAssistant.git
cd NotionAiAssistant
```

## Step 2: Configure Environment Variables

Create a `.env` file in the project root based on the `.env.example` template:

```bash
cp .env.example .env
```

Edit the `.env` file with your configurations:

```
# Application Settings
APP_PORT=3000
NODE_ENV=development

# Database Settings
DB_HOST=postgres
DB_PORT=5432
DB_NAME=notionassistant
DB_USER=postgres
DB_PASSWORD=postgres_password

# Notion Settings
NOTION_API_KEY=your_notion_api_key
```

## Step 3: Install Dependencies

For local development (outside Docker):

```bash
# Install backend dependencies
cd backend
npm install

# Install frontend dependencies
cd ../frontend
npm install
```

## Step 4: Start Services with Docker Compose

To start all services (recommended):

```bash
docker-compose -f docker-compose.dev.yml up
```

This command will start:
- Backend application container
- PostgreSQL database container
- Frontend container with hot reload

## Step 5: Verify the Installation

After starting the services, you can access:

- Frontend: http://localhost:3000
- Backend API: http://localhost:8080

## Step 6: Configure the Database

The database will be automatically configured during container initialization. To run migrations manually:

```bash
# Inside the backend container
docker-compose exec backend npm run migrate
```

## Local Development Without Docker

For development without Docker:

1. Set up a local PostgreSQL database
2. Update the `.env` file with local configurations
3. Run the backend:
   ```bash
   cd backend
   npm run dev
   ```
4. Run the frontend:
   ```bash
   cd frontend
   npm start
   ```

## Troubleshooting

### Issue: Database Connection Error

Check:
- If the PostgreSQL container is running
- If the credentials in the `.env` file are correct
- If the Docker network is configured correctly

### Issue: Hot Reload Not Working

Check:
- If the volume is correctly mapped in docker-compose.yml
- If dependencies are installed

## Next Steps

After setting up the environment, refer to:
- [Development with Hot Reload](./02-development-with-hotreload.md)
- [Project Structure](../02-architecture/00-overview.md)
- [How to Contribute](../03-contribution/00-how-to-contribute.md)