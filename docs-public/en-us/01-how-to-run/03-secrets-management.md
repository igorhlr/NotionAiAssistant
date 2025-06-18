# Secrets Management in NotionAiAssistant

This document describes how NotionAiAssistant manages sensitive information and secrets, and how you should configure your environment for development and production.

## Basic Concepts

NotionAiAssistant uses several types of sensitive information:

1. **Database Credentials**: PostgreSQL passwords and users
2. **API Keys**: OpenAI, Anthropic, Notion, DeepSeek, etc.
3. **System Secrets**: JWT secrets, encryption keys, etc.
4. **Administrative Credentials**: Admin user passwords

This information **must never** be stored directly in code or committed to repositories.

## Development Configuration

### Using .env

1. Copy the `.env.example` file to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file with your configurations:
   ```
   # Database Settings
   DATABASE_URL=postgresql://notioniauser:dev_password@localhost:5432/notionassistant
   
   # API Keys (fill in with your keys)
   OPENAI_API_KEY=your_key_here
   NOTION_API_KEY=your_key_here
   ```

3. The `.env` file is ignored by Git and will not be included in commits.

### Using Secrets in Development

For a more secure approach in development:

1. Run the secrets generation script:
   ```bash
   ./config/secrets/generate-secure-vars.sh
   ```

2. This script generates:
   - Secure passwords for the database
   - Application user passwords
   - JWT secrets
   - Configuration files in `config/secrets/development/`

3. The generated files are automatically ignored by Git.

## Production Configuration

### Using Docker Secrets

In production, we recommend using Docker Secrets:

1. Create the necessary secrets:
   ```bash
   echo "secure_password" | docker secret create postgres_password -
   echo "another_password" | docker secret create jwt_secret -
   # Repeat for other required secrets
   ```

2. In the `docker-compose.yml` file, reference the secrets:
   ```yaml
   services:
     app:
       secrets:
         - postgres_password
         - jwt_secret
         - openai_api_key
   
   secrets:
     postgres_password:
       external: true
     jwt_secret:
       external: true
     openai_api_key:
       external: true
   ```

3. The application will read the secrets from the `/run/secrets/` directory at runtime.

### Secrets Initialization Script

NotionAiAssistant includes an initialization script that:

1. Looks for secrets in the `/run/secrets/` directory
2. If not found, uses environment variables
3. Generates a temporary `.env` file with the correct values
4. Sets appropriate permissions

This script is located at `config/secrets/init-secrets.sh` and runs automatically when the container starts.

## External API Key Management

### Recommended Approach

For external APIs (OpenAI, Notion, etc.), we recommend:

1. **In development**:
   - Temporarily store in the `.env` file
   - Or use environment variables in your session

2. **In production**:
   - Use Docker Secrets for secure storage
   - Or integrate with an external secrets management service
   - Consider HashiCorp Vault or AWS Secrets Manager

### Dynamic Configuration

NotionAiAssistant allows users to configure their own API keys through the interface:

1. Keys are temporarily stored during the user session
2. No keys are persisted in the database
3. Users need to reconfigure keys when restarting the application

## Secrets Security

### Permission Recommendations

- `.env` files: `chmod 600`
- `config/secrets/` directory: `chmod 700`
- Individual secret files: `chmod 600`

### Security Validation

Before commits or deployment, you can run:
```bash
./config/secrets/validate-secrets.sh
```

This script checks:
- If sensitive secrets are being committed
- If example files are present
- If sensitive information is in logs or backups

## References

- [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/)
- [FastAPI Environment Variables](https://fastapi.tiangolo.com/advanced/settings/)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/auth-best-practices.html)

---

**IMPORTANT**: Never share your API keys or secrets with others. If you suspect a key has been compromised, generate a new one immediately and revoke the old one.

## Docker Data Path Configuration

Follow the instructions in [Setting Up the Data Path](./04-configuring-docker-data-path.md) if you haven't configured it yet.