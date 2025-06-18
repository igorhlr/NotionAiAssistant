# How to Run with Docker - Notion Assistant

This guide explains how to run the Notion Assistant project using Docker and Docker Compose, providing an isolated and consistent environment for development and testing.

## Prerequisites

Ensure you have installed:
- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)

To verify the installed versions:
```bash
docker --version
docker-compose --version
```

## Initial Setup

Before starting the containers, configure the environment file:

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file with your local configurations.

## Starting the Application

### Development Environment

To start the application in development mode:
```bash
docker-compose -f docker-compose.dev.yml up
```

This command starts:
- Application container (with hot reload)
- PostgreSQL container
- Volume mapping for development

To run in the background:
```bash
docker-compose -f docker-compose.dev.yml up -d
```

### Local Production Environment

To simulate a production environment locally:
```bash
docker-compose up
```

This command uses the configurations from the default `docker-compose.yml` file, which is optimized for a production-like environment.

## Checking Containers

To check the status of running containers:
```bash
docker-compose ps
```

Example output:
```
         Name                        Command               State                  Ports                
-------------------------------------------------------------------------------------------------------
notionaissistant_app      docker-entrypoint.sh node  ...   Up      0.0.0.0:3000->3000/tcp              
notionaissistant_postgres docker-entrypoint.sh postgres    Up      0.0.0.0:5432->5432/tcp
```

## Accessing the Application

After starting the containers, you can access:
- Web Interface: http://localhost:3000
- API: http://localhost:3000/api

## Viewing Logs

To monitor logs in real-time:
```bash
# All containers
docker-compose logs -f

# Specific container
docker-compose logs -f app
```

## Running Commands

To execute commands inside the containers:
```bash
# Shell into the application container
docker-compose exec app sh

# Run an NPM command
docker-compose exec app npm run <command>

# Shell into the PostgreSQL container
docker-compose exec postgres psql -U postgres -d notionassistant
```

## Stopping the Application

To stop all containers:
```bash
# If started in the foreground (with Ctrl+C)
# Or if started in the background:
docker-compose down
```

To stop and remove volumes (warning: this will delete the database):
```bash
docker-compose down -v
```

## Rebuilding the Application

If you modify the Dockerfile or need to rebuild the images:
```bash
docker-compose build
# or
docker-compose up --build
```

## Troubleshooting

### Issue: Port Already in Use

If port 3000 or 5432 is already in use:
1. Check which processes are using the ports:
   ```bash
   lsof -i :3000
   lsof -i :5432
   ```
2. Terminate those processes or change the ports in the `docker-compose.yml` file.

### Issue: Volume Permission Errors

If you encounter permission errors when mounting volumes:
```bash
# On Linux/macOS
sudo chown -R $USER:$USER .
```

## Next Steps

After running the application with Docker, refer to:
- [Development with Hot Reload](./02-development-with-hotreload.md)
- [How to Contribute](../03-contribution/00-how-to-contribute.md)