# Odyssey Web

A simple, unofficial [Cosmos](https://cosmos.so) API for fetching images from profiles, clusters & search, plus a web frontend. It also powers the [Mac app](../mac).

## Endpoints

### All images

```
GET https://odyssey-hq.vercel.app/api/{username}
```

### Cluster images

```
GET https://odyssey-hq.vercel.app/api/{username}/{cluster}
```

### Search

Searches all of Cosmos, not a single profile. Matching is semantic, so results are ranked by relevance rather than filtered on exact words.

```
GET https://odyssey-hq.vercel.app/api/search?q={query}
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

Search returns the top 40 matches; the profile and cluster endpoints return everything

Responses are cached in-memory for up to 5 minutes