# Security Policy

## Supported Versions

Use this section to tell people about which versions of your project are currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of the Indoor Navigation System seriously. If you discover a security vulnerability, we appreciate your help in disclosing it to us in a responsible manner.

### Process

1. **Do not open a public GitHub issue.** Publicly reporting a vulnerability can put the community at risk.
2. Please verify the vulnerability is reproducible.
3. Send a detailed report to the maintainers at **[INSERT SECURITY EMAIL]**.
   - Include clear steps to reproduce the issue.
   - Describe the potential impact.
   - Attach any relevant screenshots or logs.

### Response Timeline

- **Acknowledgment**: We will acknowledge your report within 48 hours.
- **Assessment**: We will assess the severity and impact within 1 week.
- **Fix**: We aim to release a patch for critical vulnerabilities within 2 weeks.
- **Disclosure**: We will coordinate the public disclosure with you after the fix is released.

## Security Best Practices for Users

- **Firebase Rules**: Ensure your Firestore security rules are configured to restrict write access to authorized admins only.
- **API Keys**: Do not commit your `google-services.json` or `GoogleService-Info.plist` files to public repositories.
- **Authentication**: Usage of weak passwords for admin accounts is discouraged.

## Out of Scope

The following are generally considered out of scope for our security program:

- Vulnerabilities in third-party libraries (please report to the respective library maintainers).
- Social engineering attacks against our team.
- Physical attacks against user devices.
