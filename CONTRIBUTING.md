# Contributing to LAMP Auto-Installer

Thank you for your interest in contributing to the LAMP Auto-Installer project! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues
- Use the GitHub issue tracker to report bugs
- Include detailed information about your system and the error
- Provide the installation log from `/LAMPinstallLOGS.text`
- Include steps to reproduce the issue

### Suggesting Enhancements
- Open an issue with the `enhancement` label
- Clearly describe the feature and its benefits
- Provide examples of how it would work

### Code Contributions
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test on multiple distributions if possible
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📋 Development Guidelines

### Code Style
- Follow bash best practices
- Use proper error handling with the existing framework
- Add logging for all major operations
- Use descriptive variable names
- Add comments for complex logic

### Testing
- Test on multiple Linux distributions when possible
- Verify that existing functionality isn't broken
- Test both successful and failure scenarios
- Update documentation if needed

### Supported Distributions
When adding support for new distributions:
- Update the OS detection logic
- Add appropriate package manager commands
- Test the installation process
- Update the compatibility matrix in README

## 🔧 Development Setup

### Testing Environment
It's recommended to test in virtual machines or containers:

```bash
# Example using Docker for testing
docker run -it --rm ubuntu:20.04 bash
docker run -it --rm centos:8 bash
docker run -it --rm debian:11 bash
```

### Local Testing
```bash
# Make the script executable
chmod +x install-lamp.sh

# Run with verbose logging
sudo bash -x install-lamp.sh

# Check logs
tail -f /LAMPinstallLOGS.text
```

## 📝 Pull Request Process

1. **Update Documentation**: Update README.md if you change functionality
2. **Follow the Template**: Use the pull request template
3. **Test Thoroughly**: Test on multiple distributions if possible
4. **Clean Commits**: Use clear, descriptive commit messages
5. **Link Issues**: Reference any related issues

### Pull Request Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] Tested on Ubuntu
- [ ] Tested on CentOS/RHEL
- [ ] Tested on Debian
- [ ] Added/updated tests

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
```

## 🐛 Bug Report Template

When reporting bugs, please include:

```markdown
**System Information:**
- OS: [e.g., Ubuntu 20.04]
- Script Version: [commit hash or version]
- Installation Method: [direct download, copy-paste, etc.]

**Describe the Bug:**
Clear description of what happened

**Expected Behavior:**
What you expected to happen

**Steps to Reproduce:**
1. Step one
2. Step two
3. See error

**Logs:**
```
[Paste relevant logs from /LAMPinstallLOGS.text]
```

**Additional Context:**
Any other information about the problem
```

## 🌟 Feature Request Template

```markdown
**Feature Description:**
Clear description of the feature

**Use Case:**
Explain why this feature would be useful

**Proposed Implementation:**
How you think it should work

**Alternatives Considered:**
Other solutions you've considered

**Additional Context:**
Any other relevant information
```

## 📚 Resources

- [Bash Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck](https://www.shellcheck.net/) - Online shell script analyzer
- [Linux Distribution Information](https://distrowatch.com/)

## 🏆 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- GitHub contributors graph

## ❓ Questions?

If you have questions about contributing:
- Open an issue with the `question` label
- Check existing documentation
- Review closed issues for similar questions

Thank you for contributing to make LAMP installation easier for everyone! 🚀
