<div align="right">
  <small>
    <a href="../../pt-br/03-contribuicao/00-como-contribuir.md">🇧🇷 Português</a> | 
    <strong>🇺🇸 English</strong>
  </small>
</div>

# How to Contribute - Notion Assistant

This guide explains how you can effectively contribute to the Notion Assistant project. We greatly appreciate your interest in helping improve our platform!

## Types of Contributions

There are several ways to contribute to the project:

- **Bug fixes**: Identify and fix issues in the code
- **New features**: Implement new capabilities for the assistant
- **Performance improvements**: Optimize existing code
- **Documentation**: Improve or add documentation
- **Testing**: Create or enhance automated tests
- **Design**: Improve user interface and experience
- **Feedback**: Report bugs or suggest improvements

## Workflow

### 1. Set Up Your Environment

Follow the steps in [Setting Up the Environment](../01-como-executar/00-setting-up-environment.md) to prepare your development environment.

### 2. Choose a Task

- Check the open [Issues](https://github.com/igorhlr/NotionAiAssistant/issues) on GitHub
- Look for issues labeled `good first issue` if this is your first contribution
- Or propose a new feature by creating an issue

### 3. Fork and Clone

1. Fork the repository to your GitHub account
2. Clone your fork:
   ```bash
   git clone https://github.com/igorhlr/NotionAiAssistant.git
   cd NotionAiAssistant
   ```
3. Add the original repository as a remote:
   ```bash
   git remote add upstream https://github.com/repositorio-original/NotionAiAssistant.git
   ```

### 4. Create a Branch

Always create a specific branch for your contribution:

```bash
git checkout -b feature/feature-name
# or
git checkout -b fix/bug-name
```

### 5. Develop

While developing your contribution:

- Follow the [Code Standards](./01-code-standards.md)
- Write tests for new features
- Keep the scope of changes focused
- Commit regularly with clear messages

### 6. Test Your Contribution

Ensure your contribution works correctly:

```bash
# Run automated tests
npm test

# Run the application locally
docker-compose -f docker-compose.dev.yml up
```

### 7. Submit a Pull Request

1. Update your branch with the latest changes:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. Push your changes to your fork:
   ```bash
   git push origin feature/feature-name
   ```

3. Open a Pull Request on GitHub, detailing:
   - What your contribution does
   - How to test it
   - Any additional important context

4. Follow the [Pull Request Flow](./02-pr-flow.md) for more details

## Best Practices

- **Communicate**: Comment on the issue you're working on to avoid duplication of effort
- **Focus**: Keep changes small and focused on a single purpose
- **Tests**: Add tests for new features
- **Documentation**: Update documentation to reflect your changes
- **Clean code**: Follow the project's coding standards

## Recognition

All contributors are recognized and listed in the [CONTRIBUTORS.md](https://github.com/igorhlr/NotionAiAssistant/blob/main/CONTRIBUTORS.md) file.

## Questions?

If you have questions about contributing, feel free to:
- Open an issue with the `question` tag
- Ask in the comments of an existing issue
- Contact the core maintainers

We greatly appreciate your contribution to making Notion Assistant even better!