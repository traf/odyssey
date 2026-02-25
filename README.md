# Ace

A simple, unofficial [Cosmos](https://cosmos.so) API for fetching images from profiles & clusters.

## Endpoints

### All images

```
GET https://ace-hq.vercel.app/api/{username}
```

### Cluster images

```
GET https://ace-hq.vercel.app/api/{username}/{cluster}
```

### Example

```bash
curl https://ace-hq.vercel.app/api/traf/systems
```

```json
{
  "images": ["https://cdn.cosmos.so/...", "..."],
  "count": 75
}
```

Responses are cached for 5 minutes.