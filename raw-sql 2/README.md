# Raw SQL 2 External PWA

Standalone, deploy-ready version of the external portal. It is intentionally self-contained and does not depend on the monorepo workspace packages.

## Local development

```bash
npm install
npm run dev
```

## Production build

```bash
npm run build
npm run preview
```

The production output is written to `dist/`.

## Deploy

### Render static site

Use the included `render.yaml`, or create a Render Static Site with:

- Build command: `npm install && npm run build`
- Publish directory: `dist`
- Rewrite rule: `/*` to `/index.html`

### Netlify

Use the included `netlify.toml`; Netlify will build with `npm install && npm run build` and publish `dist`.

### Docker

```bash
docker build -t raw-sql-2-external-pwa .
docker run -p 8080:80 raw-sql-2-external-pwa
```
