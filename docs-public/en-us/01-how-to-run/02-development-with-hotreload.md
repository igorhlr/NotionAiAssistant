# Development with Hot Reload - Notion Assistant

This guide explains how to set up a development environment with hot reload, allowing you to view code changes in real-time without manually restarting the application.

## Benefits of Hot Reload

- **Faster Development**: View changes instantly
- **Immediate Feedback**: Quickly identify errors
- **Better Development Experience**: Maintain application context between changes
- **State Preservation**: Application state is preserved between reloads

## Environment Setup

### Prerequisites

Ensure you have installed:
- Docker and Docker Compose
- Node.js and npm
- Git

Follow the instructions in [Setting Up the Environment](./00-setting-up-environment.md) if you haven't configured it yet.

## Option 1: Hot Reload with Docker

The project includes a special Docker Compose configuration for development with hot reload.

### Starting with Docker

```bash
# At the project root
docker-compose -f docker-compose.dev.yml up
```

This configuration:
- Maps code directories as volumes
- Configures nodemon for the backend
- Configures the webpack dev server for the frontend
- Exposes necessary ports for development

### How It Works

1. Project files are mounted as volumes in the containers
2. Watch tools monitor file changes
3. When a file is modified, only the affected code is reloaded
4. The application state is preserved when possible

## Option 2: Local Development (Without Docker)

For development without Docker, you need to set up hot reload locally.

### Backend

1. Install dependencies:
   ```bash
   cd backend
   npm install
   ```

2. Start the server with nodemon:
   ```bash
   npm run dev
   ```

### Frontend

1. Install dependencies:
   ```bash
   cd frontend
   npm install
   ```

2. Start the development server:
   ```bash
   npm start
   ```

## Custom Configurations

### Adjusting Backend Hot Reload

Backend hot reload is configured via nodemon. You can customize its behavior by editing the `nodemon.json` file in the backend root:

```json
{
  "watch": ["src/**/*.js", "config/**/*.js"],
  "ignore": ["src/**/*.test.js", "src/**/*.spec.js"],
  "exec": "node src/index.js",
  "ext": "js,json"
}
```

### Adjusting Frontend Hot Reload

For the frontend, webpack dev server configurations can be adjusted in the webpack config file:

```js
// Example webpack.config.js configuration
module.exports = {
  // ... other configurations
  devServer: {
    hot: true,
    historyApiFallback: true,
    port: 3000,
    proxy: {
      '/api': 'http://localhost:8080'
    }
  }
};
```

## Tips and Best Practices

### Improving the Development Experience

1. **Visual Feedback**: Configure your bundler to show success/error notifications
2. **State Preservation**: Implement Hot Module Replacement (HMR) to maintain state
3. **Clear Logs**: Set up informative logs to facilitate debugging

### Debugging

1. **DevTools**: Use browser developer tools to inspect the application
2. **Breakpoints**: Set breakpoints in the code to stop execution and inspect variables
3. **Source Maps**: Ensure source maps are enabled for debugging transpiled code

### Troubleshooting Common Issues

#### Hot Reload Not Working

Check:
- If volumes are correctly configured in docker-compose.yml
- If watch tools are monitoring the correct directories
- If there are syntax errors preventing reload

#### Changes Not Appearing

Possible solutions:
- Clear the browser cache (Ctrl+F5 or Cmd+Shift+R)
- Verify the modified file is being monitored
- Restart the development server

#### State Lost Between Reloads

Consider:
- Implementing persistent storage (localStorage, Redux persist)
- Configuring HMR properly
- Using state management tools that preserve state during hot reload

## Next Steps

After setting up the development environment with hot reload, you're ready to start contributing! Refer to:

- [How to Contribute](../03-contribution/00-how-to-contribute.md)
- [Code Standards](../03-contribution/01-code-standards.md)
- [Project Architecture](../02-architecture/00-overview.md)