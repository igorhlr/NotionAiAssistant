# Docker Data Path Configuration

When developing locally, NotionAiAssistant uses Docker volumes to persist data. By default, the path used is `/Users/user0/Documents/VPS/home/user0/docker-data/notion-assistant/`.

This guide explains how to customize this path to suit your needs.

## Introduction

The Docker data path is controlled by the `DOCKER_DATA_PATH` environment variable, which is automatically configured by the `setup-docker-env.sh` script. In a local development environment, you can customize this path to better fit your system's directory structure.

## How to Customize the Data Path

1. **Copy the example configuration file**:

   ```bash
   cp config/local-env.conf.example config/local-env.conf
   ```

2. **Edit the `config/local-env.conf` file**:
   
   Open the file in your preferred editor and set the value of `DOCKER_DATA_PATH` to the path you want to use:

   ```
   # Configuration for macOS
   DOCKER_DATA_PATH=/Users/your_user/Documents/Projects/NotionAiAssistant
   
   # OR for Linux
   # DOCKER_DATA_PATH=/home/your_user/projects/NotionAiAssistant
   
   # OR for Windows (WSL)
   # DOCKER_DATA_PATH=/mnt/c/Users/your_user/Documents/Projects/NotionAiAssistant
   ```

3. **Save the file** and start the project as usual.

## Directory Structure

After defining your `DOCKER_DATA_PATH`, the following directories will be created automatically:

```
${DOCKER_DATA_PATH}/docker-data/notion-assistant/
├── data/           # PostgreSQL data
├── backups/        # Database backups
└── logs/           # Application logs
```

And for the development environment:

```
${DOCKER_DATA_PATH}/docker-data/notion-assistant/dev/
├── data/           # PostgreSQL data (dev environment)
├── backups/        # Database backups (dev environment)
└── logs/           # Application logs (dev environment)
```

## Important Notes

- The `config/local-env.conf` file is in `.gitignore`, so your local configurations will not be pushed to the repository.
- In a production environment, this configuration is ignored, and the default production path is used.
- Ensure the directory you specify has write permissions for the user running Docker.

## Troubleshooting

If you encounter permission issues after changing the path, try:

1. Checking the permissions of the specified directory:
   ```bash
   ls -la ${DOCKER_DATA_PATH}
   ```

2. Granting write permissions if necessary:
   ```bash
   chmod -R 755 ${DOCKER_DATA_PATH}/docker-data
   ```

3. If using Docker Desktop, verify the directory is in the file sharing settings.