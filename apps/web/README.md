# Odyssey Web

A simple, unofficial [Cosmos](https://cosmos.so) API for fetching images from profiles & clusters, plus a web frontend. It also powers the [Mac app](../mac).

## Endpoints

### All images

```
GET https://odyssey-hq.vercel.app/api/{username}
```

### Cluster images

```
GET https://odyssey-hq.vercel.app/api/{username}/{cluster}
```

### Example

```bash
curl https://odyssey-hq.vercel.app/api/traf/systems
```

```json
{
  "images": ["https://cdn.cosmos.so/...", "..."],
  "count": 75
}
```

No auth, so public elements only

Responses are cached in-memory for up to 5 minutes