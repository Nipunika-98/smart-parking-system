# Smart Parking Dashboard

The dashboard is the Angular-based administration interface for the Smart Parking System. It provides parking administrators with tools to monitor parking operations, manage users and slots, configure rates, and review reports and transaction data.

## Features

- Administrator login and access protection
- Parking-slot management
- Parking-rate configuration
- User directory
- Parking reports and analytics
- Transaction logs
- System settings
- Firebase data integration
- Charts and dashboard visualizations

## Technology Stack

- Angular 19
- TypeScript
- Firebase SDK
- Angular Router
- Chart.js
- ng2-charts
- SCSS

## Requirements

- Node.js and npm
- Angular CLI 19-compatible environment
- Access to the configured Firebase project

Check the installed versions:

```bash
node --version
npm --version
```

## Installation

From the repository root:

```bash
cd dashboard
npm install
```

If a `package-lock.json` is available, use the following for a reproducible installation:

```bash
npm ci
```

## Development Server

Start the local development server:

```bash
npm start
```

Alternatively:

```bash
npx ng serve
```

Open the dashboard at:

```text
http://localhost:4200/
```

The application reloads automatically when source files are changed.

## Production Build

```bash
npm run build
```

The compiled application is generated in the `dist/` directory.

## Testing

Run unit tests with Karma:

```bash
npm test
```

The project can also be tested directly with Angular CLI:

```bash
npx ng test
```

## Project Structure

```text
dashboard/
├── src/
│   ├── app/
│   │   ├── dashboard/
│   │   ├── guards/
│   │   ├── login/
│   │   ├── parking-rates/
│   │   ├── parking-slot-management/
│   │   ├── reports/
│   │   ├── services/
│   │   ├── sidebar/
│   │   ├── system-settings/
│   │   ├── transaction-logs/
│   │   ├── user-directory/
│   │   └── firebase.config.ts
│   ├── main.ts
│   └── styles.scss
├── public/
├── angular.json
├── package.json
├── tsconfig.json
└── README.md
```

## Firebase Configuration

The dashboard reads and manages parking-system data through Firebase. Confirm that the Firebase configuration in the application matches the project used by the mobile app and simulation.

Do not add private service-account credentials, passwords, or other secrets to this repository.

## Troubleshooting

If dependencies or generated files cause issues, run:

```bash
rm -rf node_modules
npm install
```

On Windows PowerShell, remove `node_modules` manually or use an equivalent command. If the dashboard cannot connect to Firebase, verify the Firebase configuration, authentication settings, Firestore rules, and network connection.
